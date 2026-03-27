#' Download bulk BI data from DataJud
#'
#' Downloads CSV data from the CNJ BI download API and returns a named list
#' of dataframes, one per indicator found in the response.
#'
#' @param tribunal Character. Tribunal code (e.g. `"TJAP"`).
#' @param indicador Character. Indicator code (e.g. `"ind3"`). Required when
#'   using filters (`oj`, `grau`, `municipio`).
#' @param oj Character. Orgao julgador code.
#' @param grau Character. Degree (e.g. `"G1"`, `"G2"`).
#' @param municipio Character. Municipality code.
#' @param ambiente Character. Environment (`"csv_p"` for production).
#' @param referencia Character. Reference period in `"YYYY/MM"` format (e.g.
#'   `"2026/01"`). Required when `output_dir` is provided.
#' @param output_dir Character or NULL. Directory to save Parquet files. If
#'   provided, `referencia` is mandatory.
#' @param verbose Logical. Print progress messages.
#'
#' @return A named list of dataframes, one per indicator.
#' @export
download_bi <- function(tribunal,
                        indicador = "",
                        oj = "",
                        grau = "",
                        municipio = "",
                        ambiente = "csv_p",
                        referencia = NULL,
                        output_dir = NULL,
                        verbose = TRUE) {

  tribunal <- toupper(tribunal)

  bi_base_url <- Sys.getenv(
    "DATAJUD_BI_BASE_URL",
    "https://api-csvr.cloud.cnj.jus.br/download_csv"
  )

  # Salvar exige referencia obrigatoria
  if (!is.null(output_dir) && is.null(referencia)) {
    stop(
      "O parametro `referencia` e obrigatorio ao salvar os dados.\n",
      "Exemplo: download_bi(tribunal = \"TJAP\", referencia = \"2026/01\", output_dir = \"dados_bi\")"
    )
  }

  # Validar formato de referencia
  if (!is.null(referencia) && !grepl("^\\d{4}/\\d{2}$", referencia)) {
    stop(
      "O parametro `referencia` deve estar no formato \"YYYY/MM\" (ex: \"2026/01\")."
    )
  }

  # Filtros exigem indicador obrigatorio
  usando_filtro <- nchar(oj) > 0 || nchar(grau) > 0 || nchar(municipio) > 0
  if (usando_filtro && nchar(indicador) == 0) {
    stop(
      "O parametro `indicador` e obrigatorio ao usar filtros (oj, grau, municipio).\n",
      "Exemplo: download_bi(tribunal = \"TJAP\", indicador = \"ind3\", grau = \"G1\")"
    )
  }

  req <- httr2::request(bi_base_url) |>
    httr2::req_url_query(
      tribunal  = tribunal,
      indicador = indicador,
      oj        = oj,
      grau      = grau,
      municipio = municipio,
      ambiente  = ambiente
    ) |>
    httr2::req_error(body = function(resp) {
      status <- httr2::resp_status(resp)
      switch(as.character(status),
        "404" = "Endpoint nao encontrado. Verifique o codigo do tribunal ou indicador.",
        "429" = "Rate limit excedido. Aguarde antes de tentar novamente.",
        "500" = "Erro interno do servidor DataJud. Tente novamente mais tarde.",
        paste0("Erro da API DataJud BI (HTTP ", status, ").")
      )
    })

  if (verbose) {
    message("Baixando dados BI: ", tribunal, " [", ambiente, "]")
  }

  resp <- httr2::req_perform(req)

  content_type <- httr2::resp_content_type(resp)
  raw_bytes    <- httr2::resp_body_raw(resp)

  # ---- ZIP com multiplos CSVs ----
  is_zip <- grepl("zip", content_type, ignore.case = TRUE) ||
            identical(raw_bytes[1:2], charToRaw("PK"))

  if (is_zip) {

    tmp_zip <- tempfile(fileext = ".zip")
    tmp_dir <- tempfile()

    on.exit({
      unlink(tmp_zip)
      unlink(tmp_dir, recursive = TRUE)
    }, add = TRUE)

    writeBin(raw_bytes, tmp_zip)
    utils::unzip(tmp_zip, exdir = tmp_dir)

    csv_files <- list.files(tmp_dir, pattern = "\\.csv$",
                            full.names = TRUE, recursive = TRUE)

    if (length(csv_files) == 0) {
      stop("Nenhum CSV encontrado dentro do arquivo ZIP.")
    }

    nomes <- tools::file_path_sans_ext(basename(csv_files))

    result <- purrr::map(csv_files, function(f) {
      readr::read_csv2(
        f,
        show_col_types = FALSE,
        locale = readr::locale(
          decimal_mark  = ",",
          grouping_mark = ".",
          encoding      = "UTF-8"
        )
      )
    })

    names(result) <- nomes

  # ---- CSV simples ----
  } else {

    nome <- if (nchar(indicador) > 0) {
      paste0(tribunal, "_", indicador)
    } else {
      tribunal
    }

    df <- readr::read_csv2(
      raw_bytes,
      show_col_types = FALSE,
      locale = readr::locale(
        decimal_mark  = ",",
        grouping_mark = ".",
        encoding      = "UTF-8"
      )
    )

    result <- stats::setNames(list(df), nome)

  }

  if (verbose) {
    purrr::iwalk(result, function(df, nome) {
      message(
        "  [", nome, "] ",
        format(nrow(df), big.mark = ",", scientific = FALSE), " linhas x ",
        ncol(df), " colunas"
      )
    })
  }

  # ---- Salvar em Parquet ----
  if (!is.null(output_dir)) {

    pasta <- file.path(output_dir, referencia)
    dir.create(pasta, showWarnings = FALSE, recursive = TRUE)

    purrr::iwalk(result, function(df, nome) {
      file_path <- file.path(pasta, paste0(tolower(nome), ".parquet"))
      arrow::write_parquet(df, file_path)
      if (verbose) message("  Salvo: ", file_path)
    })

  }

  invisible(result)

}
