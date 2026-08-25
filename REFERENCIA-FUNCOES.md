# Referência de Funções — `datajudr`

Guia de todas as funções voltadas ao usuário, na ordem em que aparecem num fluxo
de trabalho real: **login/configuração → montagem da consulta → busca/contagem/
agregação → atalhos prontos → download em lote**.

## Índice

1. [Fluxo geral](#1-fluxo-geral)
2. [Login e configuração](#2-login-e-configuração) — `datajud_config()`
3. [Construtores de consulta (Elasticsearch DSL)](#3-construtores-de-consulta-elasticsearch-dsl) — `query_*`, `build_query()`, `agg_*`
4. [Busca, contagem e agregação](#4-busca-contagem-e-agregação) — `datajud_search()`, `datajud_count()`, `datajud_estimate_download()`, `datajud_aggregate()`
5. [Atalhos de processo (API pública)](#5-atalhos-de-processo-api-pública) — `processos*`
6. [Processos brutos (índice Elastic)](#6-processos-brutos-índice-elastic) — ⭐ **`processos_brutos()`**, `processos_brutos_*`
7. [Funções do Datamart](#7-funções-do-datamart) — `datamart_*`
8. [Download em lote](#8-download-em-lote) — `download_processos()`, `download_bi()`
9. [Tabela-resumo](#9-tabela-resumo)

---

## 1. Fluxo geral

```
                       ┌───────────────────────────────────────────────┐
  datajud_config()  →  │ cfg (fonte + endpoint + auth + sort)           │
   (login/fonte)       └───────────────────────────────────────────────┘
                                        │
      query_* + build_query()  →  body (consulta Elasticsearch)
                                        │
        ┌───────────────┬───────────────┼────────────────┬─────────────────┐
        ▼               ▼               ▼                ▼                 ▼
  datajud_search   datajud_count  datajud_aggregate  download_processos  atalhos
   (tibble)         (total)        (buckets)          (Parquet)          (processos_*,
                                                                          datamart_*)
```

Praticamente tudo recebe **`cfg`** (o objeto de configuração) como primeiro
argumento. A única exceção é `download_bi()`, que acessa o Painel de Estatística
do CNJ (público) e **não** depende de login.

---

## 2. Login e configuração

### `datajud_config()`

Cria o objeto `cfg` que carrega **qual fonte** de dados usar, o **endpoint**, o
**tipo de autenticação** e o **campo de ordenação** para paginação. É o ponto de
partida de quase todas as funções.

```r
datajud_config(
  fonte      = c("publica", "elastic"),
  indice     = c("processos", "datamart"),   # só para fonte = "elastic"
  tribunal   = "TJAP",
  api_key    = Sys.getenv("DATAJUD_API_KEY", <chave pública do CNJ>),
  usuario    = Sys.getenv("DATAJUD_USER"),
  senha      = Sys.getenv("DATAJUD_PWD"),
  base_url   = NULL,
  index      = NULL,
  rate_limit = 120
)
```

**Há dois modos de acesso** (`fonte`). A API pública usa chave; a API Elastic usa
usuário e senha e, dentro dela, você escolhe o **índice** (`indice`):

| `fonte` | `indice` | Índice real | Autenticação | Acesso | Ordenação (interno) |
|---|---|---|---|---|---|
| `"publica"` *(padrão)* | — | `api_publica_<tribunal>` | **APIKey** (chave pública) | Público, só não sigilosos | `@timestamp` |
| `"elastic"` | `"processos"` *(padrão)* | `view-processos-sigilo-*` | **Basic Auth** (usuário/senha) | Restrito a tribunais, inclui sigilosos | `id.keyword` |
| `"elastic"` | `"datamart"` | `datamart-*` | **Basic Auth** (usuário/senha) | Restrito a tribunais | `id` |

> O download do **Painel de Estatística** (`download_bi()`) é **público, sem
> login** e não usa `datajud_config()` — veja a seção 8.

**Parâmetros principais**

- `fonte` — o modo de acesso: `"publica"` (chave, sem cadastro) ou `"elastic"`
  (usuário/senha fornecidos pelo tribunal).
- `indice` — só vale para `fonte = "elastic"`: `"processos"` (dados brutos) ou
  `"datamart"` (metadados agregados).
- `tribunal` — código do tribunal (ex.: `"TJSP"`, `"TRF1"`); usado para montar o
  índice da API pública.
- `usuario` / `senha` — credenciais **Basic Auth** da API Elastic. O ideal é
  defini-las no `.Renviron` (`DATAJUD_USER`, `DATAJUD_PWD`) e não no código.
- `base_url` / `index` — sobrescritas opcionais (ex.: apontar para
  `datamart-tjsp` específico em vez do curinga `datamart-*`).
- `rate_limit` — teto de requisições por minuto (padrão 120, o limite da API
  pública). Use `Inf` para desativar.

**Retorno:** uma lista com `fonte`, `indice`, `tribunal`, `endpoint`, `auth`,
`sort` e `rate_limit`.

```r
# API pública (padrão) — sem credenciais
cfg <- datajud_config(tribunal = "TJSP")

# Elastic + Datamart (Basic Auth via .Renviron: DATAJUD_USER / DATAJUD_PWD)
cfg_dm <- datajud_config(fonte = "elastic", indice = "datamart")

# Elastic + dados brutos de processos (inclui sigilosos)
cfg_proc <- datajud_config(fonte = "elastic", indice = "processos")
```

> Se as credenciais Basic Auth estiverem faltando para `fonte = "elastic"`, a
> função falha imediatamente com uma mensagem clara — antes de qualquer chamada
> à rede.

---

## 3. Construtores de consulta (Elasticsearch DSL)

Estas funções montam pedaços da consulta no formato do Elasticsearch, sem você
precisar escrever JSON à mão. Todas retornam **listas** que se encaixam umas nas
outras.

### `query_match(field, value)`
Busca textual (full-text) num campo. Útil para nomes/descrições.
```r
query_match("classe.nome", "Habeas Corpus")
#> {"match": {"classe.nome": "Habeas Corpus"}}
```

### `query_term(field, value)`
Correspondência **exata** de um valor (não analisa o texto). Ideal para
códigos, números e booleanos.
```r
query_term("id_situacao_atual", 25)
#> {"term": {"id_situacao_atual": 25}}
```

### `query_terms(field, values)`
Como `query_term`, mas casa com **qualquer um** de vários valores (OR lógico).
```r
query_terms("id_situacao_atual", c(25, 30))
#> {"terms": {"id_situacao_atual": [25, 30]}}
```

### `query_range(field, gte = NULL, lte = NULL)`
Intervalo numérico ou de datas. `gte` = maior ou igual, `lte` = menor ou igual
(informe ao menos um).
```r
query_range("dataAjuizamento", gte = "2024-01-01", lte = "2024-12-31")
query_range("sigilo", gte = 1)
```

### `query_match_all()`
Casa com **todos** os documentos. Ponto de partida para "trazer tudo".
```r
query_match_all()
#> {"match_all": {}}
```

### `query_bool(must, filter, should, must_not)`
Combina várias cláusulas com lógica booleana (informe ao menos uma):
- `must` — todas precisam casar (conta na relevância);
- `filter` — todas precisam casar (sem relevância, mais rápido);
- `should` — ao menos uma casa;
- `must_not` — nenhuma pode casar.
```r
query_bool(
  filter = list(
    query_range("sigilo", gte = 1),
    query_term("id_situacao_atual", 25)
  )
)
```

### `build_query(query, aggs = NULL, size = NULL)`
Empacota tudo no corpo final da requisição. É o que você passa para
`datajud_search()`, `datajud_count()` etc.
- `aggs` — agregações (ver abaixo);
- `size` — quantos documentos retornar (`0` para "só agregação, sem documentos").
```r
body <- build_query(
  query_bool(
    must   = query_match("classe.nome", "Habeas Corpus"),
    filter = query_range("dataAjuizamento", gte = "2023-01-01")
  )
)
```

### `agg_terms(name, field, size = 100)`
Agregação que **agrupa e conta** por valores distintos de um campo (ex.: contar
processos por situação). Retorna "baldes" (buckets).
```r
agg_terms("por_situacao", "situacao_atual", size = 100)
```

### `agg_stats(name, field)`
Estatísticas de um campo numérico: contagem, mínimo, máximo, média e soma.
```r
agg_stats("stats_sigilo", "sigilo")
```

---

## 4. Busca, contagem e agregação

### `datajud_search(cfg, body, page_size = 100, max_pages = Inf, verbose = TRUE, estimate = TRUE)`
Função central de busca. Pagina automaticamente com `search_after`, aplica a
ordenação correta da fonte e devolve um **tibble** com uma linha por processo.
- `page_size` — documentos por página (até 10.000);
- `max_pages` — limite de páginas (use para "espiar" sem baixar tudo);
- `verbose` — imprime o progresso das páginas;
- `estimate` — quando `verbose = TRUE`, faz uma contagem prévia e mostra a
  estimativa de download antes de baixar.
```r
resultado <- datajud_search(cfg, body, max_pages = 5)
```

### `datajud_count(cfg, body)`
Retorna apenas o **número total** de documentos que casam com a consulta (não
baixa os dados). Rápido e barato.
```r
datajud_count(cfg, build_query(query_match_all()))
#> 15234789
```

### `datajud_estimate_download(cfg, body, page_size = 100)`
Estima o tamanho da extração **antes** de baixar: total de documentos, tamanho da
página e número de páginas. Bom para dimensionar downloads grandes.
```r
est <- datajud_estimate_download(cfg, build_query(query_match_all()))
print(est)
#> Estimativa de download DataJud
#> Resultados totais:  15,234,789
#> Page size:          100
#> Total de paginas:   152,348
```

### `datajud_aggregate(cfg, body)`
Executa uma consulta de **agregação** (força `size = 0`, então não traz
documentos) e devolve os buckets como um tibble organizado. É a base das
estatísticas do Datamart.
- Com uma agregação: retorna um tibble (`key`, `doc_count`).
- Com várias: retorna uma lista nomeada de tibbles.
```r
body <- build_query(
  query_range("sigilo", gte = 1),
  aggs = agg_terms("por_situacao", "situacao_atual")
)
datajud_aggregate(cfg_dm, body)
#> # A tibble: n x 2
#>   key            doc_count
#>   <chr>              <int>
```

---

## 5. Atalhos de processo (API pública)

Funções prontas para as buscas mais comuns. Montam o `body` por você e chamam
`datajud_search()`. Todas aceitam `...` para repassar argumentos (`max_pages`,
`page_size`, `verbose`...).

> ⚠️ **Estes atalhos usam os campos da API pública** (`numeroProcesso`,
> `classe.nome`, `dataAjuizamento`). O índice `processos` do Elastic
> (`view-processos-sigilo-*`) vem no esquema bruto do CNJ (`dadosBasicos.numero`,
> `dadosBasicos.classeProcessual` — só código, etc.), então nele use os atalhos
> `processos_brutos_*` (seção 6). Exceções que valem em qualquer índice:
> `processos()` e `processos_busca()` sem filtros (usam `match_all`).

### `processos(cfg, ...)`
Traz **todos** os processos do índice (equivale a `query_match_all()`).
```r
processos(cfg, max_pages = 2)
```

### `processo_por_numero(cfg, numero_processo, ...)`
Busca por número de processo (correspondência exata).
```r
processo_por_numero(cfg, "0000001-02.2020.8.26.0001")
```

### `processos_por_classe(cfg, classe, ...)`
Filtra por nome da classe processual (busca textual).
```r
processos_por_classe(cfg, "Habeas Corpus", max_pages = 2)
```

### `processos_por_data(cfg, data_inicio, data_fim = NULL, ...)`
Filtra por intervalo de data de ajuizamento (`"YYYY-MM-DD"`).
```r
processos_por_data(cfg, "2024-01-01", "2024-03-31")
```

### `processos_busca(cfg, classe = NULL, data_inicio = NULL, data_fim = NULL, ...)`
Busca combinada: aplica os filtros que você informar (classe e/ou período). Sem
filtros, traz tudo.
```r
processos_busca(cfg, classe = "Mandado de Segurança", data_inicio = "2023-01-01")
```

---

## 6. Processos brutos (índice Elastic)

Atalhos para o índice `processos` da API Elastic (`view-processos-sigilo-*`), que
traz o documento **bruto** no esquema MTD do CNJ (`dadosBasicos.*`), diferente do
formato limpo da API pública. Exigem `cfg` com `fonte = "elastic"` e
`indice = "processos"` — se usados em outra fonte/índice, avisam. Ao contrário da
API pública, este índice **inclui processos sigilosos**.

**Campos típicos:** `dadosBasicos.numero`, `dadosBasicos.classeProcessual`
(código), `dadosBasicos.dpj_dataAjuizamento`, `dadosBasicos.nivelSigilo`,
`dadosBasicos.orgaoJulgador.codigoOrgao`, `siglaTribunal`, `movimento[]`.

### ⭐ `processos_brutos(cfg, variavel, valores, ...)` — **função principal**

A maneira mais direta e flexível de baixar dados brutos, e a **forma recomendada**
para a maioria dos casos: você escolhe **o campo** (`variavel`) e passa **um ou
mais valores** (`valores`). Por baixo monta uma consulta `terms` (OR lógico),
então uma única chamada traz todos os processos cujo `variavel` casa com
**qualquer** valor da lista.

Diferente dos atalhos `_por_*` abaixo, ela **não fixa o índice**: como você mesmo
informa o campo, funciona em qualquer fonte/índice (bruto, Datamart ou API
pública) — sem emitir aviso.

```r
cfg_proc <- datajud_config(fonte = "elastic", indice = "processos")

# Vários números de uma vez (esquema bruto: dadosBasicos.numero)
processos_brutos(
  cfg_proc,
  variavel = "dadosBasicos.numero",
  valores  = c("00201597020148140401", "00201597020148140402")
)

# Um único valor também vale
processos_brutos(cfg_proc, variavel = "dadosBasicos.numero",
                 valores = "00201597020148140401")

# Como não fixa índice, serve no Datamart escolhendo o campo daquele índice
processos_brutos(cfg_dm, variavel = "id_situacao_atual", valores = c(25, 30))
```

Equivale a:
```r
datajud_search(cfg, build_query(query_terms(variavel, valores)))
```

**Atalhos específicos** (fixam `fonte = "elastic"` / `indice = "processos"` e
avisam se usados em outra fonte/índice):

### `processos_brutos_por_numero(cfg, numero, ...)`
Busca por número do processo (campo `dadosBasicos.numero`, só dígitos).
```r
processos_brutos_por_numero(cfg_proc, "00201597020148140401")
```

### `processos_brutos_por_classe(cfg, codigo_classe, ...)`
Filtra pelo **código** da classe (`dadosBasicos.classeProcessual`) — o índice
bruto não guarda o nome da classe.
```r
processos_brutos_por_classe(cfg_proc, 279)
```

### `processos_brutos_por_data(cfg, data_inicio, data_fim = NULL, ...)`
Filtra por período de ajuizamento usando `dadosBasicos.dpj_dataAjuizamento`
(ISO 8601), o campo de data confiável para intervalos no índice bruto.
```r
processos_brutos_por_data(cfg_proc, "2024-01-01", "2024-03-31")
```

### `processos_brutos_sigilosos(cfg, nivel_min = 1, ...)`
Traz apenas processos com sigilo (`dadosBasicos.nivelSigilo >= nivel_min`).
```r
processos_brutos_sigilosos(cfg_proc)
```

> Para filtros sem atalho, use os construtores genéricos com os campos
> `dadosBasicos.*`, ex.: `query_term("dadosBasicos.orgaoJulgador.codigoOrgao", 3200)`.

---

## 7. Funções do Datamart

O **Datamart** é um índice da API Elastic, enxuto, com **um documento plano por
processo** e metadados já processados (situação, fase, sigilo, se é criminal,
datas). Estas funções exigem `cfg` com `fonte = "elastic"` e `indice = "datamart"`
— se usadas em outra fonte/índice, avisam que os campos podem não existir.

**Campos típicos:** `id_elastic`, `indice`, `id`, `id_situacao_atual`,
`situacao_atual`, `id_fase_atual`, `fase_atual`, `data_cn`, `data_baixa`,
`criminal`, `sigilo`, `nome_sigilo`, `updated_at`, `@timestamp`.

### `datamart_sigilosos(cfg, id_situacao_atual = 25, sigilo_min = 1, ...)`
Busca processos **sigilosos** (nível de sigilo ≥ `sigilo_min`), opcionalmente
restritos a uma situação atual.
- `sigilo_min` — nível mínimo de sigilo (`0` = público, `≥ 1` = sigiloso);
- `id_situacao_atual` — código da situação (ex.: `25` = em tramitação); `NULL`
  para todas as situações.
```r
datamart_sigilosos(cfg_dm, id_situacao_atual = 25, sigilo_min = 1)
```
Equivale a:
```r
datajud_search(cfg_dm, build_query(
  query_bool(filter = list(
    query_range("sigilo", gte = 1),
    query_term("id_situacao_atual", 25)
  ))
))
```

### `datamart_criminais(cfg, criminal = TRUE, ...)`
Filtra processos criminais (`TRUE`) ou não criminais (`FALSE`).
```r
datamart_criminais(cfg_dm)             # criminais
datamart_criminais(cfg_dm, FALSE)      # não criminais
```

### `datamart_por_situacao(cfg, query = query_match_all(), size = 100)`
Conta processos **agrupados por situação atual**, sem baixar os documentos.
Retorna um tibble com `key` (situação) e `doc_count`. O argumento `query`
permite escopar a contagem (ex.: só sigilosos).
```r
# Todas as situações
datamart_por_situacao(cfg_dm)

# Só entre os sigilosos
datamart_por_situacao(cfg_dm, query = query_range("sigilo", gte = 1))
```

---

## 8. Download em lote

### `download_processos(cfg, body, output_dir, page_size = 100, batch_pages = 50, verbose = TRUE, estimate = TRUE)`
Baixa **grandes volumes** salvando em arquivos **Parquet** por lote (um arquivo a
cada `batch_pages` páginas), evitando estouro de memória. Funciona em qualquer
fonte.
- `output_dir` — pasta de destino (criada se não existir);
- `batch_pages` — quantas páginas por arquivo Parquet;
- colunas com listas (ex.: movimentos) são serializadas em JSON automaticamente.
```r
download_processos(
  cfg_dm,
  body        = build_query(query_range("data_cn", gte = "2024-01-01")),
  output_dir  = "dados/datamart",
  batch_pages = 10
)
```

### `download_bi(tribunal, indicador = "", oj = "", grau = "", municipio = "", ambiente = "csv_p", referencia = NULL, output_dir = NULL, verbose = TRUE)`
Baixa os indicadores agregados do **Painel de Estatística do CNJ** (CSV/ZIP), de
toda a Justiça. É **público e não exige login** — **independe de
`datajud_config()`** (não recebe `cfg`).
- `tribunal` — código (ex.: `"TJAP"`) ou `"all"` para todos;
- `indicador` — código do indicador (ex.: `"CPL"`, `"Sent"`, `"CN"`); obrigatório
  ao usar filtros (`oj`, `grau`, `municipio`);
- `referencia` — período `"YYYY/MM"`, obrigatório para salvar;
- `output_dir` — se informado, salva em Parquet.
```r
download_bi(tribunal = "all", indicador = "CPL", referencia = "2026/01",
            output_dir = "dados/bi")
```
Retorna uma **lista nomeada de data frames**, um por indicador encontrado.

---

## 9. Tabela-resumo

| Função | Categoria | Precisa de `cfg`? | Retorno |
|---|---|---|---|
| `datajud_config()` | Login/configuração | — | `cfg` (lista) |
| `query_match()` | Query DSL | não | cláusula (lista) |
| `query_term()` | Query DSL | não | cláusula |
| `query_terms()` | Query DSL | não | cláusula |
| `query_range()` | Query DSL | não | cláusula |
| `query_match_all()` | Query DSL | não | cláusula |
| `query_bool()` | Query DSL | não | cláusula |
| `build_query()` | Query DSL | não | corpo da requisição |
| `agg_terms()` | Agregação | não | cláusula de agregação |
| `agg_stats()` | Agregação | não | cláusula de agregação |
| `datajud_search()` | Busca | sim | tibble (1 linha/processo) |
| `datajud_count()` | Busca | sim | inteiro (total) |
| `datajud_estimate_download()` | Busca | sim | objeto de estimativa |
| `datajud_aggregate()` | Agregação | sim | tibble de buckets |
| `processos()` | Atalho | sim | tibble |
| `processo_por_numero()` | Atalho | sim | tibble |
| `processos_por_classe()` | Atalho | sim | tibble |
| `processos_por_data()` | Atalho | sim | tibble |
| `processos_busca()` | Atalho | sim | tibble |
| ⭐ `processos_brutos()` | **Processos brutos (principal)** | sim (qualquer fonte) | tibble |
| `processos_brutos_por_numero()` | Processos brutos | sim (`elastic`/`processos`) | tibble |
| `processos_brutos_por_classe()` | Processos brutos | sim (`elastic`/`processos`) | tibble |
| `processos_brutos_por_data()` | Processos brutos | sim (`elastic`/`processos`) | tibble |
| `processos_brutos_sigilosos()` | Processos brutos | sim (`elastic`/`processos`) | tibble |
| `datamart_sigilosos()` | Datamart | sim (`elastic`/`datamart`) | tibble |
| `datamart_criminais()` | Datamart | sim (`elastic`/`datamart`) | tibble |
| `datamart_por_situacao()` | Datamart | sim (`elastic`/`datamart`) | tibble de buckets |
| `download_processos()` | Download | sim | caminho da pasta (invisível) |
| `download_bi()` | Download | **não** | lista de data frames |

---

*Documento de referência gerado para o pacote `datajudr`. Para exemplos
narrados, veja as vignettes `introducao-api`, `dados-brutos-datamart` e
`download-bi`.*
