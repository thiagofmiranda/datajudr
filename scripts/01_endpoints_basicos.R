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
  tribunal = "tjpa"
)

# ------------------------------------------------ - 
# ---- Teste 0: busca geral                    -----
# ------------------------------------------------ -

df_processos <- processos(
  cfg,
  page_size = 5,
  max_pages = 5,
  verbose = TRUE)

print(df_processos)

# ------------------------------------------------ - 
# ---- Teste 1: buscar processo por número     -----
# ------------------------------------------------ - 

df_processo <- processo_por_numero(
  cfg,
  "00365766720198030001",
  page_size = 5,
  verbose = TRUE
)

print(df_processo)


# ------------------------------------------------ - 
# ---- Teste 2: processos por classe           -----
# ------------------------------------------------ - 

df_classe <- processos_por_classe(
  cfg,
  classe = "Execução Fiscal",
  page_size = 5,
  max_pages = 5
)

dplyr::glimpse(df_classe)


# ------------------------------------------------ - 
# ---- Teste 3: processos por data             -----
# ------------------------------------------------ - 

df_data <- processos_por_data(
  cfg,
  data_inicio = "2023-01-01",
  data_fim = "2023-12-31",
  page_size = 5,
  max_pages = 5
)

dplyr::glimpse(df_data)






