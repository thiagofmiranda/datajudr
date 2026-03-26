source("R/config.R")
source("R/request.R")
source("R/query_builders.R")
source("R/endpoints_tjap.R")

cfg <- datajud_config(
  api_key = Sys.getenv("DATAJUD_API_KEY")
)

res <- tjap_por_classe(cfg, "Execução Fiscal")


body <- list(
  query = list(
    match_all = list()
  ),
  sort = list(
    list(`@timestamp` = list(order = "asc"))
  )
)

res <- datajud_search_after(cfg, body)

df <- extract_source(res)