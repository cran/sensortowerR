test_that("live st_market_metrics smoke test uses aggregate market parameters", {
  skip_on_cran()
  skip_if_no_auth()

  result <- st_market_metrics(
    category = 7001,
    countries = "US",
    os = "ios",
    date_from = "2024-01-01",
    date_to = "2024-01-31",
    granularity = "monthly",
    shape = "wide"
  )

  expect_s3_class(result, "tbl_df")
  expect_true(all(c("date", "country", "category_id", "os", "revenue_usd", "downloads") %in% names(result)))
  if (nrow(result) > 0) {
    expect_true(all(result$revenue_usd >= 0, na.rm = TRUE))
    expect_true(all(result$downloads >= 0, na.rm = TRUE))
    expect_equal(unique(result$os), "ios")
    expect_equal(unique(result$country), "US")
  }
})
