library(dplyr)

source("R/config.R")
source("R/request.R")
source("R/pagination.R")
source("R/parsing.R")
source("R/query_builders.R")
source("R/search.R")
source("R/endpoints_processos.R")
source("R/download.R")


# Configurando endpoint a ser usando
cfg <- datajud_config(
  api_key = Sys.getenv("DATAJUD_API_KEY"),
  tribunal = "tjap"
)


## Construir query
body <- build_query(
  query_match("classe.nome", "Execução Fiscal")
)


## Estimar download
estimate <- datajud_estimate_download(
  cfg,
  body,
  page_size = 200
)

print(estimate)


## Definir diretório de saída
output_dir <- "dados_tjap_execucao_fiscal"



## Executar download
download_processos(
  cfg,
  body,
  output_dir = output_dir,
  page_size = 50,
  batch_pages = 3,
  verbose = TRUE
)







