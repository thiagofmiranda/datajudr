# datajudr 0.2.1

## Correções

* Campos que vêm `null` da API não quebram mais a montagem do tibble. Antes, um
  campo nulo virava uma *list column* contendo `NULL`, o que causava dois erros:
  `Can't combine <list> and <integer>` no `bind_rows` (quando o campo vinha
  preenchido em algumas linhas e nulo em outras) e, ao exibir o resultado no
  Jupyter/IRkernel, `'names' attribute [1] must be the same length as the vector
  [0]` (na renderização pelo pacote `repr`). Agora o campo nulo vira `NA`
  (`processos_brutos()` e demais funções de busca).

# datajudr 0.2.0

## Novas fontes de dados

* `datajud_config()` agora suporta dois modos de acesso via `fonte`:
  * `"publica"` (padrão) — API pública, autenticação por APIKey (comportamento
    anterior, sem mudanças).
  * `"elastic"` — API Elasticsearch, autenticação Basic Auth (`DATAJUD_USER` /
    `DATAJUD_PWD`). O índice é escolhido com `indice`:
    * `"processos"` (padrão) — dados brutos de `view-processos-sigilo-*`,
      incluindo processos sigilosos;
    * `"datamart"` — índice `datamart-*` de metadados agregados e planos.
* O objeto de configuração passou a carregar `indice`, e o campo de ordenação do
  `search_after` é resolvido por fonte/índice (`@timestamp`, `id.keyword` ou `id`).

## Processos brutos (Elastic)

* **Nova função principal `processos_brutos(cfg, variavel, valores)`** — a forma
  recomendada para baixar dados brutos: escolha **o campo** e passe **uma lista
  de valores**; monta uma consulta `terms` (OR lógico) e traz todos os processos
  que casam com qualquer um deles. É genérica e **não fixa índice**, funcionando
  em qualquer fonte (bruto, Datamart ou API pública).
* Novos atalhos para o índice `processos` (`view-processos-sigilo-*`), que usa o
  esquema bruto do CNJ (MTD, `dadosBasicos.*`), diferente da API pública:
  `processos_brutos_por_numero()`, `processos_brutos_por_classe()` (por código),
  `processos_brutos_por_data()` e `processos_brutos_sigilosos()`.
* Os atalhos `processos_*` continuam específicos da API pública (documentado via
  `@note` e na referência de funções).

## Datamart e agregações

* Novas funções de atalho: `datamart_sigilosos()`, `datamart_criminais()` e
  `datamart_por_situacao()`.
* Suporte a agregações no Elasticsearch DSL: `agg_terms()`, `agg_stats()`,
  `build_query(query, aggs =, size =)` e `datajud_aggregate()` (retorna os
  buckets como tibble organizado).
* Novo construtor `query_terms()` (casa com qualquer um de vários valores).

## Melhorias

* Respostas da API agora são sempre lidas em **UTF-8**, independentemente do
  `charset` (às vezes incorreto) anunciado pelo servidor — corrige acentos
  corrompidos nos textos (ex.: `situacao_atual`, `fase_atual`, `nome_sigilo`).
* A paginação (`search_after`) evita uma requisição extra ao final quando a
  última página vem incompleta — antes o download imprimia uma página a mais do
  que o necessário.
* Mensagens de erro da API agora exibem o motivo real retornado pelo
  Elasticsearch (linha `Detalhe:`), facilitando o diagnóstico de erros 400.
* O limite de requisições por minuto passou a ser configurável em
  `datajud_config(rate_limit =)`.
* Adicionados testes automatizados (`testthat` + `httptest2`).

## Documentação

* Nova vignette *Dados brutos (API Elastic) e Datamart*.
* Novo documento de referência `REFERENCIA-FUNCOES.md`.
* `download_bi()` documentado como acesso ao **Painel de Estatística** do CNJ
  (público, sem login).

# datajudr 0.1.0

* Primeira versão: consulta e download da API pública do DataJud e download de
  dados do BI do CNJ.
