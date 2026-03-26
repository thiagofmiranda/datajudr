extract_source <- function(results){
  
  if(length(results) == 0){
    return(tibble::tibble())
  }
  
  purrr::map_dfr(results, function(page){
    
    purrr::map_dfr(page, function(hit){
      
      source_to_row(hit$`_source`)
      
    })
    
  })
  
}

extract_hits <- function(results){
  
  if(length(results) == 0){
    return(tibble::tibble())
  }
  
  purrr::map_dfr(results, function(page){
    
    purrr::map_dfr(page, function(hit){
      
      source <- source_to_row(hit$`_source`)
      
      tibble::tibble(
        id = hit$`_id`,
        index = hit$`_index`,
        sort = list(hit$sort)
      ) |>
        dplyr::bind_cols(source)
      
    })
    
  })
  
}



source_to_row <- function(source){
  
  source <- lapply(source, function(x){
    
    if(length(x) == 1){
      x
    } else {
      list(x)
    }
    
  })
  
  tibble::as_tibble(source)
  
}

# tidyr::unnest(df, movimentos)