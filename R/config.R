#' Create a DataJud API configuration object
#'
#' Builds a configuration list with credentials and endpoint URL used by all
#' DataJud API functions.
#'
#' @param api_key Character. DataJud API key. Defaults to the
#'   `DATAJUD_API_KEY` environment variable.
#' @param tribunal Character. Tribunal code in uppercase (e.g. `"TJAP"`). Converted to lowercase internally.
#' @param base_url Character. Base URL of the DataJud API. Defaults to the
#'   `DATAJUD_BASE_URL` environment variable or the public endpoint.
#'
#' @return A named list with `api_key`, `tribunal`, and `endpoint`.
#' @export
datajud_config <- function(api_key  = Sys.getenv(
                             "DATAJUD_API_KEY",
                             "cDZHYzlZa0JadVREZDJCendQbXY6SkJlTzNjLV9TRENyQk1RdnFKZGRQdw=="
                           ),
                           tribunal = "TJAP",
                           base_url = Sys.getenv(
                             "DATAJUD_BASE_URL",
                             "https://api-publica.datajud.cnj.jus.br"
                           )) {

  if (api_key == "") {
    stop("API Key nao encontrada. Defina DATAJUD_API_KEY no ambiente.")
  }

  tribunal <- tolower(tribunal)
  endpoint <- paste0(base_url, "/api_publica_", tribunal, "/_search")

  list(
    api_key  = api_key,
    tribunal = tribunal,
    endpoint = endpoint
  )

}
