# O search_after exige uma ordenacao estavel. A API publica usa `@timestamp`;
# a API elastic e o Datamart usam `id.keyword` (conforme documentacao oficial),
# garantindo paginacao eficiente em grandes volumes sem recarregar resultados.
#' @keywords internal
datajud_search_after <- function(cfg,
                                 body,
                                 page_size = 100,
                                 max_pages = Inf,
                                 verbose   = TRUE) {

  if (is.null(body$sort)) {
    stop("body$sort precisa ser definido para usar search_after")
  }

  body$size <- page_size

  results      <- list()
  search_after <- NULL
  page         <- 1

  repeat {

    if (!is.null(search_after)) {
      body$search_after <- search_after
    }

    if (verbose) {
      message("Baixando pagina: ", page)
    }

    res  <- datajud_request(cfg, body)
    hits <- res$hits$hits

    if (length(hits) == 0) break

    results[[page]] <- hits

    last_hit <- hits[[length(hits)]]

    if (is.null(last_hit$sort)) {
      stop("Campo 'sort' nao retornado pela API. Verifique se o body possui clausula 'sort'.")
    }

    # Pagina incompleta => ja e a ultima; evita uma requisicao extra vazia
    # (com a excecao inevitavel de um total multiplo exato de page_size).
    if (length(hits) < page_size) break

    search_after <- last_hit$sort
    page         <- page + 1

    if (page > max_pages) break

  }

  results

}

#' @keywords internal
default_sort <- function(cfg = NULL) {
  field <- if (!is.null(cfg) && !is.null(cfg$sort)) cfg$sort else "@timestamp"
  list(
    stats::setNames(list(list(order = "asc")), field)
  )
}
