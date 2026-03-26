processo_por_numero <- function(cfg, numero_processo, ...){
  
  body <- build_query(
    query_term("numeroProcesso", numero_processo)
  )
  
  datajud_search(cfg, body, ...)
  
}

processos_por_classe <- function(cfg, classe, ...){
  
  body <- build_query(
    query_match("classe.nome", classe)
  )
  
  datajud_search(cfg, body, ...)
  
}

processos_por_data <- function(cfg,
                               data_inicio,
                               data_fim = NULL,
                               ...){
  
  body <- build_query(
    query_range(
      "dataAjuizamento",
      gte = data_inicio,
      lte = data_fim
    )
  )
  
  datajud_search(cfg, body, ...)
  
}

processos_busca <- function(cfg,
                            classe = NULL,
                            data_inicio = NULL,
                            data_fim = NULL,
                            ...){
  
  filters <- list()
  
  if(!is.null(classe)){
    filters <- append(filters, list(query_match("classe.nome", classe)))
  }
  
  if(!is.null(data_inicio) | !is.null(data_fim)){
    filters <- append(filters, list(query_range(
      "dataAjuizamento",
      gte = data_inicio,
      lte = data_fim
    )))
  }
  
  if(length(filters) == 0){
    body <- build_query(query_match_all())
  } else {
    body <- build_query(query_bool(filter = filters))
  }
  
  datajud_search(cfg, body, ...)
  
}

processos <- function(cfg, ...){
  
  body <- build_query(
    query_match_all()
  )
  
  datajud_search(cfg, body, ...)
  
}


# Aqui podem ser implementadas diversas funções para filtros específicos