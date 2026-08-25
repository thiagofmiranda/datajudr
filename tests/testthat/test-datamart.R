dm_json <- function(obj) {
  httr2::response(
    status_code = 200,
    headers = list("Content-Type" = "application/json"),
    body = charToRaw(jsonlite::toJSON(obj, auto_unbox = TRUE, null = "null"))
  )
}

test_that("datamart_por_situacao returns a tidy tibble of buckets", {
  cfg <- datajud_config("elastic", indice = "datamart", usuario = "u", senha = "s")

  resp <- dm_json(list(aggregations = list(
    por_situacao = list(buckets = list(
      list(key = "Em tramitacao", doc_count = 100),
      list(key = "Baixado",       doc_count = 40)
    ))
  )))

  res <- httr2::with_mocked_responses(
    list(resp),
    datamart_por_situacao(cfg)
  )

  expect_s3_class(res, "tbl_df")
  expect_equal(res$key, c("Em tramitacao", "Baixado"))
  expect_equal(res$doc_count, c(100, 40))
})

test_that("datamart_sigilosos filters by sigilo and situation", {
  cfg <- datajud_config("elastic", indice = "datamart", usuario = "u", senha = "s")

  page1 <- dm_json(list(hits = list(hits = list(
    list(`_id` = "a", `_source` = list(id = "a", sigilo = 2), sort = list("a"))
  ))))
  page2 <- dm_json(list(hits = list(hits = list())))

  res <- httr2::with_mocked_responses(
    list(page1, page2),
    datamart_sigilosos(cfg, verbose = FALSE)
  )

  expect_equal(nrow(res), 1)
  expect_equal(res$sigilo, 2)
})

test_that("datamart helpers warn when used on the wrong source/index", {
  cfg_pub  <- datajud_config(tribunal = "tjsp")
  cfg_proc <- datajud_config("elastic", usuario = "u", senha = "s")
  expect_warning(check_indice_datamart(cfg_pub),  "datamart")
  expect_warning(check_indice_datamart(cfg_proc), "datamart")
})
