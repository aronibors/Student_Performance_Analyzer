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

## Design

Unlike traditional grade predictors, this project was designed as a **decision-support tool**.

Instead of answering:

> *"What grade will I receive?"*

it answers:

> **"What is the minimum combination of study, sleep, attendance, and office hours required to achieve my desired grade?"**

The resulting decision boundaries allow users to visualize trade-offs between behaviors while exploring how changes in one variable influence the minimum requirements of another.

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
