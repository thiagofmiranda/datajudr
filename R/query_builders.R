#' Build an Elasticsearch match query
#'
#' @param field Character. Field name.
#' @param value Character. Value to match (full-text search).
#' @return A named list representing the query clause.
#' @export
query_match <- function(field, value) {
  list(match = stats::setNames(list(value), field))
}

#' Build an Elasticsearch term query
#'
#' @param field Character. Field name.
#' @param value Character. Exact value to match.
#' @return A named list representing the query clause.
#' @export
query_term <- function(field, value) {
  list(term = stats::setNames(list(value), field))
}

#' Build an Elasticsearch range query
#'
#' @param field Character. Field name.
#' @param gte Lower bound (greater than or equal), or `NULL`.
#' @param lte Upper bound (less than or equal), or `NULL`.
#' @return A named list representing the query clause.
#' @export
query_range <- function(field, gte = NULL, lte = NULL) {

  if (is.null(gte) && is.null(lte)) {
    stop("query_range requer ao menos um dos parametros: `gte` ou `lte`.")
  }

  range_list <- list()
  if (!is.null(gte)) range_list$gte <- gte
  if (!is.null(lte)) range_list$lte <- lte

  list(range = stats::setNames(list(range_list), field))

}

#' Build an Elasticsearch match_all query
#'
#' @return A named list representing the query clause.
#' @export
query_match_all <- function() {
  list(match_all = structure(list(), names = character()))
}

#' Build an Elasticsearch bool query
#'
#' @param must List of query clauses that must match.
#' @param filter List of query clauses for filtering (no scoring).
#' @param should List of query clauses where at least one must match.
#' @param must_not List of query clauses that must not match.
#' @return A named list representing the query clause.
#' @export
query_bool <- function(must     = NULL,
                       filter   = NULL,
                       should   = NULL,
                       must_not = NULL) {

  if (is.null(must) && is.null(filter) && is.null(should) && is.null(must_not)) {
    stop("query_bool requer ao menos um dos parametros: `must`, `filter`, `should` ou `must_not`.")
  }

  bool <- list()
  if (!is.null(must))     bool$must     <- must
  if (!is.null(filter))   bool$filter   <- filter
  if (!is.null(should))   bool$should   <- should
  if (!is.null(must_not)) bool$must_not <- must_not

  list(bool = bool)

}

#' Wrap a query clause in the top-level query envelope
#'
#' @param query A query clause built with `query_*` functions.
#' @return A named list ready to be sent as an API request body.
#' @export
build_query <- function(query) {
  list(query = query)
}
