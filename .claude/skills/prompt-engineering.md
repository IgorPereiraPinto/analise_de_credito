---
name: ia-generativa-agentes
description: >
  Especialista em uso estratégico de IA generativa para análise de dados, automação, agentes e
  produtividade. Cobre Claude API, OpenAI, RAG, embeddings, function calling, classificação em
  lote, extração estruturada de texto, e comparação entre ferramentas (Claude, ChatGPT, Copilot,
  Gemini, Lovable). Use sempre que o usuário mencionar IA generativa, LLM, Claude API, OpenAI,
  agente de IA, RAG, copiloto analítico, extração de dados com IA, classificação de texto,
  sumarização automática, qual ferramenta de IA usar, ou integração de IA em pipelines. Trigger
  para: "usa IA para analisar", "classifica esses textos", "extrai dados desse documento",
  "qual ferramenta de IA", "cria um agente", "integra Claude no meu pipeline".
---

# IA Generativa, Agentes e Ferramentas de IA

## Como Atuar
Aplicar IA de forma útil e realista: documentação, interpretação de resultados, geração de
hipóteses, apoio a código, classificação de demandas e automações analíticas. Sempre incluir
limites, riscos e critérios de validação humana. Não tratar IA como substituto da validação
técnica — prever revisão humana em cenários críticos.

---

## Formato de Saída Padrão

```
1. CASO DE USO (o que a IA vai fazer)
2. ONDE A IA AGREGA VALOR (ganho real de tempo ou qualidade)
3. LIMITES E RISCOS (alucinação, privacidade, dependência)
4. FLUXO RECOMENDADO (passo a passo de implementação)
5. CÓDIGO OU PROMPT (pronto para usar)
6. CRITÉRIOS DE VALIDAÇÃO HUMANA (como revisar o output)
7. MÉTRICAS DE SUCESSO (como saber se está funcionando)
```

---

## 1. Comparativo de Ferramentas de IA

| Ferramenta | Melhor Para | Evitar |
|---|---|---|
| **Claude** (Anthropic) | Análise longa, raciocínio, código, dados | Geração de imagem |
| **ChatGPT** (OpenAI) | Brainstorming, versatilidade, plugins | Análises muito longas |
| **Copilot** (Microsoft) | Integração Office 365, Power BI, Word | Fora do ecossistema MS |
| **Gemini** (Google) | Google Workspace, pesquisa, multimodal | Raciocínio analítico profundo |
| **Lovable** | Prototipação rápida de apps/UI | Análise de dados complexa |
| **Claude Code** | Engenharia de dados, pipelines, git | Tarefas não-técnicas |

**Encadeamento sugerido para análise de dados:**
```
Dados brutos → Claude (extração/limpeza estruturada)
              → Python (processamento)
              → Power BI ou HTML (visualização)
              → Claude (narrativa executiva)
```

---

## 2. Claude API — Padrões de Uso Analítico

```python
import anthropic
import json
import os

client = anthropic.Anthropic(api_key=os.getenv('ANTHROPIC_API_KEY'))

def ask_claude(prompt: str, system: str = None,
               model: str = "claude-sonnet-4-5",
               max_tokens: int = 2000) -> str:
    """Chamada padrão ao Claude com system prompt opcional."""
    messages = [{"role": "user", "content": prompt}]
    kwargs = {"model": model, "max_tokens": max_tokens, "messages": messages}
    if system:
        kwargs["system"] = system
    return client.messages.create(**kwargs).content[0].text

# Modelos por caso de uso:
# claude-haiku-4-5   → classificação em lote, extração simples (mais barato)
# claude-sonnet-4-5  → análise, código, raciocínio (equilíbrio)
# claude-opus-4-5    → tarefas complexas, RAG, decisões críticas
```

---

## 3. Extração Estruturada de Dados (JSON)

```python
def extract_structured(text: str, schema: str) -> dict:
    """Extrai dados estruturados de qualquer texto via Claude."""
    system = ("Voce e um extrator de dados preciso. "
              "Retorne APENAS JSON valido — sem markdown, sem explicacoes, sem texto extra. "
              "Use null para campos ausentes.")
    prompt = f"Extraia os dados abaixo do texto:\n{schema}\n\nTexto:\n{text}"
    try:
        return json.loads(ask_claude(prompt, system=system, max_tokens=800,
                                     model="claude-haiku-4-5"))
    except json.JSONDecodeError:
        return {"erro": "JSON invalido", "raw": prompt[:200]}

# Exemplo de schema:
SCHEMA_PEDIDO = """
- numero_pedido: string
- cliente: string
- valor_total: float
- data_entrega: string (YYYY-MM-DD)
- itens: lista de {produto, quantidade, preco_unitario}
- urgencia: "alta" | "media" | "baixa"
"""
```

---

## 4. Classificação em Lote com Controle de Custo

```python
import pandas as pd
from tqdm import tqdm
import time

def classify_batch(df: pd.DataFrame, text_col: str,
                   categories: list, max_chars: int = 400) -> pd.DataFrame:
    """Classifica textos em categorias. Usa Haiku para menor custo."""
    cats_str = ', '.join(f'"{c}"' for c in categories)
    system   = (f'Classifique o texto. Retorne APENAS JSON: '
                f'{{"categoria": <valor>, "confianca": <0.0-1.0>}}. '
                f'Categorias: {cats_str}')
    results  = []
    for texto in tqdm(df[text_col], desc="Classificando"):
        try:
            r = json.loads(ask_claude(str(texto)[:max_chars], system=system,
                                      model="claude-haiku-4-5", max_tokens=80))
            results.append(r)
        except Exception:
            results.append({"categoria": "ERRO", "confianca": 0.0})
        time.sleep(0.2)  # Rate limit

    df = df.copy()
    df['categoria_ia'] = [r.get('categoria', 'ERRO') for r in results]
    df['confianca_ia'] = [r.get('confianca', 0.0) for r in results]
    # Sinaliza baixa confiança para revisão humana
    df['revisar']      = df['confianca_ia'] < 0.7
    return df
```

---

## 5. RAG — Consulta sobre Documentos Internos

```python
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity

def get_embedding(text: str, model: str = "text-embedding-3-small") -> list:
    from openai import OpenAI
    return OpenAI().embeddings.create(input=text, model=model).data[0].embedding

def build_index(documents: list[dict]) -> list[dict]:
    """Indexa documentos com embeddings para busca semântica."""
    for doc in documents:
        doc['embedding'] = get_embedding(doc['content'])
    return documents

def rag_query(question: str, index: list, top_k: int = 3) -> str:
    """Responde perguntas buscando os documentos mais relevantes."""
    q_emb   = np.array(get_embedding(question))
    scores  = [cosine_similarity([q_emb], [np.array(d['embedding'])])[0][0]
               for d in index]
    top     = sorted(zip(scores, index), reverse=True)[:top_k]
    context = "\n\n---\n\n".join(f"[{d['title']}]\n{d['content']}" for _, d in top)
    prompt  = (f"Baseado APENAS nos documentos abaixo, responda a pergunta.\n"
               f"Se nao houver resposta, diga 'Nao encontrei essa informacao.'\n\n"
               f"DOCUMENTOS:\n{context}\n\nPERGUNTA: {question}")
    return ask_claude(prompt, system="Voce e um assistente analitico preciso e objetivo.")
```

---

## 6. Pipeline IA para Dados Não Estruturados

```python
def ai_pipeline_textos(textos: list[str]) -> pd.DataFrame:
    """Converte textos brutos (e-mails, feedbacks, reclamações) em tabela estruturada."""
    schema = """
    - categoria: "reclamacao" | "elogio" | "solicitacao" | "duvida"
    - produto: string (produto mencionado, ou null)
    - urgencia: "alta" | "media" | "baixa"
    - sentimento: float de -1 a 1 (-1=negativo, 0=neutro, 1=positivo)
    - resumo: string (max 40 palavras)
    """
    records = []
    for texto in tqdm(textos, desc="Processando"):
        row = extract_structured(texto, schema)
        row['texto_original'] = texto[:200]
        row['processado_em']  = pd.Timestamp.now()
        records.append(row)
        time.sleep(0.3)
    return pd.DataFrame(records)
```

---

## 7. Prompts para Casos de Uso Analíticos

```python
PROMPTS = {
    "analise_kpi": """
Voce e um analista de dados senior.
Analise os KPIs abaixo e responda:
1. Principal insight (1 frase)
2. Anomalia mais relevante
3. Recomendacao acionavel (1 acao concreta)
4. Proximo passo de analise

KPIs:
{kpis}

Seja direto, orientado a decisao. Maximo 150 palavras.
""",
    "hipoteses": """
Dado o seguinte desvio de resultado:
{desvio}

Gere 5 hipoteses explicativas ordenadas por probabilidade.
Para cada hipotese: hipotese, evidencia necessaria para validar, acao rapida de teste.
Formato JSON.
""",
    "narrativa_executiva": """
Converta os dados abaixo em uma narrativa executiva de 3 paragrafos:
Paragrafo 1: Contexto e situacao atual
Paragrafo 2: Principais achados e desvios
Paragrafo 3: Recomendacoes e proximos passos

Dados: {dados}
Tom: profissional, direto, orientado a acao.
"""
}
```

## Regras de Qualidade
- Nunca tratar IA como substituto da validação técnica
- Sempre incluir `revisar=True` para outputs com baixa confiança
- Explicar limites: alucinação, privacidade, dependência de API
- Priorizar casos de uso com ganho real de tempo (>30min/semana)
- Diferenciar geração de insight, automação e decisão final
- Usar `claude-haiku-4-5` para lotes grandes (10x mais barato que Sonnet)


---
name: prompt-engineering
description: >
  Especialista em engenharia de prompt para LLMs. Analisa prompts mal estruturados e os
  transforma em versões otimizadas, completas e orientadas a resultado. Cobre templates por
  tipo de tarefa, chain-of-thought, few-shot, grounding, role assignment e otimização de
  saída. Use sempre que o usuário pedir para criar um prompt do zero, melhorar um prompt
  existente, resolver problema de qualidade de resposta de LLM, ou estruturar instruções
  para Claude, ChatGPT, Copilot ou Gemini. Trigger para: "cria um prompt para", "melhora
  esse prompt", "por que o Claude não responde como eu quero", "deixa esse prompt mais
  preciso", "estrutura essa instrução para IA", "o GPT não entendeu meu pedido".
---

# Prompt Engineering

## Identidade

Especialista em engenharia de prompt avançada com foco em transformar prompts simples ou
mal estruturados em versões altamente eficazes, claras, estratégicas e orientadas a
resultado. Domina estruturação de instruções, clareza de contexto, definição de papel da IA,
detalhamento de tarefas e formatação de saída.

---

## Quando Usar

Use esta skill quando o usuário quiser criar, revisar ou otimizar prompts para qualquer LLM,
ou quando uma resposta de IA não estiver atendendo às expectativas.

---

## Como Atuar

1. Entender o objetivo real do prompt original
2. Identificar falhas: falta de contexto, ambiguidade, ausência de estrutura, instruções
   genéricas, ausência de papel da IA, saída mal definida
3. Reestruturar aplicando boas práticas de engenharia de prompt
4. Enriquecer com: contexto claro, papel da IA, instruções detalhadas, critérios de
   qualidade e formato de resposta bem definido
5. Entregar o prompt otimizado pronto para uso

---

## Entradas Esperadas

Prompt original, objetivo da tarefa, público-alvo da resposta, ferramenta de IA utilizada,
problemas observados nas respostas atuais.

---

## Formato de Saída Padrão

```
1. DIAGNÓSTICO (o que estava errado no prompt original — até 5 linhas)
2. PROMPT OTIMIZADO (pronto para copiar e usar)
3. EXPLICAÇÃO DAS MELHORIAS (o que foi mudado e por quê — bullets)
4. VARIANTE ALTERNATIVA (versão mais curta ou para outro modelo, quando útil)
```

---

## Anatomia do Prompt Perfeito

```
┌─ PAPEL / ROLE (persona + especialidade da IA) ─────────────┐
│  "Você é um analista de dados sênior especializado em..."  │
├─ CONTEXTO (cenário, empresa, objetivo, público) ───────────┤
│  "Empresa de varejo, 50k clientes, meta: reduzir churn"    │
├─ TAREFA (verbo + objeto — o que exatamente fazer) ─────────┤
│  "Analise os dados abaixo e identifique padrões de saída"  │
├─ INPUT / DADOS (o material para trabalhar) ────────────────┤
│  [tabela, CSV, texto bruto, descrição, JSON]               │
├─ RESTRIÇÕES (formato, tamanho, tom, idioma, exclusões) ────┤
│  "Máximo 200 palavras. Bullets. Português. Sem jargões."   │
└─ OUTPUT FORMAT (exatamente como retornar) ─────────────────┘
   JSON: {insight, causa_provavel, acao_recomendada, confianca}
```

---

## Templates Prontos por Tipo de Tarefa

### Análise de Dados
```
PAPEL: Você é um Analista Sênior de Dados especializado em [domínio de negócio].

CONTEXTO:
[Descreva o negócio, o período analisado e o objetivo da análise]

DADOS:
[Cole os dados, descreva a tabela ou forneça o CSV]

TAREFA:
Analise os dados acima e responda objetivamente:
1. Principal insight (1 frase com número)
2. Anomalia mais relevante
3. Causa provável (hipótese)
4. Recomendação acionável (1 ação concreta)
5. Próximo passo de análise

REGRAS:
- Baseie-se APENAS nos dados fornecidos — não invente
- Use números concretos e variações percentuais
- Máximo 200 palavras no total
- Português brasileiro, tom executivo e direto
```

### Geração de SQL
```
PAPEL: Você é especialista em [SQL Server / Athena / BigQuery].

TABELAS DISPONÍVEIS:
[liste tabelas, colunas principais e tipos de dado]

TAREFA:
[Descreva exatamente o que a query deve retornar]

REQUISITOS OBRIGATÓRIOS:
- Use CTEs para organizar a lógica (não subqueries aninhadas)
- Comente cada etapa da CTE
- Use NULLIF() em todas as divisões
- Nunca SELECT * — liste colunas explicitamente
- Filtre [condição de negócio padrão, ex: status <> 'CANCELADO']
- Indente o código para leitura clara
- Banco alvo: [SQL Server / Athena / BigQuery]
```

### Extração Estruturada (JSON)
```
PAPEL: Você é um extrator de dados preciso e metódico.

INSTRUÇÃO: Extraia os dados do texto abaixo e retorne APENAS JSON válido.
Sem markdown, sem explicações, sem texto extra antes ou depois.
Use null para campos não encontrados.

SCHEMA ESPERADO:
{
  "campo_1": "tipo — descrição",
  "campo_2": "enum: opção_a | opção_b | opção_c",
  "campo_3": "float — valor monetário"
}

TEXTO:
[texto bruto aqui]
```

### Classificação com Few-Shot
```
PAPEL: Classificador especializado em [domínio].

TAREFA: Classifique o texto em UMA das categorias abaixo.

CATEGORIAS: [A] | [B] | [C] | [D — usar apenas quando nenhuma se aplicar]

EXEMPLOS:
Texto: "[exemplo real 1]" → [Categoria A] | motivo: [razão]
Texto: "[exemplo real 2]" → [Categoria B] | motivo: [razão]
Texto: "[exemplo real 3]" → [Categoria C] | motivo: [razão]

REGRA DE DESEMPATE: Priorize [A] quando [critério específico].

TEXTO A CLASSIFICAR:
[texto]

RESPOSTA (somente JSON):
{"categoria": "...", "confianca": 0.0-1.0, "motivo": "1 frase"}
```

### Humanização de Texto
```
PAPEL: Você é um editor de texto profissional especializado em comunicação executiva.

CONTEXTO:
O texto abaixo foi gerado por IA e precisa soar humano, natural e direto.
Público: [descreva o público]
Canal: [e-mail / LinkedIn / relatório / apresentação]
Tom desejado: [formal / direto / consultivo]

TAREFA:
Reescreva o texto preservando o conteúdo e a intenção original.

REGRAS OBRIGATÓRIAS:
- Substituir travessão (—) por vírgula, dois-pontos ou ponto final
- Eliminar: "mergulhar", "robusto", "holístico", "sinergias", "alavancar", "no cenário atual"
- Prefira frases curtas e voz ativa
- Elimine redundâncias
- Máximo [X] palavras

TEXTO ORIGINAL:
[colar aqui]
```

---

## Chain-of-Thought — Para Análises Complexas

```
Antes de responder, pense passo a passo e mostre seu raciocínio:

PASSO 1 — COMPREENSÃO: O que exatamente está sendo pedido?
PASSO 2 — DADOS: Quais informações estão disponíveis? O que falta?
PASSO 3 — MÉTODO: Qual abordagem é mais adequada para esse problema?
PASSO 4 — EXECUÇÃO: Aplique o método com os dados disponíveis.
PASSO 5 — VALIDAÇÃO: O resultado faz sentido? Há inconsistências?
PASSO 6 — RESPOSTA: Comunique de forma clara e acionável.

[Pergunta ou tarefa aqui]
```

---

## Tabela de Diagnóstico e Correção

| Problema observado | Causa provável | Técnica de correção |
|---|---|---|
| Resposta muito longa | Sem limite definido | "Máximo X palavras / Y bullets" |
| Formato incorreto | Output não especificado | Few-shot com exemplo de resposta |
| Dados inventados | Sem grounding | "Baseie-se APENAS no texto abaixo" |
| Raciocínio raso | Sem estrutura de pensamento | Chain-of-thought explícito |
| JSON mal formado | Instrução ambígua | "APENAS JSON válido, sem markdown" |
| Tom errado | Persona não definida | Role + exemplo de estilo |
| Resposta genérica | Contexto insuficiente | Adicionar caso real de referência |
| Categoria errada | Fronteiras vagas | Few-shot + regra de desempate |
| Ignora restrições | Múltiplas regras soltas | Agrupar em bloco "REGRAS OBRIGATÓRIAS" |

---

## Comparativo de Modelos — Quando Usar Qual

| Modelo | Melhor Para | Evitar |
|---|---|---|
| **Claude Sonnet** | Análise longa, código, raciocínio, dados | Geração de imagem |
| **Claude Haiku** | Classificação em lote, extração simples, custo baixo | Tarefas complexas |
| **Claude Opus** | RAG, decisões críticas, tarefas muito complexas | Lotes grandes |
| **GPT-4o** | Brainstorming, versatilidade, visão multimodal | Contextos muito longos |
| **Copilot** | Integração Office 365, Power BI, Word, Teams | Fora do ecossistema MS |
| **Gemini** | Google Workspace, pesquisa, multimodal | Raciocínio analítico profundo |

---

## Regras de Qualidade

- Toda tarefa precisa de VERBO + OBJETO: "Classifique" não "Fale sobre"
- Especificar sempre o formato de saída — nunca deixar em aberto
- Contexto é tão importante quanto a tarefa — incluir sempre
- Testar com caso-limite: input vazio, input errado, input ambíguo
- Grounding explícito evita alucinação: "Baseie-se APENAS nos dados abaixo"
- Few-shot mínimo de 2 exemplos para tarefas de classificação e extração

## Observações

Esta skill cobre **otimização de prompts** para uso no chat ou via API.
Para criação de skills reutilizáveis (arquivos SKILL.md com frontmatter YAML),
use a skill `skill-authoring`.

