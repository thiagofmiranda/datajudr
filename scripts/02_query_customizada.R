library(dplyr)
devtools::load_all()

# Configurando endpoint a ser usando
cfg <- datajud_config(tribunal = "TJPA")

# ------------------------------------------------ -
# ---- Query simples                           -----
# ------------------------------------------------ -
body <- build_query(
  query_match("classe.nome", "Execucao Fiscal")
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
      query_match("classe.nome", "Execucao Fiscal"),
      query_range(
        "dataAjuizamento",
        gte = "2022-01-01"
      )
    )
  )
)

df <- datajud_search(
  cfg,
  body,
  page_size = 5,
  max_pages = 1
)

dplyr::glimpse(df)
