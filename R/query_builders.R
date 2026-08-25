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

#' Build an Elasticsearch terms query (match any of several exact values)
#'
#' @param field Character. Field name.
#' @param values Vector. Exact values to match (logical OR).
#' @return A named list representing the query clause.
#' @export
query_terms <- function(field, values) {
  list(terms = stats::setNames(list(as.list(values)), field))
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
#' @param aggs A named list of aggregations built with `agg_*` functions, or
#'   `NULL` (default). Combine several with [c()].
#' @param size Integer or `NULL`. Number of hits to return. Set to `0` for
#'   aggregation-only requests. Default `NULL` (leave unset).
#' @return A named list ready to be sent as an API request body.
#' @export
build_query <- function(query, aggs = NULL, size = NULL) {
  body <- list(query = query)
  if (!is.null(aggs)) body$aggs <- aggs
  if (!is.null(size)) body$size <- size
  body
}

#' Build an Elasticsearch terms aggregation
#'
#' Buckets documents by the distinct values of a field. Useful with the
#' Datamart to count processes by `situacao_atual`, `fase_atual`, etc.
#'
#' @param name Character. Aggregation name (used as the result column/name).
#' @param field Character. Field to bucket by (use a `keyword` field).
#' @param size Integer. Maximum number of buckets. Default `100`.
#' @return A named list representing the aggregation clause.
#' @export
agg_terms <- function(name, field, size = 100) {
  stats::setNames(
    list(list(terms = list(field = field, size = size))),
    name
  )
}

#' Build an Elasticsearch stats aggregation
#'
#' Computes count, min, max, avg and sum for a numeric field.
#'
#' @param name Character. Aggregation name.
#' @param field Character. Numeric field to summarise.
#' @return A named list representing the aggregation clause.
#' @export
agg_stats <- function(name, field) {
  stats::setNames(
    list(list(stats = list(field = field))),
    name
  )
}
