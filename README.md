# Student Performance Analyzer

An interactive **R Shiny** decision-support application that estimates the minimum combination of study time, sleep, class attendance, and office hours required to achieve target academic outcomes.

 **Live Application**  
https://aronibors.shinyapps.io/Student_Performance_Analyzer/

---

## Application Overview

The Student Performance Analyzer combines interactive visualization, statistical modeling, and simulation to explore how academic behaviors influence performance.

Rather than functioning solely as a grade predictor, the application allows users to explore how different combinations of study time, sleep, attendance, office hours, and caffeine consumption influence expected outcomes while visualizing the trade-offs between them.

![Student Performance Analyzer](HeatMapDecisionBoundaryUpdate-png)

---
## What’s New in v2.0

- **Vectorized Decision-Boundary Heatmaps:** Re-engineered the underlying 2D evaluation pipeline with vectorized boundary conditions, eliminating dimension-recycling errors across all multi-variable slices (`Study × Coverage`, `Study × Attendance`, `Sleep × Study`).
- **Interactive Monte Carlo Click-Inspector:** Canvas click-listener capturing real-time $(x, y)$ coordinates to compute empirical grade differentials against expected centroids under stochastic noise ($\sigma = 5.0$).
- **Multivariate Hypothesis Engine (MANOVA):** Integrated joint-outcome testing using Wilks' Lambda ($\Lambda$) to evaluate shared variance across correlated test scores and homework assignments.
- **De-cluttered PCA Biplots:** Overhauled cohort principal component projections to focus exclusively on dominant eigenvector loadings and individual habit projections, removing background point noise.
## Features

- Interactive grade prediction
- Minimum-input estimation for target grades
- Decision-boundary heatmaps
- Monte Carlo simulation
- Principal Component Analysis (PCA)
- Multiple Linear Regression
- MANOVA
- Correlation analysis
- Interactive parameter controls

---

## Analytical Framework

Most predictive models solve the **forward problem**:

> **Given a set of inputs, what output can be expected?**

This application instead solves the **inverse problem**:

> **Given a desired output, what is the minimum combination of inputs required to achieve it?**

Traditional prediction identifies input combinations that are **sufficient** to produce an outcome. This application instead estimates the **minimum necessary** study time, sleep, attendance, and office hour participation required to achieve each target grade.

The resulting decision boundaries distinguish **necessary** from merely **sufficient** combinations of academic behaviors, emphasizing efficient allocation of time rather than unnecessary effort. By minimizing required inputs, users can preserve additional time for work, leisure, skill development, or other competing priorities while still achieving their desired academic outcomes.

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


## Statistical Methods

This application integrates multiple analytical techniques:

- Principal Component Analysis (PCA)
- Multiple Linear Regression
- MANOVA
- Monte Carlo Simulation
- Correlation Analysis
- Nonlinear predictive modeling
- Root-finding algorithms for minimum-input estimation
- Decision-boundary visualization

---

## Libraries

- R
- Shiny
- ggplot2
- dplyr
- corrplot
- broom
- metR

---

## Repository Contents

- `Student_Performance_Analyzer.R` — Complete R Shiny application source code
- `README.md` — Project documentation
- `LICENSE` — GNU General Public License v3.0 (GPL-3.0)

---
## License

This project is licensed under the [GNU General Public License v3.0 (GPL-3.0)](https://www.gnu.org/licenses/gpl-3.0.en.html).

---

## Author

**Aron Bors**

- **LinkedIn:** [aron-bors-066679237](https://www.linkedin.com/in/aron-bors-066679237/)
- **GitHub:** [@aronibors](https://github.com/aronibors)

