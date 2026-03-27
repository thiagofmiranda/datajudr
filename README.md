# datajudr <img src="man/figures/logo.png" align="right" height="139" alt="" />

> Cliente R para a API pública do DataJud (CNJ)

<!-- badges: start -->
[![R-CMD-check](https://github.com/thiagofmiranda/datajudr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/thiagofmiranda/datajudr/actions/workflows/R-CMD-check.yaml)
[![CRAN status](https://www.r-pkg.org/badges/version/datajudr)](https://CRAN.R-project.org/package=datajudr)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

**datajudr** fornece funções para consultar e baixar dados de processos judiciais da plataforma [DataJud](https://datajud-wiki.cnj.jus.br/) do Conselho Nacional de Justiça (CNJ), por meio da sua API pública Elasticsearch e dos endpoints de download do BI.

## Instalação

```r
# Versão de desenvolvimento (GitHub)
# install.packages("remotes")
remotes::install_github("thiagofmiranda/datajudr")
```

## Início rápido

```r
library(datajudr)

# Configurar acesso (usa chave pública do CNJ por padrão)
cfg <- datajud_config(tribunal = "tjsp")

# Buscar processos por número
processo <- processo_por_numero(cfg, "0000001-02.2020.8.26.0001")

# Buscar processos por classe
habeas <- processos_por_classe(cfg, "Habeas Corpus", max_pages = 2)

# Buscar por período
recentes <- processos_por_data(cfg, "2024-01-01", "2024-03-31")
```

## Funcionalidades

| Categoria | Funções |
|---|---|
| **Configuração** | `datajud_config()` |
| **Busca** | `datajud_search()`, `datajud_count()`, `datajud_estimate_download()` |
| **Endpoints de processo** | `processos()`, `processo_por_numero()`, `processos_por_classe()`, `processos_por_data()`, `processos_busca()` |
| **Construtores de query** | `build_query()`, `query_match()`, `query_term()`, `query_range()`, `query_bool()`, `query_match_all()` |
| **Download em lote** | `download_processos()`, `download_bi()` |

## Configuração

Por padrão, o pacote usa a chave pública do CNJ sem necessidade de cadastro. Para usar credenciais próprias, defina as variáveis de ambiente no `.Renviron`:

```r
DATAJUD_API_KEY=sua_chave_aqui
DATAJUD_BASE_URL=https://api-publica.datajud.cnj.jus.br
```

O tribunal é informado na criação do `cfg`:

```r
cfg <- datajud_config(tribunal = "tjsp")  # Tribunal de Justiça de São Paulo
cfg <- datajud_config(tribunal = "trf1")  # TRF da 1ª Região
```

## Queries personalizadas (Elasticsearch DSL)

O pacote inclui um conjunto de construtores para compor queries Elasticsearch complexas:

```r
cfg <- datajud_config(tribunal = "tjsp")

# Query booleana com filtro de classe e intervalo de datas
query <- build_query(
  query_bool(
    must = query_match("classe.nome", "Habeas Corpus"),
    filter = query_range("dataAjuizamento", gte = "2023-01-01", lte = "2023-12-31")
  )
)

resultado <- datajud_search(cfg, body = query, max_pages = 5)
```

## Estimativa de download

Antes de baixar grandes volumes de dados, use `datajud_estimate_download()` para avaliar o tamanho da extração:

```r
cfg <- datajud_config(tribunal = "tjsp")

estimativa <- datajud_estimate_download(cfg, body = build_query(query_match_all()))
print(estimativa)
#> Estimativa de download:
#>   Total de documentos : 15.234.789
#>   Tamanho da página   : 1.000
#>   Número de páginas   : 15.235
```

## Download em lote (Parquet)

Para extrações grandes, `download_processos()` salva os resultados em arquivos Parquet por lote, evitando estouro de memória:

```r
cfg <- datajud_config(tribunal = "tjsp")

query <- build_query(
  query_range("dataAjuizamento", gte = "2024-01-01", lte = "2024-12-31")
)

download_processos(
  cfg,
  body       = query,
  output_dir = "dados/tjsp",
  batch_pages = 10,
  verbose    = TRUE
)
```

## Download de dados do BI do CNJ

O CNJ disponibiliza indicadores agregados de toda a justiça brasileira. Use `download_bi()` para acessá-los:

```r
# Carga pendente de todos os tribunais
download_bi(
  tribunal  = "all",
  indicador = "CPL",
  output_dir = "dados/bi"
)
```

Indicadores disponíveis:

| Indicador | Descrição |
|---|---|
| `CPL` | Carga pendente de processos |
| `CPL_15anos` | Carga pendente — processos com mais de 15 anos |
| `Sent` | Sentenças proferidas |
| `TBaix` | Taxa de baixamento |
| `CN` | Casos novos |
| `tbl_correg` | Dados de corregedoria |

## Rate limiting

O pacote aplica automaticamente rate limiting de **120 requisições por minuto**, respeitando os limites da API pública do CNJ.

## Vignettes

- **Introdução à API do DataJud** — busca, paginação, queries personalizadas e download em Parquet
- **Download de Dados do BI do CNJ** — acesso aos indicadores agregados do CNJ

```r
vignette("introducao-api", package = "datajudr")
vignette("download-bi",    package = "datajudr")
```

## Sobre o DataJud

O [DataJud](https://datajud-wiki.cnj.jus.br/) é a base nacional de dados do Poder Judiciário, mantida pelo CNJ. Reúne informações de processos judiciais de todos os tribunais do país e disponibiliza uma API pública baseada em Elasticsearch para consulta dos dados.

## Licença

MIT © Thiago Miranda
