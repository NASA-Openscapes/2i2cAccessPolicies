ce_to_df <- function(ce_result) {
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
    keynames = dimension_names
  )

  purrr::list_rbind(df_list)
}

results_by_time_to_df <- function(x, keynames) {
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

    amount_usd <- vapply(
      x$Groups, \(x) {
        as.numeric(x$Metrics$UnblendedCost$Amount)
      },
      FUN.VALUE = numeric(1)
    )
  } else {
    # No groups
    amount_usd <- as.numeric(x$Total$UnblendedCost$Amount)
    keys <- NULL
  }

  estimated <- x$Estimated

  dplyr::bind_cols(
    start_date = start_date,
    end_date = end_date,
    keys,
    amount_usd = amount_usd,
    estimated = estimated
  )
}
