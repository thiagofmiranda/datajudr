download_processos <- function(cfg,
                               body,
                               output_dir,
                               page_size = 100,
                               batch_pages = 50,
                               verbose = TRUE){
  
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  
  if(is.null(body$sort)){
    body$sort <- default_sort()
  }
  
  body$size <- page_size
  
  search_after <- NULL
  page <- 1
  batch <- list()
  file_index <- 1
  
  repeat{
    
    if(!is.null(search_after)){
      body$search_after <- search_after
    }
    
    if(verbose){
      message("Página: ", page)
    }
    
    res <- datajud_request(cfg, body)
    
    hits <- res$hits$hits
    
    if(length(hits) == 0){
      break
    }
    
    batch[[length(batch) + 1]] <- hits
    
    last_hit <- hits[[length(hits)]]
    
    if(is.null(last_hit$sort)){
      stop("Campo 'sort' não retornado pela API.")
    }
    
    search_after <- last_hit$sort
    
    if(page %% batch_pages == 0){
      
      df <- extract_source(batch)
      
      df <- serialize_list_columns(df)
      
      file_path <- file.path(
        output_dir,
        paste0("processos_", file_index, ".parquet")
      )
      
      arrow::write_parquet(df, file_path)
      
      if(verbose){
        message("Arquivo salvo: ", file_path)
      }
      
      batch <- list()
      file_index <- file_index + 1
      
      gc()
    }
    
    page <- page + 1
  }
  
  if(length(batch) > 0){
    
    df <- extract_source(batch)
    
    df <- serialize_list_columns(df)
    
    file_path <- file.path(
      output_dir,
      paste0("processos_", file_index, ".parquet")
    )
    
    arrow::write_parquet(df, file_path)
    
    if(verbose){
      message("Arquivo salvo: ", file_path)
    }
  }
  
  invisible(output_dir)
  
}



serialize_list_columns <- function(df){
  
  list_cols <- names(df)[sapply(df, is.list)]
  
  if(length(list_cols) == 0){
    return(df)
  }
  
  df[list_cols] <- lapply(
    df[list_cols],
    function(col){
      vapply(
        col,
        jsonlite::toJSON,
        character(1),
        auto_unbox = TRUE,
        null = "null"
      )
    }
  )
  
  df
}

