# =============================================================
# DEV — Sequencia de verificacao e construcao do pacote datajudr
# =============================================================
# Execute bloco a bloco no RStudio (Ctrl+Enter)

# Prerequisitos (rodar uma vez):
# install.packages(c("devtools", "roxygen2", "usethis"))


# -------------------------------------------------------------
# 0. Limpar ambiente global
#    Evita conflitos com objetos carregados via source() anteriormente
# -------------------------------------------------------------
rm(list = ls())


# -------------------------------------------------------------
# 1. Gerar documentacao (man/) e atualizar NAMESPACE via roxygen2
# -------------------------------------------------------------
devtools::document()


# -------------------------------------------------------------
# 2. Carregar o pacote em memoria sem instalar
#    Ideal para desenvolvimento rapido — equivale a source() de todos os R/
# -------------------------------------------------------------
devtools::load_all()


# -------------------------------------------------------------
# 3. Verificar o pacote (R CMD check)
#    Aponta erros de NAMESPACE, documentacao faltando, imports nao usados, etc.
# -------------------------------------------------------------
devtools::check()


# -------------------------------------------------------------
# 4. Instalar o pacote localmente (com vignettes compiladas)
# -------------------------------------------------------------
devtools::install(build_vignettes = TRUE)


# -------------------------------------------------------------
# 5. Carregar o pacote instalado e testar funcoes principais
# -------------------------------------------------------------
library(datajudr)

# -- config --
cfg <- datajud_config(tribunal = "TJAP")
print(cfg)

# -- contagem --
body <- build_query(query_match_all())
total <- datajud_count(cfg, body)
cat("Total de processos:", format(total, big.mark = ","), "\n")

# -- estimativa --
estimate <- datajud_estimate_download(cfg, body)
print(estimate)

# -- busca com limite de 1 pagina --
df <- datajud_search(cfg, body, max_pages = 1, verbose = TRUE)
dplyr::glimpse(df)

# -- query customizada --
df_classe <- processos_por_classe(cfg, "Habeas Corpus", max_pages = 1, verbose = FALSE)
dplyr::glimpse(df_classe)

# -- download BI --
dados_bi <- download_bi(tribunal = "TJAP", verbose = TRUE)
names(dados_bi)
dplyr::glimpse(dados_bi[[1]])
