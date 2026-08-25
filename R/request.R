#' @keywords internal
.datajud_build_request <- function(cfg, body) {

  req <- httr2::request(cfg$endpoint) |>
    httr2::req_method("POST") |>
    httr2::req_body_json(body, auto_unbox = TRUE, null = "null")

  # Authentication depends on the data source: the public API uses an APIKey
  # header, while the raw Elastic API and the Datamart use HTTP Basic Auth.
  req <- switch(cfg$auth$type,
    apikey = httr2::req_headers(
      req,
      Authorization = paste("APIKey", cfg$auth$api_key)
    ),
    basic = httr2::req_auth_basic(
      req,
      username = cfg$auth$usuario,
      password = cfg$auth$senha
    ),
    stop("Tipo de autenticacao desconhecido: ", cfg$auth$type)
  )

  httr2::req_error(req, body = function(resp) {
    status <- httr2::resp_status(resp)
    base <- switch(as.character(status),
      "400" = "Requisicao invalida (400). Verifique a query, os campos e o 'sort'.",
      "401" = "Credenciais invalidas. Verifique a chave/usuario da API DataJud.",
      "403" = "Sem permissao de acesso. Verifique as credenciais da fonte.",
      "404" = "Endpoint/indice nao encontrado. Verifique o tribunal ou a fonte.",
      "429" = "Rate limit excedido. Aguarde antes de tentar novamente.",
      "500" = "Erro interno do servidor DataJud. Tente novamente mais tarde.",
      paste0("Erro da API DataJud (HTTP ", status, ").")
    )
    c(base, .datajud_error_detail(resp))
  })

}

# O DataJud/Elastic nem sempre declara (ou declara errado) o charset no header
# Content-Type, mas o corpo JSON e sempre UTF-8. Confiar no sniffing do httr2
# corrompe acentos (ex.: "Ã§Ã£o" no lugar de "cao"), entao forcamos UTF-8 ao
# ler o corpo e so entao parseamos o JSON. `simplifyVector = FALSE` mantem a
# estrutura de listas aninhadas que o restante do pacote consome.
#' @keywords internal
.datajud_parse_json <- function(resp) {
  txt <- httr2::resp_body_string(resp, encoding = "UTF-8")
  jsonlite::fromJSON(txt, simplifyVector = FALSE)
}

# Elasticsearch returns a JSON body explaining exactly why a request failed
# (e.g. "No mapping found for [id.keyword] in order to sort on"). The default
# handler hides it, so we surface `error.reason` / `error.root_cause` here.
#' @keywords internal
.datajud_error_detail <- function(resp) {
  tryCatch({
    j      <- .datajud_parse_json(resp)
    reason <- j$error$reason
    if (is.null(reason) && !is.null(j$error$root_cause)) {
      reason <- j$error$root_cause[[1]]$reason
    }
    if (is.null(reason)) NULL else paste0("Detalhe: ", reason)
  }, error = function(e) NULL)
}

#' @keywords internal
.datajud_request_raw <- function(cfg, body) {

  resp <- httr2::req_perform(.datajud_build_request(cfg, body))

  .datajud_parse_json(resp)

}

# Cache of rate-limited request wrappers, keyed by requests-per-minute. Each
# data source may declare its own `rate_limit`; we build one limiter per rate
# so different sources do not share (or fight over) the same token bucket.
.limiter_cache <- new.env(parent = emptyenv())

#' @keywords internal
#' @importFrom ratelimitr limit_rate rate
datajud_request <- function(cfg, body) {

  rpm <- cfg$rate_limit
  if (is.null(rpm) || !is.finite(rpm) || rpm <= 0) {
    return(.datajud_request_raw(cfg, body))
  }

  key     <- as.character(rpm)
  limited <- get0(key, envir = .limiter_cache, inherits = FALSE)

  if (is.null(limited)) {
    limited <- ratelimitr::limit_rate(
      .datajud_request_raw,
      ratelimitr::rate(n = rpm, period = 60)
    )
    assign(key, limited, envir = .limiter_cache)
  }

  limited(cfg, body)

}
