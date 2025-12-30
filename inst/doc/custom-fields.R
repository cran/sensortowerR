## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## -----------------------------------------------------------------------------
# library(sensortowerR)
# library(dplyr)

## ----discover-----------------------------------------------------------------
# # See all available fields
# all_fields <- st_discover_fields()
# head(all_fields)
# 
# # Search for specific fields
# game_fields <- st_discover_fields("game")
# monetization_fields <- st_discover_fields("monetization")
# 
# # Show fields with their possible values
# genre_fields <- st_discover_fields("genre", show_values = TRUE)

## ----simple-filters-----------------------------------------------------------
# # Filter for Word games
# word_filter <- st_create_simple_filter(
#   field_name = "Game Sub-genre",
#   field_values = "Word"
# )
# 
# # Filter for free apps with ads
# free_with_ads <- st_create_simple_filter(
#   field_name = "Free",
#   field_values = list(),  # Boolean field
#   global = TRUE
# )

## ----get-apps-----------------------------------------------------------------
# # Get top Word games by DAU
# word_games <- st_get_filtered_apps(
#   field_name = "Game Sub-genre",
#   field_values = "Word",
#   measure = "DAU",
#   regions = "US",
#   limit = 20
# )
# 
# # Use an existing filter ID
# apps <- st_get_filtered_apps(
#   filter_id = word_filter,
#   measure = "revenue",
#   regions = "US",
#   date = "2025-07-01",
#   end_date = "2025-07-31"
# )

## ----genre-filtering----------------------------------------------------------
# # Get Puzzle games
# puzzle_filter <- st_filter_by_genre(genres = "Puzzle")
# 
# # Get Word Puzzle games (multiple criteria)
# word_puzzle_filter <- st_filter_by_genre(
#   genres = "Puzzle",
#   sub_genres = "Word"
# )
# 
# # Exclude certain genres
# no_action_filter <- st_filter_by_genre(
#   genres = c("Action", "Shooter"),
#   exclude_genres = TRUE
# )

## ----monetization-------------------------------------------------------------
# # Free-to-play with ads
# f2p_ads <- st_filter_by_monetization(
#   free_only = TRUE,
#   has_ads = TRUE
# )
# 
# # Premium games (paid, no IAP)
# premium <- st_filter_by_monetization(
#   free_only = FALSE,
#   has_iap = FALSE
# )
# 
# # Subscription-based apps
# subscription <- st_filter_by_monetization(
#   has_subscription = TRUE
# )
# 
# # Hybrid monetization (IAP + Ads)
# hybrid <- st_filter_by_monetization(
#   has_iap = TRUE,
#   has_ads = TRUE
# )

## ----sdk-filtering------------------------------------------------------------
# # Unity-based games
# unity_games <- st_filter_by_sdk(sdk_names = "Unity")
# 
# # Apps using multiple SDKs
# firebase_admob <- st_filter_by_sdk(
#   sdk_names = c("Firebase", "AdMob")
# )
# 
# # Apps NOT using certain SDKs
# no_facebook <- st_filter_by_sdk(
#   sdk_names = "Facebook",
#   exclude = TRUE
# )

## ----date-filtering-----------------------------------------------------------
# # New releases (last 30 days)
# new_releases <- st_filter_by_date(
#   released_after = Sys.Date() - 30,
#   region = "US"
# )
# 
# # Apps released in 2024
# apps_2024 <- st_filter_by_date(
#   released_after = "2024-01-01",
#   released_before = "2024-12-31",
#   region = "WW"
# )
# 
# # Established apps (>1 year old)
# established <- st_filter_by_date(
#   released_before = Sys.Date() - 365,
#   region = "US"
# )

## ----publisher----------------------------------------------------------------
# # Apps from specific publishers
# ea_games <- st_filter_by_publisher(
#   publisher_names = c("Electronic Arts", "EA Swiss Sarl")
# )
# 
# # Exclude certain publishers
# indie_games <- st_filter_by_publisher(
#   publisher_names = c("Electronic Arts", "Activision", "Ubisoft"),
#   exclude = TRUE
# )

## ----collections--------------------------------------------------------------
# # Get genre filter collection
# genres <- st_get_filter_collection("top_genres")
# 
# # Use filters from collection
# puzzle_apps <- st_top_charts(
#   os = "unified",
#   category = 0,
#   custom_fields_filter_id = genres$puzzle,
#   custom_tags_mode = "include_unified_apps",
#   measure = "DAU",
#   regions = "US"
# )
# 
# # Get monetization model filters
# monetization <- st_get_filter_collection("monetization_models")
# 
# # Compare F2P with ads vs F2P with IAP
# f2p_ads_apps <- st_get_filtered_apps(
#   filter_id = monetization$free_with_ads,
#   measure = "DAU",
#   regions = "US"
# )
# 
# f2p_iap_apps <- st_get_filtered_apps(
#   filter_id = monetization$free_with_iap,
#   measure = "DAU",
#   regions = "US"
# )

## ----complex------------------------------------------------------------------
# # Create a complex filter manually
# complex_filter <- st_custom_fields_filter(
#   custom_fields = list(
#     list(
#       name = "Game Genre",
#       values = list("Puzzle"),
#       global = TRUE,
#       exclude = FALSE
#     ),
#     list(
#       name = "Free",
#       global = TRUE,
#       true = TRUE
#     ),
#     list(
#       name = "SDK: Unity",
#       global = TRUE,
#       true = TRUE
#     ),
#     list(
#       name = "Day 7 Retention (Last Quarter, US)",
#       values = list("30% - 100%"),  # High retention
#       global = TRUE,
#       exclude = FALSE
#     )
#   )
# )
# 
# # Use the complex filter
# high_retention_puzzle <- st_get_filtered_apps(
#   filter_id = complex_filter,
#   measure = "DAU",
#   regions = "US"
# )

## ----analysis-----------------------------------------------------------------
# # Get comprehensive analysis
# analysis <- st_analyze_filter(
#   filter_id = word_filter,
#   measure = "DAU",
#   regions = "US",
#   top_n = 10
# )
# 
# # Access analysis components
# print(analysis$filter_criteria)
# print(analysis$total_apps)
# print(analysis$top_apps)
# 
# # Custom analysis on filtered data
# word_games %>%
#   mutate(
#     dau = `aggregate_tags.Last 30 Days Average DAU (US)`,
#     retention_d7 = `aggregate_tags.Day 7 Retention (Last Quarter, US)`
#   ) %>%
#   filter(!is.na(dau)) %>%
#   summarise(
#     total_dau = sum(dau, na.rm = TRUE),
#     avg_retention = mean(retention_d7, na.rm = TRUE),
#     median_dau = median(dau, na.rm = TRUE)
#   )

## ----integration--------------------------------------------------------------
# # Use with st_top_charts
# top_word_games <- st_top_charts(
#   os = "unified",
#   category = 0,  # Required when using custom filter
#   custom_fields_filter_id = word_filter,
#   custom_tags_mode = "include_unified_apps",
#   measure = "DAU",
#   regions = "US",
#   date = "2025-07-01",
#   limit = 50
# )
# 
# # Use with st_app_tag
# matching_apps <- st_app_tag(
#   app_id_type = "unified",
#   custom_fields_filter_id = word_filter
# )
# 
# # Combine with metrics retrieval
# if (nrow(matching_apps$data) > 0) {
#   app_metrics <- st_metrics(
#     app_ids = matching_apps$data$unified_app_id[1:10],
#     metrics = c("dau", "revenue", "downloads"),
#     regions = "US"
#   )
# }

## ----caching------------------------------------------------------------------
# # Save commonly used filters
# my_filters <- list(
#   word_games = "603697f4241bc16eb8570d37",
#   puzzle_games = st_filter_by_genre(genres = "Puzzle"),
#   f2p_games = st_filter_by_monetization(free_only = TRUE),
#   unity_games = st_filter_by_sdk(sdk_names = "Unity")
# )
# 
# # Save to file for later use
# saveRDS(my_filters, "my_sensor_tower_filters.rds")
# 
# # Load in future sessions
# my_filters <- readRDS("my_sensor_tower_filters.rds")

## ----validation---------------------------------------------------------------
# # Check filter details
# filter_details <- st_custom_fields_filter_by_id(
#   id = "603697f4241bc16eb8570d37"
# )
# 
# print(filter_details$custom_fields)

## ----large-results------------------------------------------------------------
# # Use pagination for large result sets
# all_puzzle_games <- st_app_tag(
#   app_id_type = "unified",
#   custom_fields_filter_id = puzzle_filter
# )
# 
# # Process in batches if needed
# if (!is.null(all_puzzle_games$last_known_id)) {
#   # Get next page
#   next_page <- st_app_tag(
#     app_id_type = "unified",
#     custom_fields_filter_id = puzzle_filter,
#     last_known_id = all_puzzle_games$last_known_id
#   )
# }

## ----debug--------------------------------------------------------------------
# # Test filter creation
# tryCatch({
#   filter_id <- st_create_simple_filter(
#     field_name = "Invalid Field Name",
#     field_values = "test"
#   )
# }, error = function(e) {
#   message("Filter creation failed: ", e$message)
# })
# 
# # Verify field exists
# fields <- st_discover_fields("Invalid Field")
# if (nrow(fields) == 0) {
#   message("No matching fields found")
# }

## ----help, eval=FALSE---------------------------------------------------------
# ?st_custom_fields_filter
# ?st_get_filtered_apps
# ?st_filter_by_genre

