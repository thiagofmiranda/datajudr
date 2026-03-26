datajud_search <- function(cfg,
                           body,
                           page_size = 100,
                           max_pages = Inf,
                           verbose = TRUE){
  
  if(is.null(body$query)){
    stop("body precisa conter 'query'. Use build_query().")
  }
  
  if(is.null(body$sort)){
    body$sort <- default_sort()
  }
  
  # estimativa antes da execução
  if(verbose){
    
    estimate <- datajud_estimate_download(
      cfg = cfg,
      body = body,
      page_size = page_size
    )
    
    print(estimate)
  }
  
  results <- datajud_search_after(
    cfg = cfg,
    body = body,
    page_size = page_size,
    max_pages = max_pages,
    verbose = verbose
  )
  
  extract_source(results)
  
}

datajud_count <- function(cfg, body){
  
  body$size <- 0
  body$track_total_hits <- TRUE
  
  res <- datajud_request(cfg, body)
  
  res$hits$total$value
  
}
datajud_estimate_download <- function(cfg,
                                      body,
                                      page_size = 100,
                                      rate_limit = 120){
  
  total <- datajud_count(cfg, body)
  
  pages <- ceiling(total / page_size)
  
  requests_per_second <- rate_limit / 60
  
  estimated_seconds <- pages / requests_per_second
  
  result <- list(
    total_results = total,
    page_size = page_size,
    total_pages = pages,
    rate_limit_per_minute = rate_limit,
    estimated_seconds = estimated_seconds
  )
  
  class(result) <- "datajud_estimate"
  
  result
  
}

print.datajud_estimate <- function(x, ...){
  
  cat("Estimativa de download DataJud\n")
  cat("-------------------------------\n")
  cat("Resultados totais: ", format(x$total_results, big.mark=","), "\n")
  cat("Page size: ", x$page_size, "\n")
  cat("Total de páginas: ", format(x$total_pages, big.mark=","), "\n")
  cat("Rate limit: ", x$rate_limit_per_minute, "req/min\n")
  
}