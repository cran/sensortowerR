mock_st_response <- function(payload) {
  httr2::response(
    status_code = 200,
    body = charToRaw(jsonlite::toJSON(payload, auto_unbox = TRUE))
  )
}

expect_no_title_level_requests <- function(urls) {
  forbidden <- c(
    "ranking",
    "top_and_trending",
    "sales_report",
    "apps/timeseries",
    "app_ids",
    "unified_app_ids"
  )
  pattern <- paste(forbidden, collapse = "|")
  testthat::expect_false(any(grepl(pattern, urls)))
}
