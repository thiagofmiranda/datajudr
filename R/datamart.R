#' @keywords internal
check_indice_datamart <- function(cfg) {
  if (!identical(cfg$fonte, "elastic") || !identical(cfg$indice, "datamart")) {
    warning(
      "Esta funcao foi feita para fonte 'elastic' com indice 'datamart', mas ",
      "cfg usa fonte '", cfg$fonte, "' / indice '", cfg$indice, "'. ",
      "Os campos consultados podem nao existir.",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

#' Search confidential (sigiloso) processes in the Datamart
#'
#' Filters the Datamart index for processes with a confidentiality level at or
#' above `sigilo_min`, optionally restricted to a current situation code.
#'
#' @param cfg List. Configuration object from [datajud_config()] with
#'   `fonte = "elastic"` and `indice = "datamart"`.
#' @param id_situacao_atual Integer or NULL. Current situation code to filter
#'   by (e.g. `25` for processes in progress). `NULL` keeps all situations.
#' @param sigilo_min Integer. Minimum confidentiality level. Default `1`
#'   (`0` = public, `>= 1` = confidential).
#' @param ... Additional arguments passed to [datajud_search()].
#'
#' @return A tibble with matching processes.
#' @export
datamart_sigilosos <- function(cfg,
                               id_situacao_atual = 25L,
                               sigilo_min        = 1L,
                               ...) {

  check_indice_datamart(cfg)

  filters <- list(query_range("sigilo", gte = sigilo_min))

  if (!is.null(id_situacao_atual)) {
    filters <- append(
      filters,
      list(query_term("id_situacao_atual", id_situacao_atual))
    )
  }

  body <- build_query(query_bool(filter = filters))

  datajud_search(cfg, body, ...)

}

#' Search criminal (or non-criminal) processes in the Datamart
#'
#' @param cfg List. Configuration object from [datajud_config()] with
#'   `fonte = "elastic"` and `indice = "datamart"`.
#' @param criminal Logical. `TRUE` (default) for criminal processes, `FALSE`
#'   for non-criminal.
#' @param ... Additional arguments passed to [datajud_search()].
#'
#' @return A tibble with matching processes.
#' @export
datamart_criminais <- function(cfg, criminal = TRUE, ...) {

  check_indice_datamart(cfg)

  body <- build_query(query_term("criminal", criminal))

  datajud_search(cfg, body, ...)

}

#' Count Datamart processes grouped by current situation
#'
#' Runs a terms aggregation over `situacao_atual`, returning a tidy tibble of
#' situation labels and process counts without downloading the documents.
#'
#' @param cfg List. Configuration object from [datajud_config()] with
#'   `fonte = "elastic"` and `indice = "datamart"`.
#' @param query A query clause to scope the aggregation. Default
#'   [query_match_all()] (all processes).
#' @param size Integer. Maximum number of situation buckets. Default `100`.
#'
#' @return A tibble with columns `key` (situation) and `doc_count`.
#' @export
datamart_por_situacao <- function(cfg,
                                  query = query_match_all(),
                                  size  = 100) {

  check_indice_datamart(cfg)

  body <- build_query(
    query,
    aggs = agg_terms("por_situacao", "situacao_atual", size = size)
  )

  datajud_aggregate(cfg, body)

}
