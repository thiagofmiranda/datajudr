datajud_search_after <- function(cfg,
                                 body,
                                 page_size = 100,
                                 max_pages = Inf,
                                 verbose = TRUE){
  
  if(is.null(body$sort)){
    stop("body$sort precisa ser definido para usar search_after")
  }
  
  body$size <- page_size
  
  results <- list()
  search_after <- NULL
  page <- 1
  
  repeat{
    
    if(!is.null(search_after)){
      body$search_after <- search_after
    }
    
    if(verbose){
      message("Baixando página: ", page)
    }
    
    res <- datajud_request(cfg, body)
    
    hits <- res$hits$hits
    
    if(length(hits) == 0){
      break
    }
    
    results[[page]] <- hits
    
    # pegar último documento da página
    last_hit <- hits[[length(hits)]]
    
    # atualizar search_after
    search_after <- last_hit$sort
    
    page <- page + 1
    
    if(page > max_pages){
      break
    }
    
  }
  
  results
  
}

default_sort <- function(){
  
  list(
    list(`@timestamp` = list(order = "asc"))
  )
  
}