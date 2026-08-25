el_empty <- function() {
  httr2::response(
    status_code = 200,
    headers = list("Content-Type" = "application/json"),
    body = charToRaw('{"hits":{"hits":[]}}')
  )
}

# Runs `call_fn()` against a mock that returns no hits (so search_after stops
# after one request) and returns the JSON body that was actually sent.
capture_query <- function(call_fn) {
  captured <- NULL
  mock <- function(req) {
    captured <<- req
    el_empty()
  }
  httr2::with_mocked_responses(mock, call_fn())
  jsonlite::toJSON(captured$body$data, auto_unbox = TRUE)
}

test_that("processos_brutos_* target the raw MTD fields", {
  cfg <- datajud_config("elastic", indice = "processos", usuario = "u", senha = "s")

  expect_match(
    capture_query(function() processos_brutos_por_numero(cfg, "00201597020148140401", verbose = FALSE)),
    "dadosBasicos.numero"
  )
  expect_match(
    capture_query(function() processos_brutos_por_classe(cfg, 279, verbose = FALSE)),
    "dadosBasicos.classeProcessual"
  )
  expect_match(
    capture_query(function() processos_brutos_por_data(cfg, "2024-01-01", verbose = FALSE)),
    "dadosBasicos.dpj_dataAjuizamento"
  )
  expect_match(
    capture_query(function() processos_brutos_sigilosos(cfg, verbose = FALSE)),
    "dadosBasicos.nivelSigilo"
  )
})

test_that("processos_brutos builds a terms query from a list of values", {
  cfg <- datajud_config("elastic", indice = "processos", usuario = "u", senha = "s")

  sent <- capture_query(function() {
    processos_brutos(
      cfg,
      variavel = "dadosBasicos.numero",
      valores  = c("123", "133"),
      verbose  = FALSE
    )
  })

  expect_match(sent, "terms")
  expect_match(sent, "dadosBasicos.numero")
  expect_match(sent, "123")
  expect_match(sent, "133")
})

test_that("processos_brutos_* warn on the wrong source/index", {
  cfg_dm  <- datajud_config("elastic", indice = "datamart", usuario = "u", senha = "s")
  cfg_pub <- datajud_config(tribunal = "tjsp")
  expect_warning(check_indice_processos(cfg_dm),  "processos")
  expect_warning(check_indice_processos(cfg_pub), "processos")
})
