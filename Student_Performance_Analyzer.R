# --- Libraries ---
library(shiny)
library(ggplot2)
library(dplyr)
library(GGally)
library(factoextra)
library(corrplot)
library(broom)
library(rsconnect)

set.seed(42)

# ==== Nonlinear scoring function ====
score_fun <- function(sleep, study, attend, office, caffeine) {
  attend_factor <- attend / 100
  
  sleep_term    <- 30 * (1 - exp(-0.40 * pmax(sleep - 3, 0)))
  study_term    <- 30 * (1 - exp(-0.25 * pmax(study, 0)))
  attend_term   <- 25 * attend_factor
  office_term   <- 0.10 * sqrt(pmax(office, 0))
  caffeine_term <- -0.01 * pmax(caffeine, 0)
  
  raw <- 10 + (sleep_term + study_term) * attend_factor + attend_term + office_term + caffeine_term
  
  # attendance = 0 → fail cap
  raw <- ifelse(attend == 0, 30, raw)
  
  pmin(pmax(raw, 0), 100)
}

# ==== Synthetic dataset ====
set.seed(42)
n <- 400
data <- data.frame(
  Sleep       = runif(n, 3, 10),
  Study       = runif(n, 0, 20),
  ClassAttend = runif(n, 40, 100),
  OfficeHours = runif(n, 0, 100),
  Caffeine    = runif(n, 0, 400)
)

data$TestScore <- score_fun(data$Sleep, data$Study, data$ClassAttend, data$OfficeHours, data$Caffeine) + rnorm(n, 0, 5)
data$Homework  <- score_fun(data$Sleep, data$Study, data$ClassAttend, data$OfficeHours, data$Caffeine/2) + rnorm(n, 0, 5)
data$TestScore <- pmin(pmax(data$TestScore, 0), 100)
data$Homework  <- pmin(pmax(data$Homework, 0), 100)

# ==== UI ====
ui <- fluidPage(
  titlePanel("📊 Student Performance Analyzer"),
  sidebarLayout(
    sidebarPanel(
      sliderInput("Sleep",       "Sleep (hours):",           3, 12, 7, step=0.5),
      sliderInput("Study",       "Study (hours):",           0, 20, 5, step=0.5),
      sliderInput("ClassAttend", "Class Attendance (%):",    0, 100, 75),
      sliderInput("OfficeHours", "Office Hours Attendance:", 0, 100, 20),
      sliderInput("Caffeine",    "Caffeine (mg):",           0, 400, 100, step=10),
      hr(),
      sliderInput("Confidence",  "Guarantee Confidence Level (%):",
                  min = 80, max = 99.5, value = 95, step = 0.5, post = "%"),
      numericInput("nSim",       "Monte Carlo Simulations:", 1000, min=200, max=5000, step=100)
    ),
    mainPanel(
      h3("Interactive Analytics"),
      tabsetPanel(
        tabPanel("Predictions", verbatimTextOutput("pred_text")),
        tabPanel("Minimum Needed", verbatimTextOutput("requirements")),
        tabPanel("Heatmaps",
                 tabsetPanel(
                   tabPanel("Sleep × Study", plotOutput("heatmap_sleepstudy")),
                   tabPanel("Study × Attendance", plotOutput("heatmap_studyattend"))
                 )
        ),
        tabPanel("Monte Carlo", plotOutput("monte")),
        tabPanel("PCA Biplot", plotOutput("biplot")),
        tabPanel("Regression Coefficients", plotOutput("coefplot")),
        tabPanel("MANOVA Results", verbatimTextOutput("manova_text")),
        tabPanel("Correlations", plotOutput("corrplot"))
      )
    )
  )
)

# ==== Server ====
server <- function(input, output) {
  user_data <- reactive({
    tibble(
      Sleep       = input$Sleep,
      Study       = input$Study,
      ClassAttend = input$ClassAttend,
      OfficeHours = input$OfficeHours,
      Caffeine    = input$Caffeine
    )
  })
  
  grade_letter <- function(x){
    cut(x, breaks=c(-Inf,60,70,80,90,Inf),
        labels=c("F","D","C","B","A"), right=FALSE)
  }
  
  # Predictions
  output$pred_text <- renderPrint({
    s <- user_data()
    test <- score_fun(s$Sleep, s$Study, s$ClassAttend, s$OfficeHours, s$Caffeine)
    hw   <- score_fun(s$Sleep, s$Study, s$ClassAttend, s$OfficeHours, s$Caffeine/2)
    
    # Standard deviation in the synthetic model is 5
    sigma <- 5
    z <- qnorm(input$Confidence / 100)
    lower_bound_test <- pmax(0, test - z * sigma)
    lower_bound_hw   <- pmax(0, hw - z * sigma)
    
    cat("--- Expected Values (50% average) ---\n")
    cat("Predicted Test Score:", round(test, 1), "-", as.character(grade_letter(test)), "\n")
    cat("Predicted Homework:  ", round(hw, 1),   "-", as.character(grade_letter(hw)), "\n\n")
    cat(paste0("--- At ", input$Confidence, "% Statistical Confidence Guaranteed ---\n"))
    cat("Minimum Expected Test Score:", round(lower_bound_test, 1), "-", as.character(grade_letter(lower_bound_test)), "\n")
    cat("Minimum Expected Homework:  ", round(lower_bound_hw, 1),   "-", as.character(grade_letter(lower_bound_hw)), "\n")
  })
  
  # Minimum Needed Solver with Confidence Safety Margin
  safe_root <- function(f, lo, hi, target){
    flo <- f(lo) - target; fhi <- f(hi) - target
    if (is.na(flo) || is.na(fhi) || flo * fhi > 0) return(NA_real_)
    uniroot(function(x) f(x) - target, lower = lo, upper = hi)$root
  }
  
  output$requirements <- renderPrint({
    s <- user_data()
    targets <- c(60, 70, 80, 90)
    grade_names <- c("D (60%)", "C (70%)", "B (80%)", "A (90%)")
    
    # Calculate required safety buffer based on confidence level
    sigma <- 5
    z <- qnorm(input$Confidence / 100)
    buffer <- z * sigma
    
    cat(paste0("=== Absolute Minimums Needed to Guarantee Grades at ", input$Confidence, "% Confidence ===\n"))
    cat(paste0("(Includes a statistical buffer of +", round(buffer, 1), " pts to protect against random variance)\n\n"))
    
    req_study <- sapply(targets, function(base_target){
      effective_target <- base_target + buffer
      if (effective_target > 100) return("Impossible (>100 score required)")
      
      f <- function(study) score_fun(s$Sleep, study, s$ClassAttend, s$OfficeHours, s$Caffeine)
      val <- safe_root(f, 0, 20, effective_target)
      if (is.na(val)) "Impossible with current sleep/attendance" else paste0(round(val, 2), " h")
    })
    
    req_sleep <- sapply(targets, function(base_target){
      effective_target <- base_target + buffer
      if (effective_target > 100) return("Impossible (>100 score required)")
      
      f <- function(sleep) score_fun(sleep, s$Study, s$ClassAttend, s$OfficeHours, s$Caffeine)
      val <- safe_root(f, 3, 12, effective_target)
      if (is.na(val)) "Impossible with current study/attendance" else paste0(round(val, 2), " h")
    })
    
    names(req_study) <- names(req_sleep) <- grade_names
    
    cat("Holding Sleep at", s$Sleep, "hours -> Minimum Study Hours needed:\n")
    print(as.data.frame(req_study))
    
    cat("\nHolding Study at", s$Study, "hours -> Minimum Sleep Hours needed:\n")
    print(as.data.frame(req_sleep))
  })
  
  # Heatmap Sleep × Study
  output$heatmap_sleepstudy <- renderPlot({
    s <- user_data()
    grid <- expand.grid(Sleep=seq(3,12,len=120), Study=seq(0,20,len=120))
    grid$Score <- score_fun(grid$Sleep, grid$Study, s$ClassAttend, s$OfficeHours, s$Caffeine)
    grid$Grade <- grade_letter(grid$Score)
    ggplot(grid, aes(Sleep, Study)) +
      geom_tile(aes(fill=Grade)) +
      stat_contour(data=grid, aes(x=Sleep,y=Study,z=Score),
                   breaks=c(60,70,80,90), colour="black", linewidth=0.8) +
      geom_point(aes(x=s$Sleep,y=s$Study), inherit.aes=FALSE, color="black", size=3) +
      scale_fill_manual(values=c("F"="#ff4d4d","D"="#ff9933","C"="#ffd633","B"="#99e699","A"="#33cc33"), drop=FALSE) +
      labs(title="Grade Heatmap (Sleep × Study)") + theme_minimal()
  })
  
  # Heatmap Study × Attendance
  output$heatmap_studyattend <- renderPlot({
    s <- user_data()
    grid <- expand.grid(Study=seq(0,20,len=120), ClassAttend=seq(0,100,len=120))
    grid$Score <- score_fun(s$Sleep, grid$Study, grid$ClassAttend, s$OfficeHours, s$Caffeine)
    grid$Grade <- grade_letter(grid$Score)
    ggplot(grid, aes(Study, ClassAttend)) +
      geom_tile(aes(fill=Grade)) +
      stat_contour(data=grid, aes(x=Study,y=ClassAttend,z=Score),
                   breaks=c(60,70,80,90), colour="black", linewidth=0.8) +
      geom_point(aes(x=s$Study,y=s$ClassAttend), inherit.aes=FALSE, color="black", size=3) +
      scale_fill_manual(values=c("F"="#ff4d4d","D"="#ff9933","C"="#ffd633","B"="#99e699","A"="#33cc33"), drop=FALSE) +
      labs(title="Grade Heatmap (Study × Attendance)") + theme_minimal()
  })
  
  # Monte Carlo
  output$monte <- renderPlot({
    s <- user_data()
    sims <- tibble(
      Sleep       = rnorm(input$nSim, s$Sleep, 1),
      Study       = rnorm(input$nSim, s$Study, 1.5),
      ClassAttend = rnorm(input$nSim, s$ClassAttend, 5),
      OfficeHours = rnorm(input$nSim, s$OfficeHours, 6),
      Caffeine    = rnorm(input$nSim, s$Caffeine, 25)
    ) %>%
      mutate(
        Sleep=pmin(pmax(Sleep,3),12),
        Study=pmin(pmax(Study,0),20),
        ClassAttend=pmin(pmax(ClassAttend,0),100),
        OfficeHours=pmin(pmax(OfficeHours,0),100),
        Caffeine=pmin(pmax(Caffeine,0),400)
      )
    df <- data.frame(
      TestScore = score_fun(sims$Sleep, sims$Study, sims$ClassAttend, sims$OfficeHours, sims$Caffeine),
      Homework  = score_fun(sims$Sleep, sims$Study, sims$ClassAttend, sims$OfficeHours, sims$Caffeine/2)
    )
    ggplot(df, aes(TestScore, Homework)) +
      geom_point(alpha=0.25) +
      geom_point(aes(x=score_fun(s$Sleep,s$Study,s$ClassAttend,s$OfficeHours,s$Caffeine),
                     y=score_fun(s$Sleep,s$Study,s$ClassAttend,s$OfficeHours,s$Caffeine/2)),
                 color="red", size=4) +
      xlim(0,100) + ylim(0,100) + theme_minimal()
  })
  
  # PCA biplot
  pca_model <- prcomp(data[, c("Sleep", "Study", "ClassAttend", "OfficeHours", "Caffeine")], scale. = TRUE, center = TRUE)
  output$biplot <- renderPlot({
    scores_user <- as.data.frame(predict(pca_model, newdata = user_data()))
    fviz_pca_biplot(pca_model, repel=TRUE, col.var="blue") +
      geom_point(data=scores_user, aes(PC1, PC2), color="red", size=4)
  })
  
  # Regression Coefficients
  model_test <- lm(TestScore ~ Sleep + Study + ClassAttend + OfficeHours + Caffeine, data=data)
  output$coefplot <- renderPlot({
    tidy_model <- tidy(model_test, conf.int=TRUE) %>% filter(term!="(Intercept)")
    ggplot(tidy_model, aes(x=term,y=estimate)) +
      geom_point(size=3) +
      geom_errorbar(aes(ymin=conf.low,ymax=conf.high), width=0.2) +
      coord_flip() + theme_minimal()
  })
  
  # MANOVA
  output$manova_text <- renderPrint({
    m <- manova(cbind(TestScore, Homework) ~ Sleep + Study + ClassAttend + OfficeHours + Caffeine, data = data)
    summary(m, test = "Wilks")
  })
  
  # Correlations
  output$corrplot <- renderPlot({
    corrplot(cor(data[,c("Sleep","Study","ClassAttend","OfficeHours","Caffeine","TestScore","Homework")]),
             method="color", addCoef.col="black")
  })
}

# ==== Run app ====
shinyApp(ui=ui, server=server)
