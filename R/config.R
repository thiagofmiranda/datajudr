#' Create a DataJud API configuration object
#'
#' Builds a configuration list with credentials, endpoint URL, authentication
#' scheme and default sort field used by the DataJud query functions. There are
#' two access modes (`fonte`):
#'
#' * `"publica"` — the public API, open access, non-confidential processes only.
#'   Authenticated with an APIKey.
#' * `"elastic"` — the Elasticsearch API, restricted to tribunals, authenticated
#'   with a username and password (Basic Auth). Within it you choose the
#'   `indice`:
#'     - `"processos"` — raw processes (`view-processos-sigilo-*`), includes
#'       confidential processes.
#'     - `"datamart"` — flat aggregated metadata (`datamart-<tribunal>`), one
#'       document per process.
#'
#' The public *Painel de Estatística* download is handled separately by
#' [download_bi()], which does not require a configuration object or login.
#'
#' @param fonte Character. Access mode: `"publica"` (default, APIKey) or
#'   `"elastic"` (Basic Auth).
#' @param indice Character. Only used when `fonte = "elastic"`: which index to
#'   query, `"processos"` (default, `view-processos-sigilo-*`) or `"datamart"`
#'   (`datamart-*`).
#' @param tribunal Character. Tribunal code (e.g. `"TJAP"`). Used to build the
#'   public API index and the Datamart index (`datamart-<tribunal>`). Converted
#'   to lowercase internally.
#' @param api_key Character. APIKey for `fonte = "publica"`. Defaults to the
#'   `DATAJUD_API_KEY` environment variable or the CNJ public key.
#' @param usuario Character. Basic Auth username for `fonte = "elastic"`.
#'   Defaults to the `DATAJUD_USER` environment variable.
#' @param senha Character. Basic Auth password for `fonte = "elastic"`.
#'   Defaults to the `DATAJUD_PWD` environment variable.
#' @param base_url Character or NULL. Override the base URL. For `"publica"`,
#'   defaults to the `DATAJUD_BASE_URL` environment variable or the public
#'   endpoint; for `"elastic"`, defaults to the Elasticsearch API endpoint.
#' @param index Character or NULL. Override the Elasticsearch index/alias
#'   (e.g. a specific `datamart-tjsp`). Defaults to the value implied by
#'   `fonte`/`indice`.
#' @param rate_limit Numeric. Maximum requests per minute. Default `120` (the
#'   public API limit). Set to `Inf` to disable client-side rate limiting.
#'
#' @return A named list describing the connection, with elements `fonte`,
#'   `indice`, `tribunal`, `endpoint`, `auth`, `sort` and `rate_limit`.
#' @export
datajud_config <- function(fonte      = c("publica", "elastic"),
                           indice     = c("processos", "datamart"),
                           tribunal   = "TJAP",
                           api_key    = Sys.getenv(
                             "DATAJUD_API_KEY",
                             "cDZHYzlZa0JadVREZDJCendQbXY6SkJlTzNjLV9TRENyQk1RdnFKZGRQdw=="
                           ),
                           usuario    = Sys.getenv("DATAJUD_USER"),
                           senha      = Sys.getenv("DATAJUD_PWD"),
                           base_url   = NULL,
                           index      = NULL,
                           rate_limit = 120) {

  fonte    <- match.arg(fonte)
  tribunal <- tolower(tribunal)

  if (fonte == "publica") {

    if (is.null(base_url)) {
      base_url <- Sys.getenv("DATAJUD_BASE_URL", "https://api-publica.datajud.cnj.jus.br")
    }
    if (is.null(index)) index <- paste0("api_publica_", tribunal)

    if (api_key == "") {
      stop("API Key nao encontrada. Defina DATAJUD_API_KEY no ambiente.")
    }

    auth   <- list(type = "apikey", api_key = api_key)
    sort   <- "@timestamp"
    indice <- NA_character_

  } else {  # elastic: usuario/senha, escolhe o indice

    indice <- match.arg(indice)

    # Cada indice tem um campo de ordenacao estavel para o search_after:
    # em view-processos-sigilo-* o `id` e string (usa `id.keyword`); no
    # datamart-* o `id` e do tipo `long` (usa `id`).
    #
    # O curinga `*` e bloqueado pelo firewall, entao usamos alvos explicitos:
    # os cinco shards `view-processos-sigilo-0..4` separados por virgula, e o
    # `datamart-<tribunal>` especifico em vez de `datamart-*`.
    spec <- switch(indice,
      processos = list(
        index = paste0("view-processos-sigilo-", 0:4, collapse = ","),
        sort  = "id.keyword"
      ),
      datamart  = list(
        index = paste0("datamart-", tribunal),
        sort  = "id"
      )
    )

    if (is.null(base_url)) base_url <- "https://api.datajud.cnj.jus.br"
    if (is.null(index))    index    <- spec$index
    sort <- spec$sort

    if (usuario == "" || senha == "") {
      stop(
        "Credenciais Basic Auth nao encontradas para a fonte 'elastic'.\n",
        "Defina DATAJUD_USER e DATAJUD_PWD no ambiente, ou passe `usuario` e `senha`."
      )
    }

    auth <- list(type = "basic", usuario = usuario, senha = senha)

  }

  endpoint <- paste0(base_url, "/", index, "/_search")

  list(
    fonte      = fonte,
    indice     = indice,
    tribunal   = tribunal,
    endpoint   = endpoint,
    auth       = auth,
    sort       = sort,
    rate_limit = rate_limit
  )

}
