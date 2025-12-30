# Revenue Units Guide for sensortowerR

## Overview

The Sensor Tower API returns revenue values in different units depending on the endpoint. To ensure consistency and prevent confusion, sensortowerR v0.2.3+ automatically standardizes revenue units across all functions.

## Quick Reference

| Function | Original API Unit | sensortowerR Standard Column | Unit |
|----------|------------------|------------------------------|------|
| `st_top_charts()` | cents | `revenue` | base currency |
| `st_sales_report()` | base currency | `total_revenue` | base currency |
| `st_top_publishers()` | cents | `revenue_usd` | base currency |

## Detailed Behavior

### st_top_charts()
- **API returns**: `revenue_absolute` in cents
- **sensortowerR provides**: 
  - `revenue` - standardized to base currency units
  - `revenue_absolute` - preserved original cents value
  
### st_sales_report()
- **API returns**: revenue values in cents
- **sensortowerR provides**: 
  - `total_revenue`, `iphone_revenue`, `ipad_revenue` - all in base currency
  - `*_cents` columns preserved for reference

### st_top_publishers()
- **API returns**: `revenue_absolute` in cents
- **sensortowerR provides**: 
  - `revenue_usd` - converted to base currency
  - `revenue_absolute` - preserved original cents value

## Best Practices

1. **Always use the standardized columns** for analysis:
   - `revenue` from `st_top_charts()`
   - `total_revenue` from `st_sales_report()`
   - `revenue_usd` from `st_top_publishers()`

2. **Check column attributes** if unsure:
   ```r
   data <- st_top_charts(...)
   attr(data$revenue, "unit")  # Returns "base_currency"
   ```

3. **For backward compatibility**, original columns are preserved with their original units.

## Migration Guide

If you have existing code that manually converts cents to dollars:

```r
# Old approach (no longer needed)
top_charts %>%
  mutate(revenue_dollars = revenue_absolute / 100)

# New approach (use standardized column)
top_charts %>%
  select(app_name, revenue)  # revenue is already in base currency
```

## Note on Currency Types

"Base currency" refers to the standard monetary unit (dollars for USD, euros for EUR, etc.) as opposed to cents/pence/centimes. The actual currency type depends on your Sensor Tower account settings and the regions you're querying.