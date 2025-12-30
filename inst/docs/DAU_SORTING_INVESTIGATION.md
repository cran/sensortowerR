# DAU Sorting Investigation - August 2025

## Problem Statement
When using custom filters from Sensor Tower web interface URLs with DAU sorting, the API was returning apps in incorrect order. NYT Games (5.6M DAU) was appearing at position #26 instead of #1.

## Web Interface Behavior
- URL shows: `/v1/{os}/sales_report_estimates_comparison_attributes` endpoint
- Parameters include: `measure=DAU` in the web URL
- Custom filter ID: `uai=5a39e9681454d22f5a5e75ca` (Word Puzzle filter)
- Results are correctly sorted by DAU in web interface

## Original Implementation (Pre v0.8.1)
The package routed based on measure type:
- `measure = "revenue"` or `"units"` → `sales_report_estimates_comparison_attributes` endpoint
- `measure = "DAU"`, `"WAU"`, `"MAU"` → `top_and_trending/active_users` endpoint

### Issue with active_users endpoint
- Returns `entities.users_absolute` (point-in-time DAU, e.g., 4.3M for NYT)
- Different from `dau_30d_us` (30-day average DAU, e.g., 5.6M for NYT)
- Sorting by `entities.users_absolute` gives wrong order
- The endpoint doesn't seem to respect the measure parameter for sorting

## Current Solution (v0.8.1)
Force all measures to use the `sales_report_estimates_comparison_attributes` endpoint:
```r
# In st_top_charts.R
is_active_users <- FALSE  # Don't use active_users endpoint
is_sales <- TRUE  # Always use sales_report_estimates_comparison_attributes
```

### Workaround Required
- The sales endpoint only accepts `measure = "revenue"` or `"units"` (not "DAU")
- Must use `measure = "revenue"` even when wanting DAU data
- The custom filter handles returning DAU metrics despite revenue measure
- Results are then manually sorted by `dau_30d_us`

## Potential Issues with Current Solution

### Why This Might Be Wrong
1. **API Design Intent**: The existence of separate endpoints suggests they serve different purposes
2. **Parameter Mismatch**: Using `measure = "revenue"` to get DAU data feels like a hack
3. **Future Breaking**: If Sensor Tower fixes their API, this workaround might break

### Alternative Hypothesis
The `active_users` endpoint might be correct but:
1. We're missing a sort parameter (tried `sort_by` but didn't work)
2. The endpoint expects different parameters we haven't discovered
3. The web interface might be doing client-side sorting
4. There might be a third endpoint we haven't found

## Evidence Supporting Current Solution
1. Web interface shows `/sales_report_estimates_comparison_attributes` in network tab
2. Using this endpoint returns correct data (just needs sorting)
3. Results match web interface when sorted by `dau_30d_us`

## Evidence Against Current Solution
1. API returns 422 error when using `measure = "DAU"` with sales endpoint
2. Separate endpoints exist for a reason
3. We're working around the API rather than using it correctly

## How to Test if We Need to Revert

### If Sensor Tower Updates Their API
1. Try using `measure = "DAU"` with sales endpoint - if it starts working, they fixed it
2. Check if active_users endpoint starts returning correctly sorted data
3. Look for new parameters in their API documentation

### Test Commands
```r
# Test if sales endpoint accepts DAU directly (currently fails with 422)
test1 <- tryCatch(
  st_top_charts(
    os = "unified",
    measure = "DAU",  # Currently causes 422 error
    custom_fields_filter_id = "5a39e9681454d22f5a5e75ca",
    category = 7019,
    regions = "US"
  ),
  error = function(e) e
)

# Test if active_users endpoint sorts correctly (currently wrong order)
# Would need to temporarily revert the package changes to test
```

## Recommendation
Keep current solution but monitor for:
1. API documentation updates
2. Changes in web interface behavior  
3. User reports of issues

If Sensor Tower fixes their API to accept `measure = "DAU"` on the sales endpoint, we should update to use that directly rather than the current workaround.

## Related Files
- `/Users/phillip/Documents/vibe_coding_projects/sensortowerR/R/st_top_charts.R` - Main function
- `/Users/phillip/Documents/vibe_coding_projects/sensortowerR/R/utils.R` - Parameter preparation
- `/Users/phillip/Documents/vibe_coding_projects/blog_post_source/2025_08_20_puzzle/puzzle_kpi_table.R` - Working example