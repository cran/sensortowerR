## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(collapse = TRUE, comment = "#>")
library(dplyr)
source(system.file("recipes", "reports.R", package = "sensortowerR"))

## -----------------------------------------------------------------------------
data <- tibble::tibble(
  app_id = "example", os = "unified", country = "US",
  date = as.Date(c("2025-01-01", "2026-01-01")),
  metric = "revenue", value = c(100, 150), unit = "USD", period = "month"
)
recipe_yoy(data)
recipe_portfolio(data)

## ----eval=FALSE---------------------------------------------------------------
# recipe_plot(data)
# recipe_dashboard(data)
# scales::label_dollar()(data$value)

