datajud_config <- function(api_key = Sys.getenv("DATAJUD_API_KEY"),
                           tribunal = "tjap",
                           base_url = Sys.getenv("DATAJUD_BASE_URL", "https://api-publica.datajud.cnj.jus.br")) {
  
  if(api_key == ""){
    stop("API Key não encontrada. Defina DATAJUD_API_KEY no ambiente.")
  }
  
  endpoint <- paste0(base_url, "/api_publica_", tribunal, "/_search")
  
  list(
    api_key = api_key,
    tribunal = tribunal,
    endpoint = endpoint
  )
  
}