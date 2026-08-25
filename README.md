# datajudr <img src="man/figures/logo.png" align="right" height="139" alt="" />

> Cliente R para o DataJud (CNJ): API pública, API Elastic (dados brutos e Datamart) e Painel de Estatística

<!-- badges: start -->
[![R-CMD-check](https://github.com/thiagofmiranda/datajudr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/thiagofmiranda/datajudr/actions/workflows/R-CMD-check.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

**datajudr** fornece funções para consultar e baixar dados de processos judiciais da plataforma [DataJud](https://datajud-wiki.cnj.jus.br/) do Conselho Nacional de Justiça (CNJ). O pacote acessa **duas APIs de consulta** com a mesma interface, mais o download público do Painel de Estatística:

| Acesso (`fonte=`) | Autenticação | Índices (`indice=`) | O que traz |
|---|---|---|---|
| `"publica"` *(padrão)* | Chave pública (**APIKey**) | — | [API pública](https://datajud-wiki.cnj.jus.br/api-publica/): capas e movimentos, apenas não sigilosos |
| `"elastic"` | Usuário e senha (**Basic Auth**) | `"processos"` | [`view-processos-sigilo-*`](https://datajud-wiki.cnj.jus.br/para-tribunais/Datajud/Api-elastic/): dados brutos, inclui sigilosos |
| `"elastic"` | Usuário e senha (**Basic Auth**) | `"datamart"` | [`datamart-*`](https://datajud-wiki.cnj.jus.br/para-tribunais/Datajud/tag-datamart/): metadados agregados planos |

Além disso, a função `download_bi()` baixa o **Painel de Estatística do CNJ** — dados **públicos, sem login**, independentes das APIs acima.

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
| **Busca** | `datajud_search()`, `datajud_count()`, `datajud_estimate_download()`, `datajud_aggregate()` |
| **Processos (API pública)** | `processos()`, `processo_por_numero()`, `processos_por_classe()`, `processos_por_data()`, `processos_busca()` |
| **Processos brutos (Elastic)** | ⭐ **`processos_brutos()`** (principal), `processos_brutos_por_numero()`, `processos_brutos_por_classe()`, `processos_brutos_por_data()`, `processos_brutos_sigilosos()` |
| **Datamart** | `datamart_sigilosos()`, `datamart_criminais()`, `datamart_por_situacao()` |
| **Construtores de query** | `build_query()`, `query_match()`, `query_term()`, `query_terms()`, `query_range()`, `query_bool()`, `query_match_all()` |
| **Agregações** | `agg_terms()`, `agg_stats()` |
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

## Elastic: dados brutos e Datamart

A API `elastic` acessa dados restritos a tribunais via Basic Auth. Dentro dela você escolhe o **índice** com `indice=`. Defina as credenciais no `.Renviron`:

```r
DATAJUD_USER=seu_usuario
DATAJUD_PWD=sua_senha
```

E selecione a fonte e o índice na configuração — o restante da API (busca, paginação, download) é idêntico:

```r
# Dados brutos de processos (view-processos-sigilo-*) — inclui sigilosos
cfg_proc <- datajud_config(fonte = "elastic", indice = "processos")

# Datamart (datamart-*) — metadados agregados planos
cfg_dm   <- datajud_config(fonte = "elastic", indice = "datamart")
```

### Dados brutos: `processos_brutos()` ⭐

`processos_brutos()` é a **função principal** para baixar dados brutos: informe **o campo** (`variavel`) e **uma lista de valores** (`valores`), e ela traz todos os processos que casam com qualquer um deles (consulta `terms`/OR). Por não fixar índice, funciona em qualquer fonte.

```r
cfg_proc <- datajud_config(fonte = "elastic", indice = "processos")

# Vários processos de uma vez, pelo número no esquema bruto do CNJ
processos_brutos(
  cfg_proc,
  variavel = "dadosBasicos.numero",
  valores  = c("00201597020148140401", "00201597020148140402")
)
```

Para os filtros mais comuns há atalhos prontos: `processos_brutos_por_numero()`, `processos_brutos_por_classe()`, `processos_brutos_por_data()` e `processos_brutos_sigilosos()`.

### Datamart: metadados agregados

O Datamart traz um documento plano por processo (situação, fase, sigilo, criminal, datas). Há atalhos e suporte a agregações:

```r
# Processos sigilosos em tramitação
sigilosos <- datamart_sigilosos(cfg_dm, id_situacao_atual = 25, sigilo_min = 1)

# Contagem por situação atual (agregação → tibble)
por_situacao <- datamart_por_situacao(cfg_dm)

# Agregação manual
body <- build_query(
  query_range("sigilo", gte = 1),
  aggs = agg_terms("por_situacao", "situacao_atual"),
  size = 0
)
datajud_aggregate(cfg_dm, body)
```

Veja a vignette *Dados brutos (API Elastic) e Datamart* para mais exemplos.

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

## Download do Painel de Estatística do CNJ (público)

O CNJ disponibiliza indicadores agregados de toda a Justiça brasileira no Painel de Estatística. Esses dados são **públicos e não exigem login** — `download_bi()` é independente de `datajud_config()`:

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
- **Dados brutos (API Elastic) e Datamart** — fontes restritas a tribunais, sigilosos e agregações
- **Download de Dados do BI do CNJ** — Painel de Estatística do CNJ (indicadores agregados, público)

```r
vignette("introducao-api",         package = "datajudr")
vignette("dados-brutos-datamart",  package = "datajudr")
vignette("download-bi",            package = "datajudr")
```

## Sobre o DataJud

O [DataJud](https://datajud-wiki.cnj.jus.br/) é a base nacional de dados do Poder Judiciário, mantida pelo CNJ. Reúne informações de processos judiciais de todos os tribunais do país e disponibiliza, além da API pública, o acesso via Elasticsearch (dados brutos e o Datamart de metadados agregados, restritos a tribunais) e o Painel de Estatística público.

## Licença

MIT © Thiago Miranda
