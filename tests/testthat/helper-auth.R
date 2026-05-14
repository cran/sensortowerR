# Test helper functions

skip_if_no_auth <- function() {
  if (!identical(tolower(Sys.getenv("SENSORTOWER_RUN_LIVE")), "true")) {
    skip("Set SENSORTOWER_RUN_LIVE=true to run live Sensor Tower API tests")
  }
  auth_token <- Sys.getenv("SENSORTOWER_AUTH_TOKEN")
  if (auth_token == "") {
    skip("Sensor Tower authentication token not found")
  }
}
