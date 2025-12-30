# Custom Filter Integration Plan for sensortowerR

## Overview
This document outlines how to integrate custom filter support (`custom_fields_filter_id` and `custom_tags_mode`) across multiple sensortowerR functions to maximize reusability.

## Functions That Should Support Custom Filters

### 1. Already Implemented
- ✅ `st_top_charts()` - Full support for custom filters

### 2. High Priority - Should Add Support
These functions query similar endpoints and would benefit from custom filter support:

#### `st_category_rankings()`
- **Current**: Fetches official app store rankings by category
- **Enhancement**: Add custom filter to get rankings within a filtered subset
- **Use Case**: "Show me iOS game rankings, but only for games from my custom filter"
- **Implementation**: Add `custom_fields_filter_id` and `custom_tags_mode` parameters

#### `st_sales_report()`
- **Current**: Gets revenue/download data for specific apps
- **Enhancement**: Filter which apps to include in the report
- **Use Case**: "Get sales data only for apps matching my publisher filter"
- **Implementation**: Add filter parameters to the endpoint call

#### `st_game_summary()`
- **Current**: Aggregated game market data by category
- **Enhancement**: Apply custom filters to market analysis
- **Use Case**: "Show market summary only for hypercasual games"
- **Implementation**: Pass filter to aggregation endpoint

### 3. Medium Priority - Could Benefit
#### `st_top_publishers()`
- **Current**: Top publishers by revenue/downloads
- **Enhancement**: Filter to specific publisher groups
- **Use Case**: "Top publishers in my competitive set"

#### `st_batch_metrics()`
- **Current**: Fetches metrics for multiple apps
- **Enhancement**: Pre-filter the app list
- **Use Case**: "Get metrics for all apps matching my filter"

### 4. Functions That Don't Need Custom Filters
These work with specific app IDs and wouldn't benefit from filters:
- ❌ `st_app_info()` - Searches for specific apps
- ❌ `st_app_details()` - Gets details for specific app IDs
- ❌ `st_app_lookup()` - Looks up specific app IDs
- ❌ `st_publisher_apps()` - Gets apps from specific publisher

## Implementation Strategy

### Step 1: Create Shared Parameter Handler
```r
# In utils.R or new file custom_filter_utils.R

#' Add custom filter parameters to query
#' @keywords internal
add_custom_filter_params <- function(query_params, 
                                   custom_fields_filter_id = NULL,
                                   custom_tags_mode = NULL,
                                   os = NULL) {
  
  if (!is.null(custom_fields_filter_id)) {
    # Validate filter ID
    if (!st_is_valid_filter_id(custom_fields_filter_id)) {
      stop("Invalid custom_fields_filter_id format")
    }
    
    query_params$custom_fields_filter_id <- custom_fields_filter_id
    
    # Add custom_tags_mode if unified OS
    if (!is.null(os) && os == "unified") {
      if (is.null(custom_tags_mode)) {
        stop("custom_tags_mode is required when using custom_fields_filter_id with unified OS")
      }
      query_params$custom_tags_mode <- custom_tags_mode
    }
  }
  
  query_params
}
```

### Step 2: Update Function Signatures
Add these parameters to relevant functions:
```r
#' @param custom_fields_filter_id Optional. Character string. ID of a Sensor
#'   Tower custom field filter to apply. Use filter IDs from the web interface.
#' @param custom_tags_mode Optional. Character string. Required if `os` is
#'   'unified' and `custom_fields_filter_id` is provided. Options: "include",
#'   "exclude", "include_unified_apps".
```

### Step 3: Example Implementation for st_category_rankings
```r
st_category_rankings <- function(os,
                               category = NULL,  # Make optional with filter
                               chart_type = NULL,
                               country = "US",
                               date = NULL,
                               limit = 100,
                               offset = 0,
                               custom_fields_filter_id = NULL,
                               custom_tags_mode = NULL,
                               auth_token = NULL) {
  
  # Validate: need either category or custom filter
  if (is.null(category) && is.null(custom_fields_filter_id)) {
    stop("Either 'category' or 'custom_fields_filter_id' must be provided")
  }
  
  # Build query parameters
  query_params <- list(
    auth_token = auth_token,
    category = category,
    chart_type = chart_type,
    country = country,
    limit = limit,
    offset = offset
  )
  
  # Add custom filter params
  query_params <- add_custom_filter_params(
    query_params,
    custom_fields_filter_id,
    custom_tags_mode,
    os
  )
  
  # Continue with API call...
}
```

## Usage Examples

### 1. Category Rankings with Custom Filter
```r
# Get rankings for games in my custom competitive set
rankings <- st_category_rankings(
  os = "ios",
  custom_fields_filter_id = "60746340241bc16eb8a65d76",
  chart_type = "topgrossingapplications",
  country = "US"
)
```

### 2. Sales Report with Custom Filter
```r
# Get revenue data for apps matching my filter
sales <- st_sales_report(
  os = "unified",
  custom_fields_filter_id = "60746340241bc16eb8a65d76",
  custom_tags_mode = "include_unified_apps",
  start_date = "2025-01-01",
  end_date = "2025-01-31"
)
```

### 3. Game Market Summary with Filter
```r
# Market analysis for specific game subset
market <- st_game_summary(
  os = "unified",
  custom_fields_filter_id = "hypercasual_filter_id",
  custom_tags_mode = "include",
  countries = c("US", "GB", "JP")
)
```

### 4. Combining URL Parsing with Custom Filters
```r
# Parse a web URL and use the filter elsewhere
url <- "https://app.sensortower.com/..."
params <- st_parse_web_url(url)

# Use the extracted filter in different functions
if (!is.null(params$custom_fields_filter_id)) {
  # Get rankings
  rankings <- st_category_rankings(
    os = params$os,
    custom_fields_filter_id = params$custom_fields_filter_id,
    custom_tags_mode = params$custom_tags_mode
  )
  
  # Get publisher analysis
  publishers <- st_top_publishers(
    os = params$os,
    custom_fields_filter_id = params$custom_fields_filter_id,
    custom_tags_mode = params$custom_tags_mode
  )
}
```

## Benefits of This Approach

1. **Consistency**: Same parameter names and behavior across all functions
2. **Reusability**: Create one filter, use it everywhere
3. **Flexibility**: Mix and match filters with other parameters
4. **Web Integration**: Seamlessly use filters from web interface
5. **Validation**: Centralized validation logic

## Testing Strategy

### 1. Unit Tests
```r
test_that("Custom filter parameters work across functions", {
  filter_id <- "60746340241bc16eb8a65d76"
  
  # Test with each function
  expect_error(
    st_category_rankings(os = "unified", custom_fields_filter_id = filter_id),
    "custom_tags_mode is required"
  )
  
  expect_s3_class(
    st_category_rankings(
      os = "ios",
      custom_fields_filter_id = filter_id
    ),
    "data.frame"
  )
})
```

### 2. Integration Tests
- Test filter ID validation
- Test parameter combinations
- Test error messages
- Test with real filter IDs

## Documentation Updates

### README Section
```markdown
## Using Custom Filters Across Functions

Custom filters created in the Sensor Tower web interface can be used across multiple functions:

| Function | Custom Filter Support | Use Case |
|----------|---------------------|----------|
| `st_top_charts()` | ✅ Full support | Filter top apps by custom criteria |
| `st_category_rankings()` | ✅ Full support | Rankings within filtered apps |
| `st_sales_report()` | ✅ Full support | Revenue for filtered apps |
| `st_game_summary()` | ✅ Full support | Market analysis with filters |
| `st_top_publishers()` | ✅ Full support | Publishers of filtered apps |
| `st_batch_metrics()` | ✅ Full support | Metrics for filtered app sets |
```

## Implementation Timeline

1. **Phase 1** (Immediate): Update `st_category_rankings()`
2. **Phase 2** (Next): Update `st_sales_report()` and `st_game_summary()`
3. **Phase 3** (Future): Update `st_top_publishers()` and `st_batch_metrics()`
4. **Phase 4** (Ongoing): Add examples and vignettes

## Conclusion

By systematically adding custom filter support across relevant functions, we can make the sensortowerR package much more powerful for users who leverage Sensor Tower's web interface filters. This creates a seamless workflow between web and R environments.