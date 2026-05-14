test_that("st_market_metrics returns tidy long iOS metrics from one aggregate request", {
  requested_urls <- character()

  testthat::local_mocked_bindings(
    perform_request = function(req) {
      requested_urls <<- c(requested_urls, req$url)
      mock_st_response(list(
        list(ca = 7006, cc = "US", d = "2024-01-01T00:00:00Z", iu = 10, au = 5, ir = 1000, ar = 500)
      ))
    },
    st_batch_metrics_impl = function(...) stop("title-level batch path should not be used"),
    st_top_charts_impl = function(...) stop("top charts path should not be used"),
    .package = "sensortowerR"
  )

  result <- st_market_metrics(
    category = 7006,
    countries = "US",
    os = "ios",
    date_from = "2024-01-01",
    date_to = "2024-01-31",
    granularity = "monthly",
    auth_token = "token"
  )

  expect_equal(length(requested_urls), 1)
  expect_true(grepl("/v1/ios/games_breakdown", requested_urls, fixed = TRUE))
  expect_no_title_level_requests(requested_urls)
  expect_equal(
    names(result),
    c("date", "country", "category_id", "os", "metric", "value")
  )
  expect_equal(nrow(result), 2)
  expect_equal(result$value[result$metric == "downloads"], 15)
  expect_equal(result$value[result$metric == "revenue"], 15)
})

test_that("st_market_metrics returns tidy wide Android metrics with dollar revenue", {
  requested_urls <- character()

  testthat::local_mocked_bindings(
    perform_request = function(req) {
      requested_urls <<- c(requested_urls, req$url)
      mock_st_response(list(
        list(ca = "game_casino", cc = "US", d = "2024-01-01T00:00:00Z", u = 20, r = 2500)
      ))
    },
    .package = "sensortowerR"
  )

  result <- st_market_metrics(
    category = "game_casino",
    countries = "US",
    os = "android",
    date_from = "2024-01-01",
    date_to = "2024-01-31",
    granularity = "monthly",
    shape = "wide",
    auth_token = "token"
  )

  expect_equal(length(requested_urls), 1)
  expect_true(grepl("/v1/android/games_breakdown", requested_urls, fixed = TRUE))
  expect_equal(
    names(result),
    c("date", "country", "category_id", "os", "revenue_usd", "downloads")
  )
  expect_equal(result$revenue_usd, 25)
  expect_equal(result$downloads, 20)
})

test_that("st_market_metrics unified makes exactly two aggregate requests", {
  requested_urls <- character()

  testthat::local_mocked_bindings(
    perform_request = function(req) {
      requested_urls <<- c(requested_urls, req$url)

      if (grepl("/v1/ios/games_breakdown", req$url, fixed = TRUE)) {
        return(mock_st_response(list(
          list(ca = 7006, cc = "US", d = "2024-01-01T00:00:00Z", iu = 10, au = 5, ir = 1000, ar = 500)
        )))
      }

      if (grepl("/v1/android/games_breakdown", req$url, fixed = TRUE)) {
        return(mock_st_response(list(
          list(ca = "game_casino", cc = "US", d = "2024-01-01T00:00:00Z", u = 20, r = 2500)
        )))
      }

      stop("Unexpected request URL: ", req$url)
    },
    st_apps = function(...) stop("app discovery should not be used"),
    st_rankings = function(...) stop("rankings should not be used"),
    st_metrics = function(...) stop("app metrics should not be used"),
    st_batch_metrics_impl = function(...) stop("title-level batch path should not be used"),
    st_top_charts_impl = function(...) stop("top charts path should not be used"),
    .package = "sensortowerR"
  )

  result <- st_market_metrics(
    category = c("7006", "game_casino"),
    countries = c("US", "GB"),
    os = "unified",
    date_from = "2024-01-01",
    date_to = "2024-01-31",
    granularity = "monthly",
    shape = "wide",
    auth_token = "token"
  )

  expect_equal(length(requested_urls), 2)
  expect_true(any(grepl("/v1/ios/games_breakdown", requested_urls, fixed = TRUE)))
  expect_true(any(grepl("/v1/android/games_breakdown", requested_urls, fixed = TRUE)))
  expect_no_title_level_requests(requested_urls)
  expect_equal(nrow(result), 1)
  expect_equal(result$os, "unified")
  expect_equal(result$category_id, "7006,game_casino")
  expect_equal(result$revenue_usd, 40)
  expect_equal(result$downloads, 35)
})

test_that("st_market_metrics preserves stable schemas for empty responses", {
  testthat::local_mocked_bindings(
    perform_request = function(req) mock_st_response(list()),
    .package = "sensortowerR"
  )

  long_result <- st_market_metrics(
    category = 7006,
    countries = "US",
    os = "ios",
    date_from = "2024-01-01",
    date_to = "2024-01-31",
    auth_token = "token"
  )
  wide_result <- st_market_metrics(
    category = 7006,
    countries = "US",
    os = "ios",
    date_from = "2024-01-01",
    date_to = "2024-01-31",
    shape = "wide",
    auth_token = "token"
  )

  expect_equal(nrow(long_result), 0)
  expect_equal(
    names(long_result),
    c("date", "country", "category_id", "os", "metric", "value")
  )
  expect_equal(nrow(wide_result), 0)
  expect_equal(
    names(wide_result),
    c("date", "country", "category_id", "os", "revenue_usd", "downloads")
  )
})
