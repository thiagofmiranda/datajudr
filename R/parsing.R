#' @keywords internal
extract_source <- function(results) {

  if (length(results) == 0) {
    return(tibble::tibble())
  }

  purrr::map(results, function(page) {
    purrr::map(page, function(hit) {
      source_to_row(hit$`_source`)
    }) |> dplyr::bind_rows()
  }) |> dplyr::bind_rows()

}

#' @keywords internal
extract_hits <- function(results) {

  if (length(results) == 0) {
    return(tibble::tibble())
  }

  purrr::map(results, function(page) {
    purrr::map(page, function(hit) {

      source <- source_to_row(hit$`_source`)

      tibble::tibble(
        id    = hit$`_id`,
        index = hit$`_index`,
        sort  = list(hit$sort)
      ) |>
        dplyr::bind_cols(source)

    }) |> dplyr::bind_rows()
  }) |> dplyr::bind_rows()

}

#' @keywords internal
source_to_row <- function(source) {

  source <- lapply(source, function(x) {
    if (length(x) == 1) x else list(x)
  })

  tibble::as_tibble(source)

}
