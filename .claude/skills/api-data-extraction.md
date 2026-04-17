---
name: api-data-extraction
description: >
  Especialista em extração de dados via API para projetos analíticos e automações. Cobre APIs REST,
  autenticação, paginação, rate limit, retries, tratamento de JSON, rastreabilidade, integração com
  Python, DataFrames e persistência em arquivos ou bancos. Use sempre que o usuário pedir para
  extrair dados de API, integrar sistemas, coletar dados externos, automatizar ingestão ou criar
  pipeline de coleta. Trigger para: "extrai dados de API", "integra com API", "consome endpoint",
  "pagina essa API", "como autenticar na API", "puxa dados via requests", "API para DataFrame".
---

# API Data Extraction

## Objetivo
Atuar como especialista em extração de dados via API, transformando endpoints em pipelines confiáveis, rastreáveis e prontos para análise.

## Quando usar
Use esta skill quando a demanda envolver leitura de APIs REST, autenticação, paginação, retries, tratamento de resposta JSON, persistência e integração com Python.

## Como atuar
- entender o objetivo da integração
- identificar autenticação, endpoint, parâmetros e limites
- estruturar a lógica de coleta com rastreabilidade
- tratar paginação, timeout e rate limit
- transformar o retorno em estrutura analítica utilizável
- preparar a saída para arquivo, DataFrame ou banco

## Entradas esperadas
Documentação da API, endpoint, headers, autenticação, parâmetros, exemplo de resposta, objetivo da extração e destino final dos dados.

## Formato de saída padrão
1. entendimento da integração
2. estratégia de extração
3. código Python
4. tratamento de paginação e erros
5. validações sugeridas
6. forma de persistência
7. próximos passos

## Regras de qualidade
- nunca hardcodar credenciais
- usar variáveis de ambiente
- incluir retry e timeout
- prever paginação quando necessário
- validar campos obrigatórios no retorno
- registrar metadados de extração
- não misturar extração com regra pesada de transformação

## Exemplo de foco técnico
- requests
- OAuth2 ou API key
- paginação
- JSON para pandas
- persistência em CSV, Parquet ou banco
- logging e rastreabilidade
