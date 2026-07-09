# Student Performance Analyzer

An interactive **R Shiny** decision-support application that estimates the minimum combination of study time, sleep, class attendance, and office hours required to achieve target academic outcomes.

**Live Application:**  
https://aronibors.shinyapps.io/Student_Performance_Analyzer/

---

## Application Overview

Rather than simply predicting grades, this application answers a practical question:

> **Given a desired academic outcome, what is the minimum combination of behaviors needed to achieve it?**

Users adjust study habits through an interactive interface while the application estimates expected performance, visualizes decision boundaries, and identifies minimum input combinations required to reach target grade thresholds.

![Student Performance Analyzer](HeatmapDecisionBoundary-png)

---

## Features

- Interactive prediction of test and homework performance
- Minimum study and sleep requirements for target grades
- Decision-boundary heatmaps
- Monte Carlo simulation
- Principal Component Analysis (PCA)
- Multiple Linear Regression
- MANOVA
- Correlation analysis
- Interactive parameter controls

---

## Statistical Methods

This application integrates several statistical and analytical techniques:

- Principal Component Analysis (PCA)
- Multiple Linear Regression
- MANOVA
- Monte Carlo Simulation
- Correlation Analysis
- Nonlinear predictive modeling
- Root-finding algorithms for minimum input estimation
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

## Analytical Framework

The application approaches academic performance as an input-minimization problem rather than an output-maximization problem.

Instead of asking, *"Given 20 hours of study, what grade can I expect?"* it asks, *"Given a target grade, what is the minimum combination of study time, sleep, attendance, and office hours required to achieve it?"*

By estimating decision boundaries, the model distinguishes **necessary** inputs from merely **sufficient** ones, emphasizing efficient allocation of time rather than unnecessary effort.
---

## Repository Contents

- `Student_Performance_Analyzer.R` — Complete R Shiny application source code
- `README.md` — Project documentation
- `LICENSE` — GNU GPL v3 License

---

## Author

**Aron Bors**

**LinkedIn:** https://www.linkedin.com/in/aron-bors-066679237

**GitHub:** https://github.com/aronibors
