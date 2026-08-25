#' datajudr: R Client for the DataJud API (CNJ)
#'
#' Provides functions to query and download judicial process data from the
#' DataJud platform (CNJ - Conselho Nacional de Justica). Supports two query
#' access modes — the public API (APIKey) and the Elasticsearch API (Basic Auth,
#' with the `view-processos-sigilo-*` and `datamart-*` indexes) — plus the public
#' *Painel de Estatistica* download.
#'
#' @section Configuracao:
#'
#' O pacote funciona sem nenhuma configuracao adicional, pois os valores
#' padrao ja estao embutidos. Caso qualquer uma das informacoes abaixo mude,
#' defina as variaveis de ambiente no seu `.Renviron`:
#'
#' ```
#' # Abrir o .Renviron para edicao:
#' usethis::edit_r_environ()
#' ```
#'
#' Variaveis disponiveis:
#'
#' \describe{
#'   \item{`DATAJUD_API_KEY`}{
#'     Chave de autenticacao da API do DataJud. A chave publica disponibilizada
#'     pelo CNJ ja e o valor padrao — so e necessario definir esta variavel se
#'     a chave for atualizada pelo CNJ.
#'
#'     Valor padrao: `cDZHYzlZa0JadVREZDJCendQbXY6SkJlTzNjLV9TRENyQk1RdnFKZGRQdw==`
#'
#'     Fonte: \url{https://datajud-wiki.cnj.jus.br/api-publica/acesso}
#'   }
#'   \item{`DATAJUD_BASE_URL`}{
#'     URL base da API publica de consulta de processos (Elasticsearch).
#'
#'     Valor padrao: `https://api-publica.datajud.cnj.jus.br`
#'   }
#'   \item{`DATAJUD_USER` / `DATAJUD_PWD`}{
#'     Usuario e senha (Basic Auth) da API Elastic (`fonte = "elastic"`),
#'     usados para os indices `view-processos-sigilo-*` e `datamart-*`.
#'     Sao fornecidos pelo tribunal; nao ha valor padrao.
#'
#'     Fonte: \url{https://datajud-wiki.cnj.jus.br/para-tribunais/Datajud/Api-elastic/}
#'   }
#'   \item{`DATAJUD_BI_BASE_URL`}{
#'     URL base do endpoint de download do Painel de Estatistica do CNJ (publico).
#'
#'     Valor padrao: `https://api-csvr.cloud.cnj.jus.br/download_csv`
#'   }
#' }
#'
#' @section Instalacao:
#'
#' ```r
#' # install.packages("devtools")
#' devtools::install_github("thiagofmiranda/datajudr")
#' ```
#'
#' @section Uso basico:
#'
#' ```r
#' library(datajudr)
#'
#' # API publica (usa defaults automaticamente)
#' cfg <- datajud_config(tribunal = "tjap")
#' df  <- processos_por_classe(cfg, "Habeas Corpus", max_pages = 1)
#'
#' # API Elastic + Datamart (Basic Auth via DATAJUD_USER / DATAJUD_PWD)
#' cfg_dm <- datajud_config(fonte = "elastic", indice = "datamart", tribunal = "tjap")
#' sit    <- datamart_por_situacao(cfg_dm)
#'
#' # Painel de Estatistica (publico, sem login)
#' dados <- download_bi(tribunal = "TJAP")
#' ```
#'
#' @keywords internal
"_PACKAGE"
