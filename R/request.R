#' @keywords internal
.datajud_request_raw <- function(cfg, body) {

  req <- httr2::request(cfg$endpoint) |>
    httr2::req_method("POST") |>
    httr2::req_headers(
      Authorization = paste("APIKey", cfg$api_key)
    ) |>
    httr2::req_body_json(body, auto_unbox = TRUE, null = "null") |>
    httr2::req_error(body = function(resp) {
      status <- httr2::resp_status(resp)
      switch(as.character(status),
        "401" = "API Key invalida. Verifique DATAJUD_API_KEY.",
        "403" = "Sem permissao de acesso. Verifique DATAJUD_API_KEY.",
        "404" = "Endpoint nao encontrado. Verifique o codigo do tribunal.",
        "429" = "Rate limit excedido. Aguarde antes de tentar novamente.",
        "500" = "Erro interno do servidor DataJud. Tente novamente mais tarde.",
        paste0("Erro da API DataJud (HTTP ", status, ").")
      )
    })

  resp <- httr2::req_perform(req)

  httr2::resp_body_json(resp)

}

#' @keywords internal
#' @importFrom ratelimitr limit_rate rate
datajud_request <- ratelimitr::limit_rate(
  .datajud_request_raw,
  rate = ratelimitr::rate(n = 120, period = 60)
)
