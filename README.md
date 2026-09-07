# Student Performance Analyzer (v2.0)

An interactive **R Shiny** decision-support engine and risk-modeling framework tailored for rigorous, proof-heavy STEM disciplines (Real Analysis, Quantum Mechanics, Theoretical Computer Science). 

The application pairs non-linear cognitive growth models with multivariate inference and stochastic simulation, allowing students to solve the **inverse optimization problem**: identifying the minimal, necessary resource allocation required to guarantee target academic grades under adverse test-day variance.

🔗 **Live Application**  
[https://aronibors.shinyapps.io/Student_Performance_Analyzer/](https://aronibors.shinyapps.io/Student_Performance_Analyzer/)

---

## Application Overview

Traditional academic predictors focus on the **forward problem**:
> *"Given my current habits, what grade can I expect?"*

In rigorous STEM programs, this perspective often leads to inefficient over-studying or unexpected test-day failures due to cognitive exhaustion. The Student Performance Analyzer instead solves the **inverse problem**:
> *"Given my desired grade and target confidence level, what is the minimum necessary combination of study, sleep, and syllabus coverage required?"*

By distinguishing **necessary conditions** from merely **sufficient effort**, users can identify high-leverage habits, preserve time for rest and competing priorities, and protect their GPA against downside exam-day risk.

---

## What’s New in v2.0

- **Vectorized Decision-Boundary Heatmaps:** Re-engineered the underlying 2D evaluation pipeline with vectorized boundary conditions, eliminating dimension-recycling errors across all multi-variable slices (`Study × Coverage`, `Study × Attendance`, `Sleep × Study`).
- **Interactive Monte Carlo Click-Inspector:** Canvas click-listener capturing real-time $(x, y)$ coordinates to compute empirical grade differentials against expected centroids under stochastic noise ($\sigma = 5.0$).
- **Multivariate Hypothesis Engine (MANOVA):** Integrated joint-outcome testing using Wilks' Lambda ($\Lambda$) to evaluate shared variance across correlated test scores and homework assignments.
- **De-cluttered PCA Biplots:** Overhauled cohort principal component projections to focus exclusively on dominant eigenvector loadings and individual habit projections, removing background point noise.

---

## Analytical Architecture

text
                                  +-------------------+
                                  | Curriculum (Cov%) |
                                  +---------+---------+
                                            |
                                            v (Multiplicative Bottleneck)
[Sleep (hrs)] ---> (Cognitive Floor)  \ 
                                       *===> [Usable Mastery] --+
[Study (hrs)] ---> (Diminishing Return)/                        |
                                                                +---> [Expected Score]
[Attendance%] ---> (Direct Linear Exposure) --------------------+     (0 - 100)
[Office Hrs]  ---> (Concave Support, sqrt)  --------------------+
[Caffeine]    ---> (Non-linear Jitter/Crash) -------------------+
```### 1. The Forward Model: Scoring Dynamics Upper-division STEM coursework requires deep quantifier manipulation and conceptual synthesis where rote memorization fails. The scoring engine models these constraints explicitly:
```
$$\text{Mastery} = \Big(S_{\text{sleep}} + S_{\text{study}}\Big) \times \left(\frac{\text{Coverage}}{100}\right)$$

$$\text{Expected Score} = \text{Clamp}_{[0, 100]}\Big(10 + \text{Mastery} + T_{\text{attend}} + T_{\text{office}} + T_{\text{caffeine}}\Big)$$

- **The Multiplicative Bottleneck:** Usable mastery is gated by syllabus coverage. No amount of study time or cognitive rest can unlock points on unreviewed theoretical definitions or proofs.
- **10-Point Baseline Floor:** Calibrated for realistic proof/FRQ exam rubrics—accounting for elementary setup notation, base cases, and definitions while preventing unearned partial credit.
- **Asymmetric Sleep Saturation:** Incorporates an exponential threshold modeling the severe working-memory loss observed below 4.5 hours of sleep.

### 2. The Inverse Problem: Minimum Resource Solver
The analyzer inverts the scoring function using 1D numerical root-finding (`uniroot`) across user parameters.

To defend against downside variance, the solver targets an augmented threshold:

$$\text{Target}_{\text{effective}} = \text{Target} + z_{\alpha} \times \sigma$$

where $z_{\alpha} = \Phi^{-1}(1 - \alpha)$ and $\sigma = 5.0\text{ points}$.

---

## Core Modules & Visualizations

| Module | Statistical Method | Analytical Objective |
| :--- | :--- | :--- |
| **Predictions & Floor** | Parametric Cutoffs ($z$-score) | Projects mean expected score vs. guaranteed conservative floor at $80\%\text{--}99.5\%$ confidence. |
| **Minimum Needed** | Numerical Root-Finding (`uniroot`) | Computes exact minimum thresholds for Sleep, Study, and Coverage needed to secure grades A through D. |
| **Decision Heatmaps** | Iso-Score Contour Mapping (`geom_tile`) | Visualizes orthogonal 2D trade-offs and non-linear contour boundaries across behavioral pairs. |
| **Monte Carlo Risk** | Stochastic Sampling ($\mathcal{N}(0, 5^2)$) | Simulates $N \in [200, 5000]$ exam scenarios with 2D kernel density rings and interactive click diagnostics. |
| **Cohort PCA** | SVD / Eigenvector Decomposition | Projects 6D habit vectors onto the primary 2D principal component plane ($\sim 37\%$ cohort variance). |
| **MANOVA** | Wilks' Lambda ($\Lambda$) Estimation | Quantifies the generalized variance of joint outcomes ($\mathbf{Y} = [\text{TestScore}, \text{Homework}]^T$). |
| **Feature Correlations** | Pearson Correlation Matrix | Evaluates collinearity and verifies input orthogonality across generated cohorts. |

---

## Tech Stack & Dependencies

- **Language:** R (>= 4.0.0)
- **Framework:** Shiny
- **Visualization:** ggplot2
- **Statistical Computing:** stats` (`prcomp`, `manova`, `lm`, `uniroot`, `rnorm`)
```
---
```
## Local Setup & Installation

To run the application locally:
```
```
# 1. Clone the repository git clone [https://github.com/aronibors/Student_Performance_Analyzer.git](https://github.com/aronibors/Student_Performance_Analyzer.git)
```r# 2. Install dependencies- install.packages(c("shiny", "ggplot2"))
```
# 3. Launch application
shiny::runApp("Student_Performance_Analyzer.R")

## License

This project is licensed under the [GNU General Public License v3.0 (GPL-3.0)](https://www.gnu.org/licenses/gpl-3.0.en.html).

---

## Author

**Aron Bors**

- **LinkedIn:** [aron-bors-066679237](https://www.linkedin.com/in/aron-bors-066679237/)
- **GitHub:** [@aronibors](https://github.com/aronibors)
