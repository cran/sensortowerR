## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(collapse = TRUE, comment = "#>")
library(sensortowerR)
library(dplyr)

## ----eval=FALSE---------------------------------------------------------------
# st_publishers("Supercell") |>
#   st_publisher_apps() |>
#   mutate(cohort = "Supercell portfolio") |>
#   st_metrics(date_from = "2026-01-01", date_to = "2026-03-31",
#              countries = "US", granularity = "monthly")

## ----eval=FALSE---------------------------------------------------------------
# st_apps("Clash of Clans") |>
#   st_app(target_os = "ios") |>
#   st_demographics(date_from = "2026-04-01", date_to = "2026-06-30")

## -----------------------------------------------------------------------------
tibble(app_id = character(), os = character(), cohort = character()) |>
  st_metrics(date_from = "2026-01-01", date_to = "2026-01-31")

