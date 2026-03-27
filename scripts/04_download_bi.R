library(dplyr)
devtools::load_all()


# ------------------------------------------------ -
# ---- Download BI - Dados completos do tribunal ---
# ------------------------------------------------ -

# Retorna uma lista nomeada, um dataframe por indicador
dados <- download_bi(
  tribunal = "TJAP",
  verbose  = TRUE
)

# Acessar cada indicador pelo nome
dplyr::glimpse(dados$TJAP_CPL)
dplyr::glimpse(dados$TJAP_CPL_15anos)
dplyr::glimpse(dados$TJAP_Sent)
dplyr::glimpse(dados$TJAP_TBaix)
dplyr::glimpse(dados$TJAP_tbl_correg)
dplyr::glimpse(dados$TJAP_CN)

# Ver todos os nomes disponiveis
names(dados)


# ------------------------------------------------ -
# ---- Download BI - Salvando em Parquet         ---
# ------------------------------------------------ -

# referencia e obrigatorio ao salvar — use o periodo de atualizacao do dado
# Cada indicador e salvo em dados_bi/2026/01/
dados <- download_bi(
  tribunal   = "TJAP",
  referencia = "2026/01",
  output_dir = "dados_bi",
  verbose    = TRUE
)

# Sem referencia + output_dir -> erro explicativo
# download_bi(tribunal = "TJAP", output_dir = "dados_bi")
# Error: O parametro `referencia` e obrigatorio ao salvar os dados.


# ------------------------------------------------ -
# ---- Download BI - Com filtros opcionais       ---
# ------------------------------------------------ -

# Filtros exigem indicador obrigatorio
# Exemplo: indicador ind3, orgao julgador 43909, grau G1, municipio 183
dados_filtrado <- download_bi(
  tribunal  = "TJAP",
  indicador = "ind3",
  oj        = "43909",
  grau      = "G1",
  municipio = "183",
  verbose   = TRUE
)

dplyr::glimpse(dados_filtrado)

# Sem indicador + filtro -> erro explicativo
# download_bi(tribunal = "TJAP", grau = "G1")
# Error: O parametro `indicador` e obrigatorio ao usar filtros (oj, grau, municipio).
