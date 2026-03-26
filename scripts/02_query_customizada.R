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
# ---- Query simples                           -----
# ------------------------------------------------ -
body <- build_query(
  query_match("classe.nome", "Execução Fiscal")
)

df <- datajud_search(
  cfg,
  body,
  page_size = 5,
  max_pages = 1
)

dplyr::glimpse(df)


# ------------------------------------------------ - 
# ---- Query por intervalo de data             -----
# ------------------------------------------------ -
body <- build_query(
  query_range(
    "dataAjuizamento",
    gte = "2024-01-01",
    lte = "2024-12-31"
  )
)

df <- datajud_search(
  cfg,
  body,
  page_size = 5,
  max_pages = 1
)

dplyr::glimpse(df)


# ------------------------------------------------ - 
# ---- Query combinada                         -----
# ------------------------------------------------ -
body <- build_query(
  
  query_bool(
    filter = list(
      query_match("classe.nome", "Execução Fiscal"),
      query_range(
        "dataAjuizamento",
        gte = "2022-01-01"
      )
    )
  )
  
)

df1 <- datajud_search(
  cfg,
  body,
  page_size = 5,
  max_pages = 1
)

dplyr::glimpse(df)


