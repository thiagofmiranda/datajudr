json_response <- function(obj) {
  httr2::response(
    status_code = 200,
    headers = list("Content-Type" = "application/json"),
    body = charToRaw(jsonlite::toJSON(obj, auto_unbox = TRUE, null = "null"))
  )
}

test_that("public source sends an APIKey Authorization header", {
  skip_if_not_installed("httpuv")  # req_dry_run() exige httpuv
  cfg <- datajud_config(tribunal = "tjsp")
  req <- .datajud_build_request(cfg, build_query(query_match_all()))
  dr  <- httr2::req_dry_run(req, quiet = TRUE, redact_headers = FALSE)
  hdr <- stats::setNames(dr$headers, tolower(names(dr$headers)))
  expect_match(hdr$authorization, "^APIKey ")
})

test_that("basic-auth sources send an Authorization header", {
  skip_if_not_installed("httpuv")  # req_dry_run() exige httpuv
  cfg <- datajud_config("elastic", indice = "datamart", usuario = "u", senha = "s")
  req <- .datajud_build_request(cfg, build_query(query_match_all()))
  dr  <- httr2::req_dry_run(req, quiet = TRUE, redact_headers = FALSE)
  hdr <- stats::setNames(dr$headers, tolower(names(dr$headers)))
  expect_true("authorization" %in% names(hdr))
  expect_match(hdr$authorization, "^Basic ")
})

test_that("datajud_search paginates with search_after and parses _source", {
  cfg <- datajud_config("elastic", indice = "datamart", usuario = "u", senha = "s")

  page1 <- json_response(list(hits = list(hits = list(
    list(`_id` = "a", `_index` = "datamart-x",
         `_source` = list(id = "a", situacao_atual = "Em tramitacao"),
         sort = list("a")),
    list(`_id` = "b", `_index` = "datamart-x",
         `_source` = list(id = "b", situacao_atual = "Baixado"),
         sort = list("b"))
  ))))
  page2 <- json_response(list(hits = list(hits = list())))

  res <- httr2::with_mocked_responses(
    list(page1, page2),
    datajud_search(cfg, build_query(query_match_all()), page_size = 2, verbose = FALSE)
  )

  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 2)
  expect_equal(res$situacao_atual, c("Em tramitacao", "Baixado"))
})

test_that("UTF-8 accents survive a wrongly-declared charset", {
  cfg <- datajud_config("elastic", indice = "processos", usuario = "u", senha = "s")

  # Corpo em bytes UTF-8, mas o servidor declara charset errado (ISO-8859-1).
  utf8_bytes <- charToRaw(enc2utf8(
    '{"hits":{"hits":[{"_id":"a","_index":"x","_source":{"classe":"Execução"},"sort":["a"]}]}}'
  ))
  resp <- httr2::response(
    status_code = 200,
    headers = list("Content-Type" = "application/json; charset=ISO-8859-1"),
    body = utf8_bytes
  )

  res <- httr2::with_mocked_responses(
    list(resp),
    datajud_search(cfg, build_query(query_match_all()), page_size = 2, verbose = FALSE)
  )

  expect_equal(res$classe, "Execução")
  expect_equal(Encoding(res$classe), "UTF-8")
})

test_that("400 errors surface the Elasticsearch reason", {
  cfg <- datajud_config("elastic", indice = "datamart", usuario = "u", senha = "s")

  err_resp <- httr2::response(
    status_code = 400,
    headers = list("Content-Type" = "application/json"),
    body = charToRaw(jsonlite::toJSON(list(
      error = list(reason = "No mapping found for [id.keyword] in order to sort on")
    ), auto_unbox = TRUE))
  )

  expect_error(
    httr2::with_mocked_responses(
      list(err_resp),
      datajud_count(cfg, build_query(query_match_all()))
    ),
    "No mapping found for \\[id.keyword\\]"
  )
})

test_that("datajud_count reads hits.total.value", {
  cfg <- datajud_config("elastic", indice = "datamart", usuario = "u", senha = "s")
  resp <- json_response(list(hits = list(total = list(value = 4321))))

  total <- httr2::with_mocked_responses(
    list(resp),
    datajud_count(cfg, build_query(query_match_all()))
  )
  expect_equal(total, 4321)
})
