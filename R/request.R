library(httr2)
library(ratelimitr)
library(jsonlite)

.datajud_request_raw <- function(cfg, body){
  
  json_body <- jsonlite::toJSON(
    body,
    auto_unbox = TRUE,
    null = "null"
  )
  
  req <- request(cfg$endpoint) |>
    req_method("POST") |>
    req_headers(
      Authorization = paste("APIKey", cfg$api_key),
      `Content-Type` = "application/json"
    ) |>
    req_body_raw(json_body)
  
  resp <- req_perform(req)
  
  resp_body_json(resp)
  
}

datajud_request <- ratelimitr::limit_rate(
  .datajud_request_raw,
  rate = ratelimitr::rate(n = 120, period = 60)
)