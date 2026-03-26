query_match <- function(field, value){
  
  list(
    match = stats::setNames(list(value), field)
  )
  
}

query_term <- function(field, value){
  
  list(
    term = stats::setNames(list(value), field)
  )
  
}

query_range <- function(field, gte = NULL, lte = NULL){
  
  range_list <- list()
  
  if(!is.null(gte)){
    range_list$gte <- gte
  }
  
  if(!is.null(lte)){
    range_list$lte <- lte
  }
  
  list(
    range = stats::setNames(list(range_list), field)
  )
  
}

query_match_all <- function(){
  
  list(
    match_all = structure(list(), names = character())
  )
  
}

query_bool <- function(must = NULL,
                       filter = NULL,
                       should = NULL,
                       must_not = NULL){
  
  bool <- list()
  
  if(!is.null(must)) bool$must <- must
  if(!is.null(filter)) bool$filter <- filter
  if(!is.null(should)) bool$should <- should
  if(!is.null(must_not)) bool$must_not <- must_not
  
  list(
    bool = bool
  )
  
}

build_query <- function(query){
  
  list(
    query = query
  )
  
}

