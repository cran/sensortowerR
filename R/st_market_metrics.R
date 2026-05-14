#' Fetch Aggregate Sensor Tower Market Metrics
#'
#' Tidy facade for market/category revenue and download denominators. This
#' function routes to Sensor Tower's aggregate `games_breakdown` endpoint through
#' [st_game_summary()] and never approximates market totals by enumerating apps,
#' rankings, top charts, or title cohorts.
#'
#' @param category Character or numeric vector of Sensor Tower game category IDs.
#'   iOS and Android use different category identifiers; pass the appropriate
#'   platform category for platform-specific calls, or the full platform basket
#'   for `os = "unified"`.
#' @param countries Character vector of 2-letter country codes. Use `"WW"` for
#'   worldwide.
#' @param os Character scalar. One of `"ios"`, `"android"`, or `"unified"`.
#' @param date_from,date_to Date bounds for the query. Accept `Date` objects or
#'   ISO date strings.
#' @param granularity Character scalar. One of `"daily"`, `"weekly"`,
#'   `"monthly"`, or `"quarterly"`.
#' @param metrics Character vector. One or both of `"revenue"` and `"downloads"`.
#' @param revenue_unit Character scalar. `"dollars"` returns revenue in base
#'   currency units. `"cents"` returns revenue in cents.
#' @param shape Character scalar. `"long"` returns one row per metric
#'   observation. `"wide"` returns metric columns.
#' @param auth_token Optional Sensor Tower API token. If `NULL`, falls back to
#'   `SENSORTOWER_AUTH_TOKEN`.
#'
#' @return
#' If `shape = "long"`, a tibble with columns `date`, `country`, `category_id`,
#' `os`, `metric`, and `value`. If `shape = "wide"`, a tibble with columns
#' `date`, `country`, `category_id`, `os`, and requested metric columns.
#'
#' @section Denominator Safety:
#' Use `st_market_metrics()` for game category market denominators. Use
#' [st_rankings()], [st_apps()], and custom-field top-chart workflows for
#' discovery, leaderboards, and title cohorts only. True Game IQ subgenre market
#' denominators require a Sensor Tower market-size export or another confirmed
#' aggregate market endpoint.
#'
#' @examples
#' \dontrun{
#' casino_market <- st_market_metrics(
#'   category = c("7006", "game_casino"),
#'   countries = "WW",
#'   os = "unified",
#'   date_from = "2025-01-01",
#'   date_to = "2025-12-31",
#'   granularity = "monthly"
#' )
#' }
#'
#' @export
st_market_metrics <- function(category,
                              countries,
                              os,
                              date_from,
                              date_to,
                              granularity = "monthly",
                              metrics = c("revenue", "downloads"),
                              revenue_unit = c("dollars", "cents"),
                              shape = c("long", "wide"),
                              auth_token = NULL) {
  if (missing(category) || is.null(category) || !length(category)) {
    rlang::abort("`category` must be a non-empty character or numeric vector.")
  }

  category <- unique(as.character(category))
  if (any(is.na(category) | !nzchar(category))) {
    rlang::abort("`category` entries must be non-empty strings.")
  }

  os <- normalize_os(os)
  countries <- normalize_countries(countries)
  dates <- normalize_dates(date_from, date_to)
  granularity <- normalize_granularity(granularity)
  metrics <- normalize_metrics(metrics, allowed = c("revenue", "downloads"))
  revenue_unit <- match.arg(revenue_unit)
  shape <- match.arg(shape)
  auth_token <- get_auth_token(
    auth_token,
    error_message = paste(
      "Authentication token is required.",
      "Set SENSORTOWER_AUTH_TOKEN or pass `auth_token`."
    )
  )

  raw <- st_game_summary(
    categories = category,
    countries = countries,
    os = os,
    date_granularity = granularity,
    start_date = dates$date_from,
    end_date = dates$date_to,
    auth_token = auth_token,
    enrich_response = TRUE
  )

  .st_market_metrics_normalize(
    data = raw,
    category = category,
    os = os,
    metrics = metrics,
    revenue_unit = revenue_unit,
    shape = shape
  )
}

.st_market_metrics_normalize <- function(data,
                                         category,
                                         os,
                                         metrics,
                                         revenue_unit,
                                         shape) {
  if (is.null(data) || !nrow(data)) {
    return(.st_market_metrics_empty(shape = shape, metrics = metrics, revenue_unit = revenue_unit))
  }

  data <- tibble::as_tibble(data)
  n <- nrow(data)
  category_label <- paste(category, collapse = ",")

  date <- .st_market_col(data, "Date", default = as.Date(rep(NA_character_, n)))
  country <- .st_market_col(data, "Country Code", default = rep(NA_character_, n))
  category_id <- if ("Category" %in% names(data)) {
    as.character(data$Category)
  } else {
    rep(category_label, n)
  }

  revenue_col <- dplyr::case_when(
    os == "ios" ~ "iOS Revenue",
    os == "android" ~ "Android Revenue",
    TRUE ~ "Total Revenue"
  )
  downloads_col <- dplyr::case_when(
    os == "ios" ~ "iOS Downloads",
    os == "android" ~ "Android Downloads",
    TRUE ~ "Total Downloads"
  )

  wide <- tibble::tibble(
    date = as.Date(date),
    country = as.character(country),
    category_id = as.character(category_id),
    os = rep(os, n),
    revenue_usd = .st_market_numeric_col(data, revenue_col),
    downloads = .st_market_numeric_col(data, downloads_col)
  )

  if (identical(revenue_unit, "cents")) {
    wide$revenue_usd <- wide$revenue_usd * 100
    names(wide)[names(wide) == "revenue_usd"] <- "revenue_cents"
  }

  metric_cols <- .st_market_metric_columns(metrics, revenue_unit)
  wide <- dplyr::select(wide, dplyr::all_of(c("date", "country", "category_id", "os", metric_cols)))

  if (identical(shape, "wide")) {
    return(wide)
  }

  long <- tidyr::pivot_longer(
    wide,
    cols = dplyr::all_of(metric_cols),
    names_to = "metric",
    values_to = "value"
  )
  long$metric <- dplyr::recode(
    long$metric,
    revenue_usd = "revenue",
    revenue_cents = "revenue",
    downloads = "downloads"
  )
  dplyr::select(long, date, country, category_id, os, metric, value)
}

.st_market_metrics_empty <- function(shape, metrics, revenue_unit) {
  if (identical(shape, "wide")) {
    metric_cols <- .st_market_metric_columns(metrics, revenue_unit)
    out <- tibble::tibble(
      date = as.Date(character()),
      country = character(),
      category_id = character(),
      os = character()
    )
    for (col in metric_cols) {
      out[[col]] <- numeric()
    }
    return(out)
  }

  tibble::tibble(
    date = as.Date(character()),
    country = character(),
    category_id = character(),
    os = character(),
    metric = character(),
    value = numeric()
  )
}

.st_market_metric_columns <- function(metrics, revenue_unit) {
  cols <- character()
  if ("revenue" %in% metrics) {
    cols <- c(cols, if (identical(revenue_unit, "cents")) "revenue_cents" else "revenue_usd")
  }
  if ("downloads" %in% metrics) {
    cols <- c(cols, "downloads")
  }
  cols
}

.st_market_col <- function(data, column, default) {
  if (column %in% names(data)) {
    return(data[[column]])
  }
  default
}

.st_market_numeric_col <- function(data, column) {
  if (!column %in% names(data)) {
    return(rep(NA_real_, nrow(data)))
  }
  as.numeric(data[[column]])
}
