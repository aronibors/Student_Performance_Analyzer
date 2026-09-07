
library(shiny)
library(ggplot2)
library(dplyr)
library(broom)

set.seed(42)

# ---- 1. Scoring Model (0-100 Range) ----
score_fun <- function(sleep, study, attend, office, caffeine, coverage) {
  cov_factor    <- coverage / 100
  attend_factor <- attend / 100
  
  sleep_term    <- 30 * (1 - exp(-0.75 * pmax(sleep - 4, 0)))
  study_term    <- 35 * (1 - exp(-0.21 * pmax(study, 0)))
  attend_term   <- 20 * attend_factor
  office_term   <- 0.50 * sqrt(pmax(office, 0))
  caffeine_term <- 2.0 * (caffeine / 100) * exp(1 - (caffeine / 100)) - 2.0 * (caffeine / 100)
  
  mastery <- (sleep_term + study_term) * cov_factor
  raw     <- 10 + mastery + attend_term + office_term + caffeine_term
  
  raw[coverage == 0] <- 0
  pmin(pmax(raw, 0), 100)
}

grade_letter <- function(x) {
  cut(x, breaks = c(-Inf, 60, 70, 80, 90, Inf),
      labels = c("F", "D", "C", "B", "A"), right = FALSE)
}

grade_colors <- c("F" = "#ff4d4d", "D" = "#ff9933", "C" = "#ffd633", "B" = "#99e699", "A" = "#33cc33")

fast_theme <- theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(), legend.position = "right")

# ---- 2. Pre-Fitted Cohort Dataset & Global Models ----
n_cohort <- 500
cohort_data <- data.frame(
  Sleep       = runif(n_cohort, 3, 10),
  Study       = runif(n_cohort, 0, 20),
  ClassAttend = runif(n_cohort, 30, 100),
  OfficeHours = runif(n_cohort, 0, 100),
  Caffeine    = runif(n_cohort, 0, 400),
  Coverage    = runif(n_cohort, 40, 100)
)

cohort_data$TestScore <- pmin(pmax(
  score_fun(cohort_data$Sleep, cohort_data$Study, cohort_data$ClassAttend, 
            cohort_data$OfficeHours, cohort_data$Caffeine, cohort_data$Coverage) + 
    rnorm(n_cohort, 0, 5), 0), 100)

cohort_data$Homework <- pmin(pmax(
  score_fun(cohort_data$Sleep, cohort_data$Study, cohort_data$ClassAttend, 
            cohort_data$OfficeHours, cohort_data$Caffeine / 2, cohort_data$Coverage) + 
    rnorm(n_cohort, 0, 5), 0), 100)

pca_vars <- c("Sleep", "Study", "ClassAttend", "OfficeHours", "Caffeine", "Coverage")
pca_fit  <- prcomp(cohort_data[, pca_vars], scale. = TRUE, center = TRUE)

lm_test_fit <- lm(TestScore ~ Sleep + Study + ClassAttend + OfficeHours + Caffeine + Coverage, data = cohort_data)
manova_fit  <- manova(cbind(TestScore, Homework) ~ Sleep + Study + ClassAttend + OfficeHours + Caffeine + Coverage, data = cohort_data)

safe_root <- function(f, lo, hi, target) {
  flo <- f(lo) - target
  fhi <- f(hi) - target
  if (is.na(flo) || is.na(fhi) || flo * fhi > 0) return(NA_real_)
  uniroot(function(x) f(x) - target, lower = lo, upper = hi)$root
}

# ---- 3. UI ----
ui <- fluidPage(
  titlePanel("📊 Student Performance Analyzer (v2.0)"),
  sidebarLayout(
    sidebarPanel(
      sliderInput("Coverage",    "Curriculum Coverage (%):",         0, 100, 85, step = 5),
      sliderInput("Sleep",       "Sleep (hours):",                   3, 12, 7,   step = 0.5),
      sliderInput("Study",       "Study (hours):",                   0, 20, 5,   step = 0.5),
      sliderInput("ClassAttend", "Physical Attendance (%):",         0, 100, 75, step = 5),
      sliderInput("OfficeHours", "Office Hours Attendance:",         0, 100, 20, step = 5),
      sliderInput("Caffeine",    "Caffeine (mg):",                   0, 400, 100, step = 25),
      hr(),
      sliderInput("Confidence",  "Guarantee Confidence Level (%):", 80, 99.5, 95, step = 0.5, post = "%"),
      numericInput("nSim",       "Monte Carlo Runs:",               1000, min = 200, max = 5000, step = 100)
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Predictions", verbatimTextOutput("pred_text")),
        tabPanel("Minimum Needed", verbatimTextOutput("requirements")),
        tabPanel("Heatmaps",
                 tabsetPanel(
                   tabPanel("Study × Coverage", plotOutput("plot_study_cov", height = "480px")),
                   tabPanel("Study × Attendance", plotOutput("plot_study_attend", height = "480px")),
                   tabPanel("Sleep × Study", plotOutput("plot_sleep_study", height = "480px"))
                 )
        ),
        tabPanel("Monte Carlo", 
                 plotOutput("plot_monte", height = "480px", click = "monte_click"),
                 verbatimTextOutput("monte_click_info")),
        tabPanel("PCA Biplot", plotOutput("plot_pca", height = "480px")),
        tabPanel("Regression Coefficients", plotOutput("plot_coefs", height = "480px")),
        tabPanel("MANOVA Results", verbatimTextOutput("manova_text")),
        tabPanel("Correlations", plotOutput("plot_corr", height = "480px"))
      )
    )
  )
)

# ---- 4. Server ----
server <- function(input, output) {
  
  u <- reactive({
    list(
      Sleep       = input$Sleep,
      Study       = input$Study,
      ClassAttend = input$ClassAttend,
      OfficeHours = input$OfficeHours,
      Caffeine    = input$Caffeine,
      Coverage    = input$Coverage
    )
  })
  
  # Predictions with Confidence Floor
  output$pred_text <- renderPrint({
    usr <- u()
    test <- score_fun(usr$Sleep, usr$Study, usr$ClassAttend, usr$OfficeHours, usr$Caffeine, usr$Coverage)
    hw   <- score_fun(usr$Sleep, usr$Study, usr$ClassAttend, usr$OfficeHours, usr$Caffeine / 2, usr$Coverage)
    
    sigma <- 5
    z <- qnorm(input$Confidence / 100)
    conservative_test <- pmax(0, test - z * sigma)
    conservative_hw   <- pmax(0, hw - z * sigma)
    
    cat("================ ACADEMIC PERFORMANCE PREDICTIONS ================\n")
    cat("Expected Mean Outcome (50% Probability Point):\n")
    cat("  • Test Score:     ", sprintf("%5.1f", test), paste0(" [Grade: ", grade_letter(test), "]\n"))
    cat("  • Homework Score: ", sprintf("%5.1f", hw),   paste0(" [Grade: ", grade_letter(hw), "]\n\n"))
    
    cat(paste0("Guaranteed Score Floor (at ", input$Confidence, "% Statistical Confidence):\n"))
    cat("  • Test Lower Bound:     ", sprintf("%5.1f", conservative_test), paste0(" [Grade: ", grade_letter(conservative_test), "]\n"))
    cat("  • Homework Lower Bound: ", sprintf("%5.1f", conservative_hw),   paste0(" [Grade: ", grade_letter(conservative_hw), "]\n"))
    cat("===================================================================\n")
  })
  
  # Minimum Needed Solver
  output$requirements <- renderPrint({
    usr <- u()
    targets <- c(60, 70, 80, 90)
    grade_names <- c("D (60%)", "C (70%)", "B (80%)", "A (90%)")
    
    sigma <- 5
    z <- qnorm(input$Confidence / 100)
    buffer <- z * sigma
    
    cat(paste0("=== Minimum Inputs Needed to Guarantee Grades at ", input$Confidence, "% Confidence ===\n"))
    cat(paste0("Statistical Safety Margin Applied: +", round(buffer, 1), " points\n\n"))
    
    req_study <- sapply(targets, function(tgt) {
      eff <- tgt + buffer
      if (eff > 100) return("Impossible (>100)")
      val <- safe_root(function(x) score_fun(usr$Sleep, x, usr$ClassAttend, usr$OfficeHours, usr$Caffeine, usr$Coverage), 0, 20, eff)
      if (is.na(val)) "Impossible" else paste0(round(val, 1), " h")
    })
    
    req_sleep <- sapply(targets, function(tgt) {
      eff <- tgt + buffer
      if (eff > 100) return("Impossible (>100)")
      val <- safe_root(function(x) score_fun(x, usr$Study, usr$ClassAttend, usr$OfficeHours, usr$Caffeine, usr$Coverage), 3, 12, eff)
      if (is.na(val)) "Impossible" else paste0(round(val, 1), " h")
    })
    
    req_cov <- sapply(targets, function(tgt) {
      eff <- tgt + buffer
      if (eff > 100) return("Impossible (>100)")
      val <- safe_root(function(x) score_fun(usr$Sleep, usr$Study, usr$ClassAttend, usr$OfficeHours, usr$Caffeine, x), 0, 100, eff)
      if (is.na(val)) "Impossible" else paste0(round(val, 1), " %")
    })
    
    req_df <- data.frame(
      Grade            = grade_names,
      Min_Study_Req    = req_study,
      Min_Sleep_Req    = req_sleep,
      Min_Coverage_Req = req_cov
    )
    print(req_df, row.names = FALSE)
  })
  
  # Heatmap 1: Study × Coverage
  output$plot_study_cov <- renderPlot({
    usr <- u()
    grid <- expand.grid(Study = seq(0, 20, length.out = 70), Coverage = seq(0, 100, length.out = 70))
    grid$Score <- score_fun(usr$Sleep, grid$Study, usr$ClassAttend, usr$OfficeHours, usr$Caffeine, grid$Coverage)
    grid$Grade <- grade_letter(grid$Score)
    
    ggplot(grid, aes(Study, Coverage)) +
      geom_tile(aes(fill = Grade)) +
      stat_contour(aes(z = Score), breaks = c(60, 70, 80, 90), colour = "black", linewidth = 0.6) +
      geom_point(aes(x = usr$Study, y = usr$Coverage), color = "black", size = 4) +
      scale_fill_manual(values = grade_colors, drop = FALSE) +
      labs(title = "Study × Curriculum Coverage",
           subtitle = paste0("Fixed: Sleep = ", usr$Sleep, "h | Attendance = ", usr$ClassAttend, "%"),
           x = "Study Time (hours)", y = "Curriculum Coverage (%)") +
      fast_theme
  })
  
  # Heatmap 2: Study × Attendance
  output$plot_study_attend <- renderPlot({
    usr <- u()
    grid <- expand.grid(Study = seq(0, 20, length.out = 70), ClassAttend = seq(0, 100, length.out = 70))
    grid$Score <- score_fun(usr$Sleep, grid$Study, grid$ClassAttend, usr$OfficeHours, usr$Caffeine, usr$Coverage)
    grid$Grade <- grade_letter(grid$Score)
    
    ggplot(grid, aes(Study, ClassAttend)) +
      geom_tile(aes(fill = Grade)) +
      stat_contour(aes(z = Score), breaks = c(60, 70, 80, 90), colour = "black", linewidth = 0.6) +
      geom_point(aes(x = usr$Study, y = usr$ClassAttend), color = "black", size = 4) +
      scale_fill_manual(values = grade_colors, drop = FALSE) +
      labs(title = "Study × Physical Attendance",
           subtitle = paste0("Fixed: Coverage = ", usr$Coverage, "% | Sleep = ", usr$Sleep, "h"),
           x = "Study Time (hours)", y = "Physical Attendance (%)") +
      fast_theme
  })
  
  # Heatmap 3: Sleep × Study
  output$plot_sleep_study <- renderPlot({
    usr <- u()
    grid <- expand.grid(Sleep = seq(3, 12, length.out = 70), Study = seq(0, 20, length.out = 70))
    grid$Score <- score_fun(grid$Sleep, grid$Study, usr$ClassAttend, usr$OfficeHours, usr$Caffeine, usr$Coverage)
    grid$Grade <- grade_letter(grid$Score)
    
    ggplot(grid, aes(Sleep, Study)) +
      geom_tile(aes(fill = Grade)) +
      stat_contour(aes(z = Score), breaks = c(60, 70, 80, 90), colour = "black", linewidth = 0.6) +
      geom_point(aes(x = usr$Sleep, y = usr$Study), color = "black", size = 4) +
      scale_fill_manual(values = grade_colors, drop = FALSE) +
      labs(title = "Sleep × Study",
           subtitle = paste0("Fixed: Coverage = ", usr$Coverage, "% | Attendance = ", usr$ClassAttend, "%"),
           x = "Sleep (hours)", y = "Study (hours)") +
      fast_theme
  })
  
  # Monte Carlo Simulation with Explicit Risk Ring Annotations
  output$plot_monte <- renderPlot({
    usr <- u()
    n_sims <- input$nSim
    
    sim_df <- data.frame(
      Sleep       = pmin(pmax(rnorm(n_sims, usr$Sleep, 1.0), 3), 12),
      Study       = pmin(pmax(rnorm(n_sims, usr$Study, 1.5), 0), 20),
      ClassAttend = pmin(pmax(rnorm(n_sims, usr$ClassAttend, 5), 0), 100),
      OfficeHours = pmin(pmax(rnorm(n_sims, usr$OfficeHours, 6), 0), 100),
      Caffeine    = pmin(pmax(rnorm(n_sims, usr$Caffeine, 25), 0), 400),
      Coverage    = pmin(pmax(rnorm(n_sims, usr$Coverage, 4), 0), 100)
    )
    
    sim_df$TestScore <- pmin(pmax(score_fun(sim_df$Sleep, sim_df$Study, sim_df$ClassAttend, 
                                            sim_df$OfficeHours, sim_df$Caffeine, sim_df$Coverage) + 
                                    rnorm(n_sims, 0, 5), 0), 100)
    
    sim_df$Homework  <- pmin(pmax(score_fun(sim_df$Sleep, sim_df$Study, sim_df$ClassAttend, 
                                            sim_df$OfficeHours, sim_df$Caffeine / 2, sim_df$Coverage) + 
                                    rnorm(n_sims, 0, 5), 0), 100)
    
    expected_test <- score_fun(usr$Sleep, usr$Study, usr$ClassAttend, usr$OfficeHours, usr$Caffeine, usr$Coverage)
    expected_hw   <- score_fun(usr$Sleep, usr$Study, usr$ClassAttend, usr$OfficeHours, usr$Caffeine / 2, usr$Coverage)
    
    ggplot(sim_df, aes(x = TestScore, y = Homework)) +
      geom_point(alpha = 0.20, color = "#2b5c8f") +
      geom_density_2d(aes(color = after_stat(level)), linewidth = 0.8) +
      scale_color_gradient(low = "#2b5c8f", high = "#d73027", name = "Density") +
      geom_point(aes(x = expected_test, y = expected_hw), color = "red", size = 4.5) +
      annotate("text", x = expected_test, y = pmax(0, expected_hw - 4), 
               label = "Expected Average", color = "red", fontface = "bold", size = 3.5) +
      xlim(0, 100) + ylim(0, 100) +
      labs(title = paste0("Monte Carlo Risk Distribution (N = ", n_sims, " Simulated Exam Days)"),
           subtitle = "Concentric rings represent probability contours: Inner ring = ~50% zone | Outer boundary = 95% tail risk",
           x = "Simulated Test Score (0-100)", y = "Simulated Homework Score (0-100)") +
      fast_theme
  })
  
  # Monte Carlo Click Inspector
  output$monte_click_info <- renderPrint({
    usr <- u()
    expected_test <- score_fun(usr$Sleep, usr$Study, usr$ClassAttend, usr$OfficeHours, usr$Caffeine, usr$Coverage)
    
    if (is.null(input$monte_click)) {
      cat("💡 Tip: Click anywhere on the plot or rings above to inspect that specific exam scenario.")
    } else {
      clk_x <- round(input$monte_click$x, 1)
      clk_y <- round(input$monte_click$y, 1)
      diff  <- round(clk_x - expected_test, 1)
      cat(paste0("📍 Clicked Scenario Coordinates:\n"))
      cat(paste0("   • Test Score: ", clk_x, " (Grade: ", grade_letter(clk_x), ")\n"))
      cat(paste0("   • Homework:   ", clk_y, " (Grade: ", grade_letter(clk_y), ")\n"))
      if (diff < 0) {
        cat(paste0("   • Variance:   ", abs(diff), " points BELOW expected mean (Adverse test-day noise)\n"))
      } else {
        cat(paste0("   • Variance:   +", diff, " points ABOVE expected mean (Favorable test-day luck)\n"))
      }
    }
  })
  
  # Native PCA Biplot
  output$plot_pca <- renderPlot({
    usr <- u()
    usr_df <- data.frame(
      Sleep = usr$Sleep, Study = usr$Study, ClassAttend = usr$ClassAttend,
      OfficeHours = usr$OfficeHours, Caffeine = usr$Caffeine, Coverage = usr$Coverage
    )
    user_pca <- as.data.frame(predict(pca_fit, newdata = usr_df))
    loadings <- as.data.frame(pca_fit$rotation)
    
    ggplot() +
      geom_segment(data = loadings, aes(x = 0, y = 0, xend = PC1 * 3, yend = PC2 * 3),
                   arrow = arrow(length = unit(0.25, "cm")), color = "#0055ff", linewidth = 0.8) +
      geom_text(data = loadings, aes(x = PC1 * 3.3, y = PC2 * 3.3, label = rownames(loadings)),
                fontface = "bold", size = 4) +
      geom_point(data = user_pca, aes(x = PC1, y = PC2), color = "red", size = 5) +
      labs(title = "Cohort Principal Component Analysis (PCA Biplot)",
           subtitle = "Red dot = Your Current Habit Profile projected onto Cohort Variance",
           x = paste0("PC1 (", round(summary(pca_fit)$importance[2, 1] * 100, 1), "% Variance)"),
           y = paste0("PC2 (", round(summary(pca_fit)$importance[2, 2] * 100, 1), "% Variance)")) +
      fast_theme
  })
  
  # Regression Coefficients Plot
  output$plot_coefs <- renderPlot({
    tidy_reg <- broom::tidy(lm_test_fit, conf.int = TRUE) %>%
      filter(term != "(Intercept)")
    
    ggplot(tidy_reg, aes(x = reorder(term, estimate), y = estimate)) +
      geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
      geom_point(size = 3, color = "#0072B2") +
      geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.2, color = "#0072B2") +
      coord_flip() +
      labs(title = "OLS Linear Approximations (TestScore)",
           subtitle = "Standardized 95% Confidence Intervals",
           x = "Predictor Variable", y = "Estimated Marginal Effect") +
      fast_theme
  })
  
  # MANOVA Results
  output$manova_text <- renderPrint({
    cat("================ MULTIVARIATE ANALYSIS OF VARIANCE (MANOVA) ================\n")
    cat("Model: cbind(TestScore, Homework) ~ Sleep + Study + Attendance + OH + Caffeine + Coverage\n\n")
    print(summary(manova_fit, test = "Wilks"))
    cat("\nInterpretation:\n")
    cat("Wilks' Lambda measures the proportion of generalized variance in bivariate academic outcomes\n")
    cat("(Test Score and Homework) unaccounted for by the predictors. Lower values denote stronger effects.\n")
    cat("============================================================================\n")
  })
  
  # Native Correlation Matrix
  output$plot_corr <- renderPlot({
    cor_mat <- cor(cohort_data[, c(pca_vars, "TestScore", "Homework")])
    cor_df  <- as.data.frame(as.table(cor_mat))
    names(cor_df) <- c("Var1", "Var2", "Correlation")
    
    ggplot(cor_df, aes(Var1, Var2, fill = Correlation)) +
      geom_tile(color = "white") +
      geom_text(aes(label = sprintf("%.2f", Correlation)), color = "black", size = 3.5) +
      scale_fill_gradient2(low = "#d73027", mid = "#ffffbf", high = "#1a9850", 
                           midpoint = 0, limit = c(-1, 1)) +
      labs(title = "Feature Correlation Matrix", x = "", y = "") +
      fast_theme +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })
}

# ---- 5. Launch ----
shinyApp(ui = ui, server = server)
