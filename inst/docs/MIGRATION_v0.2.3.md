# Migration Guide for sensortowerR v0.2.3

## Overview

sensortowerR v0.2.3 introduces automatic revenue standardization across all functions. This guide helps you migrate existing code to use the new standardized revenue columns.

## What Changed?

Previously, different sensortowerR functions returned revenue in different units:
- `st_top_charts()`: cents (revenue_absolute)
- `st_sales_report()`: dollars (total_revenue)
- `st_top_publishers()`: cents (revenue_absolute)

Now, all functions provide standardized revenue columns in base currency units (dollars for USD, euros for EUR, etc.).

## Quick Migration Reference

### st_top_charts()

**Before v0.2.3:**
```r
top_games <- st_top_charts(...)
top_games %>%
  mutate(revenue_dollars = revenue_absolute / 100)
```

**After v0.2.3:**
```r
top_games <- st_top_charts(...)
# Use the 'revenue' column directly - it's already in dollars
top_games %>%
  select(app_name, revenue)
```

### st_sales_report()

**No changes needed** - This function already returned values in base currency units.

### st_top_publishers()

**Before v0.2.3:**
```r
publishers <- st_top_publishers(...)
publishers %>%
  mutate(revenue_dollars = revenue_absolute / 100)
```

**After v0.2.3:**
```r
publishers <- st_top_publishers(...)
# Use 'revenue_usd' column directly
publishers %>%
  select(publisher_name, revenue_usd)
```

## Backward Compatibility Pattern

If your code needs to work with both old and new versions:

```r
# For st_top_charts()
process_revenue <- function(data) {
  if ("revenue" %in% names(data)) {
    # v0.2.3+ - use standardized column
    data$revenue_millions <- data$revenue / 1e6
  } else {
    # Pre-v0.2.3 - manual conversion
    data$revenue_millions <- data$revenue_absolute / 100 / 1e6
  }
  return(data)
}

top_games <- st_top_charts(...) %>%
  process_revenue()
```

## Common Migration Scenarios

### Scenario 1: Revenue in Millions

**Old code:**
```r
mutate(revenue_millions = revenue_absolute / 1e8)  # cents to millions
```

**New code:**
```r
mutate(revenue_millions = revenue / 1e6)  # dollars to millions
```

### Scenario 2: Revenue Formatting

**Old code:**
```r
mutate(revenue_fmt = scales::dollar(revenue_absolute / 100))
```

**New code:**
```r
mutate(revenue_fmt = scales::dollar(revenue))
```

### Scenario 3: Gini Coefficient Calculations

**Old code:**
```r
gini_coef <- calculate_gini(data$revenue_absolute / 100)
```

**New code:**
```r
gini_coef <- calculate_gini(data$revenue)
```

## Checking Your Version

```r
# Check if you have v0.2.3+
if (packageVersion("sensortowerR") >= "0.2.3") {
  message("You have the standardized revenue version!")
} else {
  message("Please update: devtools::install_github('econosopher/sensortowerR')")
}
```

## Benefits of Upgrading

1. **Consistency**: Same units across all functions
2. **Simplicity**: No manual conversions needed
3. **Clarity**: Clear column names indicate units
4. **Compatibility**: Original columns preserved for backward compatibility

## Need Help?

- Check the revenue units guide: `inst/docs/revenue_units_guide.md`
- See examples: `inst/examples/revenue_standardization_example.R`
- Report issues: https://github.com/econosopher/sensortowerR/issues