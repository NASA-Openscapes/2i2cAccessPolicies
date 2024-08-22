ce_to_df <- function(ce_result, metric = "UnblendedCost") {
  dimension_names <- tolower(
    vapply(ce_result$GroupDefinitions, `[[`, "Key", FUN.VALUE = character(1))
  )

  if (length(dimension_names) > 0) {
    res_by_time <- Filter(\(y) length(y$Groups) > 0, ce_result$ResultsByTime)
  } else {
    res_by_time <- ce_result$ResultsByTime
  }

  df_list <- lapply(
    res_by_time,
    results_by_time_to_df,
    keynames = dimension_names,
    metric = metric
  )

  purrr::list_rbind(df_list)
}

results_by_time_to_df <- function(x, keynames, metric) {
  start_date <- as.Date(x$TimePeriod$Start)
  end_date <- as.Date(x$TimePeriod$End)

  if (length(keynames) > 0) {
    # Grouped Query
    keys <- purrr::list_rbind(
      lapply(x$Groups, \(x) {
        as.data.frame(
          t(x[["Keys"]])
        )
      })
    )

    names(keys) <- keynames

    metric_val <- vapply(
      x$Groups, \(x) {
        as.numeric(x$Metrics[[metric]]$Amount)
      },
      FUN.VALUE = numeric(1)
    )
  } else {
    # No groups
    metric_val <- as.numeric(x$Total[[metric]]$Amount)
    keys <- NULL
  }

  estimated <- x$Estimated

  dplyr::bind_cols(
    start_date = start_date,
    end_date = end_date,
    keys,
    {{ metric }} := metric_val,
    estimated = estimated
  )
}

# Aggregate services to maximum ten categories to simplify
# visualization and align with AWS CE colour palette
ce_categories <- function(df, n_categories = 10) {
  if (length(unique(df$service)) > n_categories) {
    top_services <- df |>
      group_by(service) |>
      summarise(total_cost = sum(UnblendedCost)) |>
      slice_max(total_cost, n = n_categories - 1) |>
      pull(service)

    df$service[!df$service %in% top_services] <- "Other"
  }

  df |>
    group_by(start_date, end_date, service) |>
    summarise(
      UnblendedCost = sum(UnblendedCost, na.rm = TRUE),
      .groups = "drop"
    )
}

aws_ce_palette <- c(
  "#9a7b09",
  "#6135a6",
  "#0b7164",
  "#952248",
  "#0166ab",
  "#e07a41",
  "#8356cd",
  "#2ea597",
  "#c33d69",
  "#6889e9"
)
