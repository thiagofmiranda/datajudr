# A ordenacao por @timestamp e exigida pela API do DataJud para uso do
# search_after. Conforme documentacao oficial, este campo garante paginacao
# eficiente em grandes volumes sem recarregar resultados a cada pagina.
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

    search_after <- last_hit$sort
    page         <- page + 1

    if (page > max_pages) break

  }

  results

}

#' @keywords internal
default_sort <- function() {
  list(
    list(`@timestamp` = list(order = "asc"))
  )
}
