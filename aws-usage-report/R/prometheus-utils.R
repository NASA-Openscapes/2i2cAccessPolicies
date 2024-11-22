get_default_prometheus_uid <- function(grafana_url = "https://grafana.openscapes.2i2c.cloud",
                                       grafana_token = Sys.getenv("GRAFANA_TOKEN")) {
  api_url <- glue::glue("{grafana_url}/")

  res <- httr2::request(grafana_url) |>
    httr2::req_url_path("/api/datasources/") |>
    httr2::req_auth_bearer_token(grafana_token) |>
    httr2::req_perform()

  body <- httr2::resp_body_json(res)

  Filter(\(x) x$name == "prometheus", body)[[1]][["uid"]] # should also check if isDefault, but there is only one and it is isDefault = FALSE
}

#  get_homedir_dashboard <- function(
#     grafana_url = "https://grafana.openscapes.2i2c.cloud",
#     grafana_token = Sys.getenv("GRAFANA_TOKEN")
#   ) {
#     ret <- httr2::request(grafana_url) |>
#       httr2::req_url_path("/api/dashboards/uid", "bd232539-52d0-4435-8a62-fe637dc822be") |>
#       httr2::req_auth_bearer_token(grafana_token) |>
#       httr2::req_perform() |>
#       httr2::resp_check_status() |>
#       httr2::resp_body_json()

#     ret
#   }

#' Get a vector of labels available from Prometheus
#'
#' @inheritParams query_prometheus_range
#'
#' @return vector of labels
#' @export
get_prometheus_labels <- function(
    grafana_url = "https://grafana.openscapes.2i2c.cloud",
    grafana_token = Sys.getenv("GRAFANA_TOKEN"),
    prometheus_uid = get_default_prometheus_uid(grafana_url, grafana_token)) {
  httr2::request(grafana_url) |>
    httr2::req_url_path("/api/datasources/proxy/uid", prometheus_uid, "api/v1/labels") |>
    httr2::req_auth_bearer_token(grafana_token) |>
    httr2::req_perform() |>
    httr2::resp_check_status() |>
    httr2::resp_body_json(simplifyVector = TRUE, simplifyDataFrame = TRUE)
}

#' Get a data.frame of metrics available from Prometheus
#'
#' @inheritParams query_prometheus_range
#'
#' @return data.frame of metrics
#' @export
get_prometheus_metrics <- function(
    grafana_url = "https://grafana.openscapes.2i2c.cloud",
    grafana_token = Sys.getenv("GRAFANA_TOKEN"),
    prometheus_uid = get_default_prometheus_uid(grafana_url, grafana_token)) {
  ret <- httr2::request(grafana_url) |>
    httr2::req_url_path("/api/datasources/proxy/uid", prometheus_uid, "api/v1/targets/metadata") |>
    httr2::req_auth_bearer_token(grafana_token) |>
    httr2::req_perform() |>
    httr2::resp_check_status() |>
    httr2::resp_body_json(simplifyVector = TRUE, simplifyDataFrame = TRUE)

  data.frame(
    metric = ret$data$metric,
    type = ret$data$type,
    help = ret$data$help,
    unit = ret$data$unit
  )
}

#' Query Prometheus for an instant in time
#'
#' @inheritParams query_prometheus_range
#'
#' @return List containing the response from Prometheus, in the
#'    [instant vector format](https://prometheus.io/docs/prometheus/latest/querying/api/#instant-vectors)
#'
#' @export
#'
#' @examples
#' current_size <- query_prometheus_instant(
#'   query = "max(dirsize_total_size_bytes) by (directory, namespace)"
#' )
query_prometheus_instant <- function(
    grafana_url = "https://grafana.openscapes.2i2c.cloud",
    grafana_token = Sys.getenv("GRAFANA_TOKEN"),
    prometheus_uid = get_default_prometheus_uid(grafana_url, grafana_token),
    query) {
  httr2::request(grafana_url) |>
    httr2::req_url_path("/api/datasources/proxy/uid", prometheus_uid, "api/v1/query") |>
    httr2::req_options(http_version = 2) |>
    httr2::req_auth_bearer_token(grafana_token) |>
    httr2::req_url_query(
      query = query
    ) |>
    httr2::req_perform() |>
    httr2::resp_check_status() |>
    httr2::resp_body_json(simplifyVector = TRUE)
}

#' Query prometheus for a range of dates
#'
#' Adapted from https://hackmd.io/NllqOUfaTLCXcDQPipr4rg
#'
#' @param grafana_url URL of the Grafana instance. Default
#'    `""https://grafana.openscapes.2i2c.cloud""`
#' @param grafana_token Authentication token for Grafana. By default reads from
#'    the environment variable `GRAFANA_TOKEN`
#' @param prometheus_uid the uid of the prometheus datasource. By default, it
#'    is discovered from the `grafana_url` using
#'    the internal function `get_default_prometheus_uid()`
#' @param query Query in "PromQL" ([Prometheus Query Language](https://prometheus.io/docs/prometheus/latest/querying/basics/))
#' @param start_time Start of time range to query. Date or date-time object, or
#'    character of the form "YYYY-MM-DD HH:MM:SS". Time  components are optional.
#' @param end_time End of time range to query. Date or date-time object, or
#'    character of the form "YYYY-MM-DD HH:MM:SS". Time  components are optional.
#' @param step Time step in seconds
#'
#' @return List containing the response from Prometheus, in the
#'    [range vector format](https://prometheus.io/docs/prometheus/latest/querying/api/#range-vectors)
#' @export
#'
#' @examples
#' \dontrun{
#' query_prometheus_range(
#'   query = "max(dirsize_total_size_bytes) by (directory, namespace)",
#'   start_time = "2024-01-01",
#'   end_time = "2024-05-28",
#'   step = 60 * 60 * 24
#' )
#' }
query_prometheus_range <- function(
    grafana_url = "https://grafana.openscapes.2i2c.cloud",
    grafana_token = Sys.getenv("GRAFANA_TOKEN"),
    prometheus_uid = get_default_prometheus_uid(grafana_url, grafana_token),
    query,
    start_time,
    end_time,
    step) {
  req <- httr2::request(grafana_url) |>
    # Force HTTP version 2, I think there was a mismatch when not set and was
    # getting the error:
    #   Failed to perform HTTP request.
    #   Caused by error in `curl::curl_fetch_memory()`:
    #   ! Failed writing received data to disk/application.
    # Use `curl --i https://grafana.openscapes.2i2c.cloud/api/` on
    # command line to get supported HTTP version of server (it shows HTTP/2)
    # See curl::curl_symbols("http_version") for http version values
    httr2::req_options(http_version = 2) |>
    httr2::req_url_path("/api/datasources/proxy/uid", prometheus_uid, "api/v1/query_range") |>
    httr2::req_auth_bearer_token(grafana_token) |>
    httr2::req_url_query(
      query = query,
      start = format(as.POSIXct(start_time), "%Y-%m-%dT%H:%M:%SZ"),
      end = format(as.POSIXct(end_time), "%Y-%m-%dT%H:%M:%SZ"),
      step = step
    ) |>
    httr2::req_perform() |>
    httr2::resp_check_status() |>
    httr2::resp_body_json(simplifyVector = TRUE, simplifyDataFrame = TRUE)
}

#' Create a data frame from a prometheus range query
#'
#' @param res the result of running `query_prometheus_range()`
#' @param value_name the name of the value column
#'
#' @return a data.frame
#' @export
#'
#' @examples
#' range_res <- query_prometheus_range(
#'   query = "max(dirsize_total_size_bytes) by (directory, namespace)",
#'   start_time = "2024-01-01",
#'   end_time = "2024-05-28",
#'   step = 60 * 60 * 24
#' )
#'
#' create_range_df(range_res, "size (bytes)")
create_range_df <- function(res, value_name) {
  metrics <- as.data.frame(res$data$result$metric)
  vals <- res$data$result$values

  lapply(seq_along(vals), \(x) {
    vals <- as.data.frame(vals[[x]])
    cbind(metrics[x, , drop = FALSE], vals, row.names = NULL)
  }) |>
    purrr::list_rbind() |>
    rename(
      date = V1,
      "{value_name}" := V2
    ) |>
    mutate(
      date = as.POSIXct(as.numeric(date), origin = "1970-01-01", tz = "UTC"),
      "{value_name}" := as.numeric(.data[[value_name]]) * 9.3132257461548e-10
    )
}

unsanitize_dir_names <- function(x) {
  x <- gsub("-2d", "-", x)
  x <- gsub("-2e", ".", x)
  x <- gsub("-40", "@", x)
  x <- gsub("-5f", "_", x)
  x
}
