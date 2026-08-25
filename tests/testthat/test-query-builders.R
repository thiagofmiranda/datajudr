test_that("query builders produce the documented DSL", {
  expect_equal(query_term("id_situacao_atual", 25),
               list(term = list(id_situacao_atual = 25)))
  expect_equal(query_terms("id_situacao_atual", c(25, 30)),
               list(terms = list(id_situacao_atual = list(25, 30))))
  expect_equal(query_range("sigilo", gte = 1),
               list(range = list(sigilo = list(gte = 1))))
})

test_that("build_query attaches aggs and size when provided", {
  body <- build_query(query_match_all())
  expect_named(body, "query")

  body <- build_query(
    query_range("sigilo", gte = 1),
    aggs = agg_terms("por_situacao", "situacao_atual"),
    size = 0
  )
  expect_equal(body$size, 0)
  expect_equal(
    body$aggs,
    list(por_situacao = list(terms = list(field = "situacao_atual", size = 100)))
  )
})

test_that("agg builders match the Datamart aggregation example", {
  expect_equal(
    agg_terms("por_situacao", "situacao_atual", size = 100),
    list(por_situacao = list(terms = list(field = "situacao_atual", size = 100)))
  )
  expect_equal(
    agg_stats("stats_sigilo", "sigilo"),
    list(stats_sigilo = list(stats = list(field = "sigilo")))
  )
})
