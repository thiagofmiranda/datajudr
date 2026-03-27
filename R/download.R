#' Download DataJud results to Parquet files in batches
#'
#' Paginates through all results and saves them as Parquet files, one file per
#' batch of pages. Useful for large downloads that exceed memory limits.
#'
#' @param cfg List. Configuration object from [datajud_config()].
#' @param body List. Elasticsearch query body from [build_query()].
#' @param output_dir Character. Directory to save Parquet files.
#' @param page_size Integer. Results per page. Default `100`.
#' @param batch_pages Integer. Pages per Parquet file. Default `50`.
#' @param verbose Logical. Print progress messages.
#' @param estimate Logical. Whether to make an extra COUNT request before
#'   downloading to print a download estimate. Only used when `verbose = TRUE`.
#'   Default `TRUE`.
#'
#' @return Invisibly returns `output_dir`.
#' @export
download_processos <- function(cfg,
                               body,
                               output_dir,
                               page_size   = 100,
                               batch_pages = 50,
                               verbose     = TRUE,
                               estimate    = TRUE) {

  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

  if (is.null(body$sort)) {
    body$sort <- default_sort()
  }

  if (verbose && estimate) {
    est <- datajud_estimate_download(
      cfg       = cfg,
      body      = body,
      page_size = page_size
    )
    print(est)
  }

  body$size    <- page_size
  search_after <- NULL
  page         <- 1
  batch        <- list()
  file_index   <- 1

  repeat {

    if (!is.null(search_after)) {
      body$search_after <- search_after
    }

    if (verbose) message("Pagina: ", page)

    res  <- datajud_request(cfg, body)
    hits <- res$hits$hits

    if (length(hits) == 0) break

    batch[[length(batch) + 1]] <- hits

    last_hit <- hits[[length(hits)]]

    if (is.null(last_hit$sort)) {
      stop("Campo 'sort' nao retornado pela API.")
    }

    search_after <- last_hit$sort

    if (page %% batch_pages == 0) {

      df        <- extract_source(batch)
      df        <- serialize_list_columns(df)
      file_path <- file.path(output_dir, paste0("processos_", file_index, ".parquet"))

      arrow::write_parquet(df, file_path)

      if (verbose) message("Arquivo salvo: ", file_path)

      batch      <- list()
      file_index <- file_index + 1

    }

    page <- page + 1

  }

  if (length(batch) > 0) {

    df        <- extract_source(batch)
    df        <- serialize_list_columns(df)
    file_path <- file.path(output_dir, paste0("processos_", file_index, ".parquet"))

    arrow::write_parquet(df, file_path)

    if (verbose) message("Arquivo salvo: ", file_path)

  }

  invisible(output_dir)

}

#' @keywords internal
serialize_list_columns <- function(df) {

  list_cols <- names(df)[sapply(df, is.list)]

  if (length(list_cols) == 0) return(df)

  df[list_cols] <- lapply(df[list_cols], function(col) {
    vapply(col, jsonlite::toJSON, character(1), auto_unbox = TRUE, null = "null")
  })

  df

}
