# Student Performance Analyzer

An interactive **R Shiny** decision-support application that estimates the minimum combination of study time, sleep, class attendance, and office hours required to achieve target academic outcomes.

🌐 **Live Application**  
https://aronibors.shinyapps.io/Student_Performance_Analyzer/

---

## Application Overview

The Student Performance Analyzer combines interactive visualization, statistical modeling, and simulation to explore how academic behaviors influence performance.

Rather than functioning solely as a grade predictor, the application allows users to explore how different combinations of study time, sleep, attendance, office hours, and caffeine consumption influence expected outcomes while visualizing the trade-offs between them.

![Student Performance Analyzer](HeatmapDecisionBoundary-png)

---

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

## Technologies

- R
- Shiny
- ggplot2
- dplyr
- GGally
- factoextra
- corrplot
- broom
- metR

---

## Repository Contents

- `Student_Performance_Analyzer.R` — Complete R Shiny application source code
- `README.md` — Project documentation
- `LICENSE` — GNU General Public License v3.0 (GPL-3.0)

---

## Author

**Aron Bors**

- LinkedIn: https://www.linkedin.com/in/aron-bors-066679237
- GitHub: https://github.com/aronibors
