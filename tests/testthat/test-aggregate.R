test_that("parse_aggregation turns terms buckets into a tidy tibble", {
  agg <- list(buckets = list(
    list(key = "Em tramitacao", doc_count = 120),
    list(key = "Baixado",       doc_count = 45)
  ))
  res <- parse_aggregation(agg)
  expect_s3_class(res, "tbl_df")
  expect_equal(res$key, c("Em tramitacao", "Baixado"))
  expect_equal(res$doc_count, c(120, 45))
})

test_that("parse_aggregation flattens metric (stats) aggregations", {
  agg <- list(count = 10, min = 0, max = 3, avg = 1.5, sum = 15)
  res <- parse_aggregation(agg)
  expect_s3_class(res, "tbl_df")
  expect_equal(res$count, 10)
  expect_equal(res$avg, 1.5)
})

test_that("datajud_aggregate requires an aggs clause", {
  cfg <- datajud_config("elastic", indice = "datamart", usuario = "u", senha = "s")
  expect_error(
    datajud_aggregate(cfg, build_query(query_match_all())),
    "aggs"
  )
})
