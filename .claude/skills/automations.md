---
name: automacoes-power-platform
description: >
  Especialista em automação de processos com Power Automate, Power Apps, Power Platform,
  integrações e desenho de fluxos operacionais eficientes. Cobre mapeamento de processos,
  fluxos de aprovação, integração com SharePoint, Excel, Teams, SQL Server e APIs REST.
  Use sempre que o usuário mencionar automação de processo, Power Automate, Power Apps,
  fluxo de aprovação, integração entre sistemas, eliminação de retrabalho manual, gatilho
  automático, notificação, formulário digital, ou qualquer tarefa de automação corporativa.
  Trigger para: "automatiza esse processo", "cria um fluxo no Power Automate", "formulário
  com Power Apps", "alerta automático", "integra SharePoint com SQL", "elimina retrabalho".
---

# Automações, Power Automate e Power Platform

## Como Atuar
Mapear o processo atual, identificar gargalos, entradas, saídas, regras, exceções e pontos
de controle. Sugerir automações práticas com foco em produtividade, governança e redução de
retrabalho. Pensar sempre em ponta a ponta, incluindo tratamento de erro e logs.

---

## Formato de Saída Padrão

```
1. DIAGNÓSTICO DO PROCESSO (situação atual, dores, volume)
2. FLUXO ATUAL RESUMIDO (passo a passo manual)
3. FLUXO AUTOMATIZADO PROPOSTO (com ferramentas)
4. FERRAMENTAS RECOMENDADAS (Power Automate, Apps, SQL, API)
5. REGRAS E EXCEÇÕES (tratamento de erros, aprovações)
6. BENEFÍCIOS ESPERADOS (tempo, custo, qualidade)
7. RISCOS E MONITORAMENTO (logs, alertas, rollback)
```

---

## 1. Casos de Uso Mais Comuns

| Processo | Ferramenta | Gatilho |
|---|---|---|
| Aprovação de pedidos | Power Automate + Teams | Formulário ou e-mail |
| Coleta de dados estruturada | Power Apps + SharePoint | Acesso via app |
| Relatório automático por e-mail | Power Automate + Excel/SQL | Agendamento diário |
| Alerta de KPI fora da meta | Power Automate + Teams | Recorrência + condição |
| Extração e consolidação de planilhas | Python + Power Automate | Novo arquivo no SharePoint |
| Onboarding de fornecedor | Power Apps + Power Automate | Formulário → aprovação → cadastro |

---

## 2. Estrutura de Fluxo Power Automate

```
GATILHO (quando o fluxo inicia):
├── Novo item em lista SharePoint
├── E-mail recebido com assunto específico
├── Formulário do Power Apps enviado
├── Agendamento (recorrência diária/semanal)
└── Webhook de sistema externo

CONDIÇÕES (lógica de decisão):
├── Se [campo] = [valor] → Caminho A
├── Se [campo] > [limite] → Alerta + escalonamento
└── Else → Caminho padrão

AÇÕES:
├── Criar item SharePoint / atualizar registro SQL
├── Enviar e-mail/Teams com dados dinâmicos
├── Gerar PDF ou Excel com relatório
├── Chamar API REST externa
└── Log de auditoria (data, usuário, ação, resultado)

TRATAMENTO DE ERRO:
├── Configure "Run after" no bloco de erro
├── Envie e-mail de falha para responsável técnico
└── Registre erro em lista de log
```

---

## 3. Integração Power Automate + SQL Server

```json
// Configuração de conexão SQL no Power Automate:
// Adicione ação "Execute a SQL query" ou "Get rows"

// Exemplo de query dinâmica em Power Automate:
{
  "query": "SELECT id_pedido, status, valor FROM dbo.pedidos WHERE status = 'PENDENTE' AND data_pedido >= '@{addDays(utcNow(), -1)}'"
}

// Para inserir log:
{
  "query": "INSERT INTO dbo.log_automacao (data_exec, fluxo, resultado, usuario) VALUES (GETDATE(), 'aprovacao_pedido', '@{variables('resultado')}', '@{triggerBody()['autor']}')"
}
```

---

## 4. Power Apps — Formulário Estruturado

```
ESTRUTURA RECOMENDADA DE APP:
├── Tela 1: Home / Menu
├── Tela 2: Formulário de entrada (campos validados)
│   ├── Campos obrigatórios com validação visual
│   ├── Dropdowns com listas de SharePoint
│   └── Botão Enviar → dispara Power Automate
├── Tela 3: Confirmação / número de protocolo
└── Tela 4: Consulta de status (busca por ID ou nome)

BOAS PRÁTICAS:
- Usar Gallery para listagem de registros
- Conectar DataSource = SharePoint List ou SQL
- Validar campos antes de submeter: IsBlank(), IsMatch()
- Usar variáveis de contexto: Set(varUsuario, User().FullName)
```

---

## 5. Python + Automação de Planilhas

```python
import pandas as pd
import os
from pathlib import Path
from datetime import datetime

def consolidar_planilhas(pasta: str, padrao: str = "*.xlsx") -> pd.DataFrame:
    """Consolida todas as planilhas de uma pasta em um único DataFrame."""
    arquivos = list(Path(pasta).glob(padrao))
    dfs = []
    for arquivo in arquivos:
        try:
            df = pd.read_excel(arquivo, sheet_name=0)
            df['_arquivo'] = arquivo.name
            df['_importado_em'] = datetime.now()
            dfs.append(df)
            print(f"✅ {arquivo.name}: {len(df)} linhas")
        except Exception as e:
            print(f"❌ {arquivo.name}: {e}")
    resultado = pd.concat(dfs, ignore_index=True) if dfs else pd.DataFrame()
    print(f"\nTotal: {len(resultado):,} linhas de {len(dfs)} arquivos")
    return resultado

def enviar_relatorio_email(df_resumo: pd.DataFrame, destinatarios: list,
                            assunto: str, corpo: str):
    """Envia relatório por e-mail via SMTP (use com servidor corporativo)."""
    import smtplib
    from email.mime.multipart import MIMEMultipart
    from email.mime.text import MIMEText
    from email.mime.base import MIMEBase
    from email import encoders

    msg = MIMEMultipart()
    msg['Subject'] = assunto
    msg['To']      = ', '.join(destinatarios)
    msg.attach(MIMEText(corpo, 'html'))

    # Anexa Excel
    excel_path = '/tmp/relatorio.xlsx'
    df_resumo.to_excel(excel_path, index=False)
    with open(excel_path, 'rb') as f:
        part = MIMEBase('application', 'octet-stream')
        part.set_payload(f.read())
        encoders.encode_base64(part)
        part.add_header('Content-Disposition', 'attachment', filename='relatorio.xlsx')
        msg.attach(part)

    # Envio (ajuste servidor SMTP conforme ambiente)
    with smtplib.SMTP('smtp.empresa.com', 587) as server:
        server.starttls()
        server.login(os.getenv('EMAIL_USER'), os.getenv('EMAIL_PASS'))
        server.sendmail(os.getenv('EMAIL_USER'), destinatarios, msg.as_string())
    print("✅ E-mail enviado com sucesso")
```

---

## Regras de Qualidade
- Sempre incluir tratamento de erro e log de execução
- Diferenciar coleta (Power Apps), processamento (Automate/Python) e aprovação (Teams)
- Priorizar automações auditáveis — toda ação deve gerar registro
- Sugerir Power Apps para entrada estruturada e Power Automate para orquestração
- Começar simples: automatize 1 etapa por vez, valide, depois expanda
- Documentar o fluxo em diagrama antes de construir
