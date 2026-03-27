library(dplyr)
devtools::load_all()

# Configurando endpoint a ser usando
cfg <- datajud_config(tribunal = "TJAP")


## Construir query
body <- build_query(
  query_match("classe.nome", "Execucao Fiscal")
)


## Estimar download
estimate <- datajud_estimate_download(
  cfg,
  body,
  page_size = 200
)

print(estimate)


## Definir diretorio de saida
output_dir <- "dados_tjap_execucao_fiscal"


## Executar download
download_processos(
  cfg,
  body,
  output_dir  = output_dir,
  page_size   = 50,
  batch_pages = 3,
  verbose     = TRUE
)
