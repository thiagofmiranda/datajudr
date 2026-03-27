library(httr2)
library(readr)

.BI_BASE_URL <- Sys.getenv("DATAJUD_BI_BASE_URL", "https://api-csvr.cloud.cnj.jus.br/download_csv")

download_bi <- function(tribunal,
                        indicador = "",
                        oj = "",
                        grau = "",
                        municipio = "",
                        ambiente = "csv_p",
                        referencia = NULL,
                        output_dir = NULL,
                        verbose = TRUE){

  tribunal <- toupper(tribunal)

  # Salvar exige referencia obrigatoria
  if(!is.null(output_dir) && is.null(referencia)){
    stop(
      "O parametro `referencia` e obrigatorio ao salvar os dados.\n",
      "Exemplo: download_bi(tribunal = \"TJAP\", referencia = \"2026/01\", output_dir = \"dados_bi\")"
    )
  }

  # Filtros exigem indicador obrigatorio
  usando_filtro <- nchar(oj) > 0 || nchar(grau) > 0 || nchar(municipio) > 0
  if(usando_filtro && nchar(indicador) == 0){
    stop(
      "O parametro `indicador` e obrigatorio ao usar filtros (oj, grau, municipio).\n",
      "Exemplo: download_bi(tribunal = \"TJAP\", indicador = \"ind3\", grau = \"G1\")"
    )
  }

  req <- request(.BI_BASE_URL) |>
    req_url_query(
      tribunal  = tribunal,
      indicador = indicador,
      oj        = oj,
      grau      = grau,
      municipio = municipio,
      ambiente  = ambiente
    )

  if(verbose){
    message("Baixando dados BI: ", tribunal, " [", ambiente, "]")
  }

  resp <- req_perform(req)

  content_type <- resp_content_type(resp)
  raw_bytes    <- resp_body_raw(resp)

  # ---- ZIP com multiplos CSVs ----
  is_zip <- grepl("zip", content_type, ignore.case = TRUE) ||
            identical(raw_bytes[1:2], charToRaw("PK"))

  if(is_zip){

    tmp_zip <- tempfile(fileext = ".zip")
    tmp_dir <- tempfile()

    writeBin(raw_bytes, tmp_zip)
    utils::unzip(tmp_zip, exdir = tmp_dir)

    csv_files <- list.files(tmp_dir, pattern = "\\.csv$",
                            full.names = TRUE, recursive = TRUE)

    if(length(csv_files) == 0){
      stop("Nenhum CSV encontrado dentro do arquivo ZIP.")
    }

    # Nome de cada elemento = nome do arquivo sem extensao
    nomes <- tools::file_path_sans_ext(basename(csv_files))

    result <- purrr::map(csv_files, function(f){
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

    unlink(tmp_zip)
    unlink(tmp_dir, recursive = TRUE)

  # ---- CSV simples ----
  } else {

    nome <- if(nchar(indicador) > 0) {
      paste0(tribunal, "_", indicador)
    } else {
      tribunal
    }

    df <- readr::read_csv2(
      I(rawToChar(raw_bytes)),
      show_col_types = FALSE,
      locale = readr::locale(
        decimal_mark  = ",",
        grouping_mark = ".",
        encoding      = "UTF-8"
      )
    )

    result <- stats::setNames(list(df), nome)

  }

  if(verbose){
    purrr::iwalk(result, function(df, nome){
      message(
        "  [", nome, "] ",
        format(nrow(df), big.mark = ",", scientific = FALSE), " linhas x ",
        ncol(df), " colunas"
      )
    })
  }

  # ---- Salvar em Parquet ----
  if(!is.null(output_dir)){

    pasta <- file.path(output_dir, referencia)
    dir.create(pasta, showWarnings = FALSE, recursive = TRUE)

    purrr::iwalk(result, function(df, nome){
      file_path <- file.path(pasta, paste0(tolower(nome), ".parquet"))
      arrow::write_parquet(df, file_path)
      if(verbose) message("  Salvo: ", file_path)
    })

  }

  invisible(result)

}
