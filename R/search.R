#' Search DataJud and return a tibble of results
#'
#' High-level search function that handles sorting, prints a download estimate,
#' and parses results into a flat tibble.
#'
#' @param cfg List. Configuration object from [datajud_config()].
#' @param body List. Elasticsearch query body from [build_query()].
#' @param page_size Integer. Results per page. Default `100`.
#' @param max_pages Numeric. Maximum pages to fetch. Default `Inf`.
#' @param verbose Logical. Print page progress messages.
#' @param estimate Logical. Whether to make an extra COUNT request before
#'   fetching to print a download estimate. Only used when `verbose = TRUE`.
#'   Default `TRUE`.
#'
#' @return A tibble with one row per process.
#' @export
datajud_search <- function(cfg,
                           body,
                           page_size = 100,
                           max_pages = Inf,
                           verbose   = TRUE,
                           estimate  = TRUE) {

  if (is.null(body$query)) {
    stop("body precisa conter 'query'. Use build_query().")
  }

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

  results <- datajud_search_after(
    cfg       = cfg,
    body      = body,
    page_size = page_size,
    max_pages = max_pages,
    verbose   = verbose
  )

  extract_source(results)

}

#' Count total results for a DataJud query
#'
#' @param cfg List. Configuration object from [datajud_config()].
#' @param body List. Elasticsearch query body from [build_query()].
#'
#' @return Integer. Total number of matching documents.
#' @export
datajud_count <- function(cfg, body) {

  body$size             <- 0
  body$track_total_hits <- TRUE

  res <- datajud_request(cfg, body)

  res$hits$total$value

}

#' Estimate download time for a DataJud query
#'
#' @param cfg List. Configuration object from [datajud_config()].
#' @param body List. Elasticsearch query body from [build_query()].
#' @param page_size Integer. Results per page. Default `100`.
#'
#' @return An object of class `datajud_estimate`.
#' @export
datajud_estimate_download <- function(cfg,
                                      body,
                                      page_size  = 100) {

  total <- datajud_count(cfg, body)
  pages <- ceiling(total / page_size)

  result <- list(
    total_results = total,
    page_size     = page_size,
    total_pages   = pages
  )

  class(result) <- "datajud_estimate"

  result

}

#' Print method for datajud_estimate
#'
#' @param x A `datajud_estimate` object.
#' @param ... Ignored.
#' @export
print.datajud_estimate <- function(x, ...) {

  cat("Estimativa de download DataJud\n")
  cat("-------------------------------\n")
  cat("Resultados totais: ", format(x$total_results, big.mark = ","), "\n")
  cat("Page size:         ", x$page_size, "\n")
  cat("Total de paginas:  ", format(x$total_pages, big.mark = ","), "\n")

}
