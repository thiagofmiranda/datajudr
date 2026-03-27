#' datajudr: R Client for the DataJud API (CNJ)
#'
#' Provides functions to query and download judicial process data from the
#' DataJud platform (CNJ - Conselho Nacional de Justica) via its public
#' Elasticsearch API and BI download endpoints.
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
#'     URL base da API de consulta de processos (Elasticsearch).
#'
#'     Valor padrao: `https://api-publica.datajud.cnj.jus.br`
#'   }
#'   \item{`DATAJUD_BI_BASE_URL`}{
#'     URL base do endpoint de download de dados do BI do CNJ.
#'
#'     Valor padrao: `https://api-csvr.cloud.cnj.jus.br/download_csv`
#'   }
#' }
#'
#' @section Instalacao:
#'
#' ```r
#' # install.packages("devtools")
#' devtools::install_github("thiagofmiranda/datajud-r")
#' ```
#'
#' @section Uso basico:
#'
#' ```r
#' library(datajudr)
#'
#' # Configurar (usa defaults automaticamente)
#' cfg <- datajud_config(tribunal = "tjap")
#'
#' # Buscar processos
#' df <- processos_por_classe(cfg, "Habeas Corpus", max_pages = 1)
#'
#' # Download BI
#' dados <- download_bi(tribunal = "TJAP")
#' ```
#'
#' @keywords internal
"_PACKAGE"
