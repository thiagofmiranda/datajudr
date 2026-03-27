library(dplyr)
devtools::load_all()

# Configurando endpoint a ser usando
cfg <- datajud_config(tribunal = "TJPA")

# ------------------------------------------------ -
# ---- Teste 0: busca geral                    -----
# ------------------------------------------------ -

df_processos <- processos(
  cfg,
  page_size = 5,
  max_pages = 5,
  verbose = TRUE
)

print(df_processos)

# ------------------------------------------------ -
# ---- Teste 1: buscar processo por numero     -----
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
  classe = "Execucao Fiscal",
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
  data_fim    = "2023-12-31",
  page_size   = 5,
  max_pages   = 5
)

dplyr::glimpse(df_data)
