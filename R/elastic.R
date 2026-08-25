#' @keywords internal
check_indice_processos <- function(cfg) {
  if (!identical(cfg$fonte, "elastic") || !identical(cfg$indice, "processos")) {
    warning(
      "Esta funcao foi feita para fonte 'elastic' com indice 'processos' ",
      "(view-processos-sigilo-*), mas cfg usa fonte '", cfg$fonte,
      "' / indice '", cfg$indice, "'. Os campos consultados podem nao existir.",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

#' Search processes by any field and a list of values
#'
#' **Primary, recommended function for pulling raw process data.** Generic entry
#' point that works with **any** source/index: pick a field and pass one or more
#' exact values. Internally builds a `terms` query (logical OR), so a single call
#' fetches every process whose `variavel` matches **any** of `valores`. You
#' choose the field, so no index is assumed — use the raw MTD fields
#' (`dadosBasicos.*`) with the `processos` index, the Datamart fields with the
#' `datamart` index, or the public API fields.
#'
#' @param cfg List. Configuration from [datajud_config()].
#' @param variavel Character. Field to filter on, e.g. `"dadosBasicos.numero"`
#'   (raw index), `"id_situacao_atual"` (datamart) or `"numeroProcesso"`
#'   (public API).
#' @param valores Vector. One or more exact values to match. Matches any of them.
#' @param ... Additional arguments passed to [datajud_search()].
#'
#' @return A tibble with matching processes.
#' @examples
#' \dontrun{
#' cfg <- datajud_config("elastic", indice = "processos",
#'                       usuario = "user", senha = "pass")
#' processos_brutos(cfg,
#'                  variavel = "dadosBasicos.numero",
#'                  valores  = c("00201597020148140401", "00201597020148140402"))
#' }
#' @seealso [processos_brutos_por_numero()] for the single-number shorthand tied
#'   to the raw `processos` index.
#' @export
processos_brutos <- function(cfg, variavel, valores, ...) {

  body <- build_query(query_terms(variavel, valores))

  datajud_search(cfg, body, ...)

}

#' Search a raw process by its number (Elastic `processos` index)
#'
#' Uses the raw CNJ (MTD) schema field `dadosBasicos.numero`, present in the
#' `view-processos-sigilo-*` index — unlike the public API's `numeroProcesso`.
#'
#' @param cfg List. Configuration from [datajud_config()] with
#'   `fonte = "elastic"` and `indice = "processos"`.
#' @param numero Character. Process number, digits only (e.g.
#'   `"00201597020148140401"`).
#' @param ... Additional arguments passed to [datajud_search()].
#'
#' @return A tibble with matching processes.
#' @export
processos_brutos_por_numero <- function(cfg, numero, ...) {

  check_indice_processos(cfg)

  body <- build_query(query_term("dadosBasicos.numero", numero))

  datajud_search(cfg, body, ...)

}

#' Search raw processes by class code (Elastic `processos` index)
#'
#' The raw index stores only the class **code** (`dadosBasicos.classeProcessual`),
#' not its name, so filter by the national class code.
#'
#' @param cfg List. Configuration from [datajud_config()] with
#'   `fonte = "elastic"` and `indice = "processos"`.
#' @param codigo_classe Integer. National class code (e.g. `279`).
#' @param ... Additional arguments passed to [datajud_search()].
#'
#' @return A tibble with matching processes.
#' @export
processos_brutos_por_classe <- function(cfg, codigo_classe, ...) {

  check_indice_processos(cfg)

  body <- build_query(query_term("dadosBasicos.classeProcessual", codigo_classe))

  datajud_search(cfg, body, ...)

}

#' Search raw processes by filing date range (Elastic `processos` index)
#'
#' Filters on `dadosBasicos.dpj_dataAjuizamento` (ISO 8601), the reliable date
#' field for range queries in the raw index (the `dadosBasicos.dataAjuizamento`
#' field is stored as a `YYYYMMDDHHMMSS` string).
#'
#' @param cfg List. Configuration from [datajud_config()] with
#'   `fonte = "elastic"` and `indice = "processos"`.
#' @param data_inicio Character. Start date in `"YYYY-MM-DD"` format.
#' @param data_fim Character or NULL. End date in `"YYYY-MM-DD"` format.
#' @param ... Additional arguments passed to [datajud_search()].
#'
#' @return A tibble with matching processes.
#' @export
processos_brutos_por_data <- function(cfg, data_inicio, data_fim = NULL, ...) {

  check_indice_processos(cfg)

  body <- build_query(
    query_range("dadosBasicos.dpj_dataAjuizamento", gte = data_inicio, lte = data_fim)
  )

  datajud_search(cfg, body, ...)

}

#' Search confidential raw processes (Elastic `processos` index)
#'
#' Filters on `dadosBasicos.nivelSigilo` (`0` = public, `>= 1` = confidential).
#' Unlike the public API, the raw index exposes confidential processes.
#'
#' @param cfg List. Configuration from [datajud_config()] with
#'   `fonte = "elastic"` and `indice = "processos"`.
#' @param nivel_min Integer. Minimum confidentiality level. Default `1`.
#' @param ... Additional arguments passed to [datajud_search()].
#'
#' @return A tibble with matching processes.
#' @export
processos_brutos_sigilosos <- function(cfg, nivel_min = 1L, ...) {

  check_indice_processos(cfg)

  body <- build_query(query_range("dadosBasicos.nivelSigilo", gte = nivel_min))

  datajud_search(cfg, body, ...)

}
