# Custom Filters Guide for SensorTowerR

## Overview

Custom filters created in the Sensor Tower web interface can now be used directly in SensorTowerR. This allows you to leverage complex filtering logic from the web UI in your R analyses.

## What are Custom Filters?

Custom filters are saved search criteria created in the Sensor Tower web interface at app.sensortower.com. They allow you to define complex app selection criteria based on:
- Publisher attributes
- App categories and subcategories
- Revenue/download thresholds
- User demographics
- Custom tags and fields
- And many other criteria

## Supported Functions

Based on API testing, custom filters are supported by these functions:

| Function | Custom Filter Support | Use Case |
|----------|---------------------|----------|
| `st_top_charts()` | ✅ **Full support** | Get detailed metrics for apps matching your filter |
| `st_category_rankings()` | ✅ **Full support** | Get store rankings for filtered apps |
| `st_sales_report()` | ✅ **Full support** | Get revenue/download data for filtered apps |
| `st_batch_metrics()` | ❌ Not supported | Use app IDs instead |
| `st_game_summary()` | ❌ Not supported | Use category parameter |
| `st_top_publishers()` | ❌ Not supported | Use other filtering options |

## How to Use Custom Filters

### Step 1: Get Your Filter ID

1. Go to app.sensortower.com
2. Create or select a custom filter
3. Look at the URL - it will contain `custom_fields_filter_id=XXXXXXXXXXXXXXXXXXXXXXXX`
4. Copy the 24-character hexadecimal ID

### Step 2: Use in R

```r
library(SensorTowerR)

# Your filter ID from the web interface
my_filter_id <- "60746340241bc16eb8a65d76"

# Example 1: Get top charts data
top_apps <- st_top_charts(
  os = "ios",
  custom_fields_filter_id = my_filter_id,
  regions = "US",
  limit = 100
)

# Example 2: Get category rankings
rankings <- st_category_rankings(
  os = "ios",
  custom_fields_filter_id = my_filter_id,  # No category needed!
  chart_type = "topgrossingapplications",
  country = "US"
)

# Example 3: Get sales data
sales <- st_sales_report(
  os = "ios",
  custom_fields_filter_id = my_filter_id,  # No app_ids needed!
  countries = c("US", "GB", "JP"),
  start_date = "2024-01-01",
  end_date = "2024-01-31",
  date_granularity = "monthly"
)
```

## Unified OS Support

When using `os = "unified"`, you must specify `custom_tags_mode`:

```r
# Unified OS requires custom_tags_mode
unified_data <- st_top_charts(
  os = "unified",
  custom_fields_filter_id = my_filter_id,
  custom_tags_mode = "include_unified_apps",  # Required!
  regions = c("US", "GB")
)
```

### Custom Tags Mode Options:
- `"include"` - Include apps that match the filter
- `"exclude"` - Exclude apps that match the filter  
- `"include_unified_apps"` - Include all platform versions when any version matches

## URL Integration

You can extract filter IDs from Sensor Tower web URLs:

```r
# Parse a URL from the web interface
web_url <- "https://app.sensortower.com/market-analysis/top-apps?custom_fields_filter_id=60746340241bc16eb8a65d76&custom_fields_filter_mode=include_unified_apps"

# Extract parameters
params <- st_parse_web_url(web_url)

# Use the extracted filter
data <- st_top_charts(
  os = params$os,
  custom_fields_filter_id = params$custom_fields_filter_id,
  custom_tags_mode = params$custom_tags_mode,
  regions = params$regions
)
```

## Important Notes

1. **Filter IDs are account-specific** - A filter created in one account cannot be used with another account's API token

2. **Empty results are normal** - If a filter returns no results, it could mean:
   - The filter ID is not valid for your account
   - No apps match the filter criteria
   - The filter has date/time restrictions

3. **Performance** - Custom filters may be slower than direct app ID queries, especially for complex filters

4. **Validation** - Filter IDs must be exactly 24 hexadecimal characters (0-9, a-f)

## Troubleshooting

### "Invalid custom_fields_filter_id format"
- Ensure the ID is exactly 24 characters
- Only hexadecimal characters (0-9, a-f) are allowed
- Check for extra spaces or characters

### "custom_tags_mode is required"
- This error occurs with `os = "unified"`
- Add `custom_tags_mode = "include_unified_apps"` to your call

### Empty results
- Verify the filter ID is from your account
- Check if the filter has any matching apps in the web interface
- Try a different date range or region

## Examples

### Complete Workflow Example

```r
# 1. Create a filter in the web interface for "Top Grossing Puzzle Games"
# 2. Get the filter ID from the URL
filter_id <- "your_filter_id_here"

# 3. Get current rankings
rankings <- st_category_rankings(
  os = "ios",
  custom_fields_filter_id = filter_id,
  chart_type = "topgrossingapplications",
  country = "US"
)

# 4. Get detailed metrics for these apps
metrics <- st_top_charts(
  os = "ios", 
  custom_fields_filter_id = filter_id,
  regions = "US"
)

# 5. Get historical revenue data
revenue <- st_sales_report(
  os = "ios",
  custom_fields_filter_id = filter_id,
  countries = "US",
  start_date = "2024-01-01",
  end_date = "2024-12-31",
  date_granularity = "monthly"
)

# 6. Combine for analysis
library(dplyr)
analysis <- rankings %>%
  left_join(metrics, by = c("app_id" = "unified_app_id")) %>%
  left_join(revenue, by = "app_id")
```

### Comparing Filtered vs Unfiltered Results

```r
# Get all games
all_games <- st_category_rankings(
  os = "ios",
  category = 6014,  # Games
  chart_type = "topgrossingapplications",
  limit = 200
)

# Get only your filtered games
filtered_games <- st_category_rankings(
  os = "ios",
  custom_fields_filter_id = filter_id,
  chart_type = "topgrossingapplications",
  limit = 200
)

# Compare
cat("Total games:", nrow(all_games), "\n")
cat("Filtered games:", nrow(filtered_games), "\n")
cat("Filter selected", 
    round(nrow(filtered_games) / nrow(all_games) * 100, 1), 
    "% of games\n")
```

## Best Practices

1. **Cache filter results** - Filter queries can be slow, so cache results when possible
2. **Use specific date ranges** - Narrow date ranges return faster
3. **Limit results appropriately** - Use the `limit` parameter to get only what you need
4. **Test filters first** - Verify a filter returns data in the web interface before using in R
5. **Document filter logic** - Keep notes on what each filter ID represents

## Future Enhancements

While `st_batch_metrics()`, `st_game_summary()`, and `st_top_publishers()` don't currently support custom filters due to API limitations, you can work around this by:

1. Using custom filters with supported functions to get app IDs
2. Passing those app IDs to the unsupported functions

```r
# Workaround example
# 1. Get app IDs from custom filter
filtered_apps <- st_top_charts(
  os = "ios",
  custom_fields_filter_id = filter_id,
  regions = "US",
  limit = 50
)

# 2. Use those IDs with batch metrics
app_ids <- unique(filtered_apps$entities.app_ids.ios)
metrics <- st_batch_metrics(
  os = "ios",
  app_list = app_ids,
  metrics = c("dau", "mau", "revenue"),
  date_range = "ytd",
  countries = "US"
)
```
