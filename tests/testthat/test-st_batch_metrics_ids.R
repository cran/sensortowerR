test_that("unified batch metrics canonicalize active-user pair IDs to unified app IDs", {
  app_map <- tibble::tibble(
    app_id = "requested_game",
    app_name = "Requested Game",
    unified_id = "abcdefabcdefabcdefabcdef",
    ios_id = "123456789",
    android_id = "com.example.game"
  )

  testthat::local_mocked_bindings(
    resolve_auth_token = function(auth_token, env_var = "SENSORTOWER_AUTH_TOKEN", error_message = NULL) {
      "token"
    },
    fetch_active_users_request = function(platform_os,
                                          app_ids,
                                          metric_name,
                                          countries,
                                          date_range,
                                          default_time_period,
                                          auth_token,
                                          verbose = FALSE) {
      tibble::tibble(
        app_id = as.character(app_ids),
        date = as.Date("2026-04-01"),
        country = "US",
        metric = metric_name,
        value = if (platform_os == "ios") 10 else 20,
        platform = platform_os
      )
    },
    st_sales_report_impl = function(os, ...) {
      tibble::tibble(
        date = as.Date("2026-04-01"),
        country = "US",
        revenue = if (os == "ios") 100 else 200,
        downloads = if (os == "ios") 1 else 2
      )
    },
    .package = "sensortowerR"
  )

  result <- sensortowerR:::st_batch_metrics_impl(
    os = "unified",
    app_list = app_map,
    metrics = c("revenue", "downloads", "dau"),
    date_range = list(start_date = as.Date("2026-04-01"), end_date = as.Date("2026-04-30")),
    countries = "US",
    granularity = "monthly",
    verbose = FALSE,
    auth_token = "token"
  )

  expect_equal(unique(result$app_id), "abcdefabcdefabcdefabcdef")
  expect_equal(unique(result$app_id_type), "unified")
  expect_equal(unique(result$original_id), "requested_game")
  expect_true("entity_id" %in% names(result))
  expect_true("platform_pair_id" %in% names(result))
  expect_true("123456789_com.example.game" %in% result$entity_id)
  expect_true("123456789_com.example.game" %in% stats::na.omit(result$platform_pair_id))

  wide <- tidyr::pivot_wider(
    result,
    id_cols = c("app_id", "date", "country"),
    names_from = "metric",
    values_from = "value"
  )
  expect_equal(nrow(wide), 1)
  expect_equal(wide$revenue, 300)
  expect_equal(wide$downloads, 3)
  expect_equal(wide$dau, 30)
})

test_that("st_active_users unified outputs do not expose platform-pair app IDs", {
  batch_result <- tibble::tibble(
    original_id = "requested_game",
    app_name = "Requested Game",
    app_id = "abcdefabcdefabcdefabcdef",
    entity_id = "123456789_com.example.game",
    platform_pair_id = "123456789_com.example.game",
    app_id_type = "unified",
    date = as.Date("2026-04-01"),
    country = "US",
    metric = "dau",
    value = 30
  )

  testthat::local_mocked_bindings(
    resolve_auth_token = function(auth_token, env_var = "SENSORTOWER_AUTH_TOKEN", error_message = NULL) {
      "token"
    },
    st_batch_metrics_impl = function(...) batch_result,
    .package = "sensortowerR"
  )

  result <- st_active_users(
    os = "unified",
    app_list = "requested_game",
    metrics = "dau",
    countries = "US",
    auth_token = "token",
    verbose = FALSE
  )

  expect_equal(result$app_id, "abcdefabcdefabcdefabcdef")
  expect_equal(result$app_id_type, "unified")
  expect_false(any(grepl("_", result$app_id, fixed = TRUE)))
  expect_equal(result$entity_id, "123456789_com.example.game")
  expect_equal(result$platform_pair_id, "123456789_com.example.game")
})

test_that("batch finalization keeps platform IDs without unified mapping and prefers unified IDs when present", {
  raw_result <- tibble::tibble(
    app_id = c("123456789", "com.example.game", "222_com.example.two"),
    entity_id = c("123456789", "com.example.game", "222_com.example.two"),
    date = as.Date("2026-04-01"),
    country = "US",
    metric = "dau",
    value = c(10, 20, 30)
  )
  app_map <- tibble::tibble(
    app_id = c("123456789", "com.example.game", "requested_two"),
    app_name = c("iOS Only", "Android Only", "Mapped Both"),
    unified_id = c(NA_character_, NA_character_, "fedcbafedcbafedcbafedcba"),
    ios_id = c("123456789", NA_character_, "222"),
    android_id = c(NA_character_, "com.example.game", "com.example.two")
  )

  result <- sensortowerR:::finalize_batch_results(raw_result, app_map)

  expect_equal(result$app_id[result$entity_id == "123456789"], "123456789")
  expect_equal(result$app_id_type[result$entity_id == "123456789"], "ios")
  expect_equal(result$app_id[result$entity_id == "com.example.game"], "com.example.game")
  expect_equal(result$app_id_type[result$entity_id == "com.example.game"], "android")
  expect_equal(result$app_id[result$entity_id == "222_com.example.two"], "fedcbafedcbafedcbafedcba")
  expect_equal(result$app_id_type[result$entity_id == "222_com.example.two"], "unified")
  expect_equal(result$platform_pair_id[result$entity_id == "222_com.example.two"], "222_com.example.two")
})
