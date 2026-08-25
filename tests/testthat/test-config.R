test_that("fonte publica keeps backward-compatible defaults", {
  cfg <- datajud_config(tribunal = "tjsp")
  expect_equal(cfg$fonte, "publica")
  expect_true(is.na(cfg$indice))
  expect_equal(cfg$auth$type, "apikey")
  expect_equal(cfg$sort, "@timestamp")
  expect_match(cfg$endpoint, "api_publica_tjsp/_search$")
  expect_match(cfg$endpoint, "^https://api-publica\\.datajud\\.cnj\\.jus\\.br/")
})

test_that("fonte elastic defaults to the processos index (basic auth)", {
  cfg <- datajud_config("elastic", usuario = "u", senha = "s")
  expect_equal(cfg$fonte, "elastic")
  expect_equal(cfg$indice, "processos")
  expect_equal(cfg$auth$type, "basic")
  expect_equal(cfg$auth$usuario, "u")
  expect_equal(cfg$sort, "id.keyword")
  expect_equal(
    cfg$endpoint,
    "https://api.datajud.cnj.jus.br/view-processos-sigilo-*/_search"
  )
})

test_that("fonte elastic with indice datamart resolves the datamart index", {
  cfg <- datajud_config("elastic", indice = "datamart", usuario = "u", senha = "s")
  expect_equal(cfg$indice, "datamart")
  expect_equal(cfg$auth$type, "basic")
  expect_equal(cfg$sort, "id")
  expect_equal(
    cfg$endpoint,
    "https://api.datajud.cnj.jus.br/datamart-*/_search"
  )
})

test_that("elastic requires credentials", {
  withr::local_envvar(DATAJUD_USER = "", DATAJUD_PWD = "")
  expect_error(datajud_config("elastic"), "Basic Auth")
  expect_error(datajud_config("elastic", indice = "datamart"), "Basic Auth")
})

test_that("index can be overridden (e.g. tribunal-specific datamart)", {
  cfg <- datajud_config("elastic", indice = "datamart", usuario = "u", senha = "s",
                        index = "datamart-tjsp")
  expect_match(cfg$endpoint, "datamart-tjsp/_search$")
})

test_that("default_sort follows the source/index", {
  pub  <- datajud_config(tribunal = "tjsp")
  proc <- datajud_config("elastic", usuario = "u", senha = "s")
  dm   <- datajud_config("elastic", indice = "datamart", usuario = "u", senha = "s")
  expect_equal(names(default_sort(pub)[[1]]),  "@timestamp")
  expect_equal(names(default_sort(proc)[[1]]), "id.keyword")
  expect_equal(names(default_sort(dm)[[1]]),   "id")
})
