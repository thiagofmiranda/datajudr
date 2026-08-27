test_that("source_to_row turns null API fields into NA, not list columns", {
  row <- source_to_row(list(numero = "123", classe = 279L, sigilo = NULL))

  expect_s3_class(row, "tbl_df")
  expect_true(is.na(row$sigilo))
  # campo null nao deve virar list column (isso quebra o bind_rows depois)
  expect_false(is.list(row$sigilo))
})

test_that("extract_source binds rows when a field is null in only some hits", {
  # regressao: campo presente numa linha e null em outra costumava quebrar
  # bind_rows com 'Can't combine <list> and <integer>'
  results <- list(list(
    list(`_source` = list(numero = "123", sigilo = 1L)),
    list(`_source` = list(numero = "456", sigilo = NULL))
  ))

  out <- extract_source(results)

  expect_equal(nrow(out), 2)
  expect_equal(out$sigilo, c(1L, NA))
})

test_that("extract_source returns an empty tibble when there are no results", {
  expect_equal(nrow(extract_source(list())), 0)
})
