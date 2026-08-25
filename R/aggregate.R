#' Run an aggregation query against DataJud and return tidy results
#'
#' Sends an aggregation request (`size` forced to `0`, so no hits are returned)
#' and parses the response buckets into tibbles. Especially useful with the
#' Datamart source for counting processes by situation, phase, etc.
#'
#' @param cfg List. Configuration object from [datajud_config()].
#' @param body List. Request body from [build_query()] containing an `aggs`
#'   clause (see [agg_terms()], [agg_stats()]).
#'
#' @return If the body has a single aggregation, a tibble; otherwise a named
#'   list of tibbles, one per aggregation. `terms` aggregations return columns
#'   `key` and `doc_count`; `stats` aggregations return their metric columns.
#' @export
datajud_aggregate <- function(cfg, body) {

  if (is.null(body$aggs)) {
    stop("body precisa conter 'aggs'. Use build_query(query, aggs = ...).")
  }

  body$size <- 0

  res  <- datajud_request(cfg, body)
  aggs <- res$aggregations

  if (is.null(aggs)) {
    return(tibble::tibble())
  }

  out <- purrr::map(aggs, parse_aggregation)

  if (length(out) == 1) out[[1]] else out

}

#' @keywords internal
parse_aggregation <- function(agg) {

  # terms/histogram aggregations expose `buckets`
  if (!is.null(agg$buckets)) {
    return(
      purrr::map_dfr(agg$buckets, function(b) {
        tibble::tibble(
          key       = if (is.null(b$key)) NA else b$key,
          doc_count = if (is.null(b$doc_count)) NA_integer_ else b$doc_count
        )
      })
    )
  }

  # metric aggregations (stats, value_count, etc.): flatten scalar fields
  scalars <- agg[vapply(agg, function(x) length(x) == 1 && !is.list(x), logical(1))]
  if (length(scalars) > 0) {
    return(tibble::as_tibble(scalars))
  }

  tibble::tibble()

}
