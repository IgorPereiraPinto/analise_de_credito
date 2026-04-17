---
name: excel-analytics
description: >
  Especialista em Excel avançado para análise de dados, automação com VBA, Power Query M,
  funções analíticas, tabelas dinâmicas, dashboards e integração com Python e SQL. Use sempre
  que o usuário mencionar Excel, planilha, VBA, macro, Power Query, tabela dinâmica, PROCV,
  XLOOKUP, fórmula de array, dashboard em Excel, ou automação de planilha. Trigger para:
  "fórmula Excel", "cria uma macro", "Power Query no Excel", "tabela dinâmica", "PROCV",
  "dashboard em Excel", "consolida planilhas", "automatiza esse relatório Excel",
  "VBA para", "XLOOKUP", "SOMASE", "função de array".
---

# Excel Analytics — Excel Avançado, VBA e Power Query

## Identidade

Especialista em Excel avançado para análise de dados corporativos. Domina fórmulas analíticas,
VBA para automação, Power Query M para ETL e construção de dashboards executivos. Foco em
soluções práticas, auditáveis e replicáveis no dia a dia.

---

## Quando Usar

Use esta skill para qualquer tarefa com Excel: fórmulas, macros VBA, Power Query, tabelas
dinâmicas, dashboards e automação. Para automação corporativa multi-sistema, use
`automacoes-power-platform`. Para análise com Python sobre Excel, use `python-analytics`.

---

## 1. Fórmulas Analíticas Essenciais

```excel
/* ── BUSCA E REFERÊNCIA ──────────────────────────────────────── */

/* XLOOKUP (substitui PROCV + PROCH + ÍNDICE/CORRESP) */
=XLOOKUP(valor_busca; matriz_busca; matriz_retorno; "Não encontrado"; 0)

/* PROCV clássico com verificação de erro */
=SEERRO(PROCV(A2; Tabela!$A:$D; 3; 0); "N/A")

/* ÍNDICE + CORRESP (busca em qualquer direção) */
=ÍNDICE(C:C; CORRESP(A2; A:A; 0))

/* ── AGREGAÇÃO CONDICIONAL ────────────────────────────────────── */

/* SOMASES com múltiplos critérios */
=SOMASES(D:D; B:B; "Sudeste"; C:C; ">="&DATA(2024;1;1); C:C; "<"&DATA(2025;1;1))

/* CONTSES para contagem condicional */
=CONTSES(B:B; "Sudeste"; E:E; "ATIVO")

/* MÉDIASES para média com filtro */
=MÉDIASES(D:D; B:B; "Sudeste"; E:E; "<>CANCELADO")

/* ── ANÁLISE TEMPORAL ─────────────────────────────────────────── */

/* Mês anterior (1º dia) */
=DATAM(HOJE(); -1)

/* YTD: soma do início do ano até hoje */
=SOMASES(D:D; C:C; ">="&DATA(ANO(HOJE());1;1); C:C; "<="&HOJE())

/* Crescimento MoM % */
=(D2-D1)/ABS(D1)

/* Dias úteis entre duas datas */
=DIATRABALHOTOTAL(data_inicio; data_fim; feriados)

/* ── TEXTO E LIMPEZA ─────────────────────────────────────────── */

/* Normalizar texto */
=MAIÚSCULA(ARRUMAR(A2))

/* Extrair domínio de e-mail */
=EXT.TEXTO(A2; LOCALIZAR("@"; A2)+1; 100)

/* Concatenar com separador ignorando vazios */
=UNIRTEXTO("; "; VERDADEIRO; A2:A10)

/* ── FÓRMULAS DE ARRAY (Ctrl+Shift+Enter ou dinâmicas no 365) ── */

/* Top 5 valores únicos de uma coluna */
=ÚNICOS(MAIORES(D2:D100; SEQUÊNCIA(5)))

/* Filtro dinâmico com critério */
=FILTRO(A2:D100; B2:B100="Sudeste"; "Sem resultados")

/* Ranking sem empate */
=CLASSIFICAR(A2:D100; 4; -1)  /* ordena pela coluna 4 decrescente */
```

---

## 2. Power Query M — ETL Dentro do Excel

```m
// ── Transformação padrão de tabela de vendas ─────────────────────
let
    // 1. Conexão com fonte (CSV, banco, SharePoint)
    Fonte = Csv.Document(
        File.Contents("C:\dados\vendas.csv"),
        [Delimiter=";", Encoding=65001, QuoteStyle=QuoteStyle.None]
    ),
    // 2. Promoção de headers
    Headers = Table.PromoteHeaders(Fonte, [PromoteAllScalars=true]),

    // 3. Tipagem correta
    Tipagem = Table.TransformColumnTypes(Headers, {
        {"id_venda",       Int64.Type},
        {"data_venda",     type date},
        {"valor_bruto",    type number},
        {"valor_desconto", type number},
        {"status",         type text}
    }),

    // 4. Limpeza e padronização
    Limpo = Table.TransformColumns(Tipagem, {
        {"status", Text.Upper},
        {"canal",  Text.Trim}
    }),

    // 5. Filtro de registros válidos
    Filtrado = Table.SelectRows(Limpo, each
        [status] <> "CANCELADO" and [valor_bruto] > 0
    ),

    // 6. Coluna calculada
    ComLiquido = Table.AddColumn(Filtrado, "valor_liquido",
        each [valor_bruto] - [valor_desconto], type number
    ),

    // 7. Features de data
    ComAno = Table.AddColumn(ComLiquido, "ano",
        each Date.Year([data_venda]), Int64.Type
    ),
    ComMes = Table.AddColumn(ComAno, "mes",
        each Date.Month([data_venda]), Int64.Type
    ),
    ComAnoMes = Table.AddColumn(ComMes, "ano_mes",
        each Text.From(Date.Year([data_venda])) & "/" &
             Text.PadStart(Text.From(Date.Month([data_venda])), 2, "0"),
        type text
    )
in
    ComAnoMes

// ── Consolidar múltiplos arquivos de uma pasta ──────────────────
let
    Pasta   = Folder.Files("C:\dados\mensais\"),
    Filtro  = Table.SelectRows(Pasta, each [Extension] = ".xlsx"),
    Dados   = Table.AddColumn(Filtro, "Tabela",
                  each Excel.Workbook([Content], true){0}[Data]),
    Expande = Table.ExpandTableColumn(Dados, "Tabela",
                  Table.ColumnNames(Dados{0}[Tabela]))
in
    Expande
```

---

## 3. VBA — Automação de Relatórios

```vba
' ── Macro padrão de formatação de relatório ─────────────────────
Sub FormatarRelatorio()
    Dim ws As Worksheet
    Dim rng As Range
    Dim lastRow As Long, lastCol As Long

    Set ws = ThisWorkbook.ActiveSheet
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    lastCol = ws.Cells(1, ws.Columns.Count).End(xlToLeft).Column
    Set rng = ws.Range(ws.Cells(1, 1), ws.Cells(lastRow, lastCol))

    ' Header
    With ws.Rows(1)
        .Interior.Color = RGB(26, 58, 92)   ' Azul escuro
        .Font.Color = RGB(255, 255, 255)
        .Font.Bold = True
        .Font.Size = 10
    End With

    ' Auto-filtro
    rng.AutoFilter

    ' Zebra stripes
    Dim i As Long
    For i = 2 To lastRow
        If i Mod 2 = 0 Then
            ws.Rows(i).Interior.Color = RGB(235, 241, 245)
        Else
            ws.Rows(i).Interior.ColorIndex = xlNone
        End If
    Next i

    ' Auto-fit colunas
    rng.Columns.AutoFit

    ' Freeze pane
    ws.Cells(2, 1).Select
    ActiveWindow.FreezePanes = True

    MsgBox "Formatação aplicada com sucesso!", vbInformation
End Sub

' ── Consolidar abas em uma única tabela ─────────────────────────
Sub ConsolidarAbas()
    Dim wsDest As Worksheet
    Dim wsSrc  As Worksheet
    Dim destRow As Long
    Dim srcLastRow As Long

    Set wsDest = ThisWorkbook.Sheets("Consolidado")
    wsDest.Cells.Clear
    destRow = 1

    Dim primeiraAba As Boolean
    primeiraAba = True

    For Each wsSrc In ThisWorkbook.Sheets
        If wsSrc.Name <> "Consolidado" Then
            srcLastRow = wsSrc.Cells(wsSrc.Rows.Count, 1).End(xlUp).Row
            If primeiraAba Then
                wsSrc.Rows(1).Copy wsDest.Cells(destRow, 1)  ' Copia header
                destRow = destRow + 1
                primeiraAba = False
            End If
            ' Copia dados (sem header)
            wsSrc.Range("A2:Z" & srcLastRow).Copy wsDest.Cells(destRow, 1)
            destRow = destRow + srcLastRow - 1
        End If
    Next wsSrc

    MsgBox "Consolidação concluída: " & destRow - 1 & " linhas", vbInformation
End Sub

' ── Enviar relatório por e-mail (Outlook) ───────────────────────
Sub EnviarRelatorio(destinatario As String, assunto As String)
    Dim outlook As Object
    Dim email As Object

    Set outlook = CreateObject("Outlook.Application")
    Set email = outlook.CreateItem(0)

    With email
        .To = destinatario
        .Subject = assunto
        .Body = "Segue em anexo o relatório de " & Format(Date, "dd/mm/yyyy") & "."
        .Attachments.Add ThisWorkbook.FullName
        .Send
    End With

    MsgBox "E-mail enviado para " & destinatario, vbInformation
End Sub
```

---

## 4. Dashboard em Excel — Estrutura Padrão

```
ESTRUTURA DE ABAS:
├── Config          → tabela de parâmetros (metas, períodos, cores)
├── Raw_Vendas      → dados brutos importados (não editar manualmente)
├── Raw_Metas       → tabela de metas
├── Calc_KPIs       → cálculos intermediários (PROCV, SOMASES, tabelas)
├── Calc_Mensal     → evolução mensal calculada
├── Dashboard       → painel visual (apenas fórmulas e gráficos)
└── _Aux            → lookup tables, listas de validação

REGRAS DO DASHBOARD:
  ✅ Dashboard deve conter APENAS fórmulas que referenciam abas Calc_
  ✅ Nunca inserir dados brutos no Dashboard
  ✅ Usar Named Ranges para KPIs principais (ex: kpi_receita, kpi_meta)
  ✅ Slicer ou segmentação de dados conectada a tabelas dinâmicas
  ✅ Formato condicional para semáforo de status (verde/amarelo/vermelho)
  ✅ Proteger células de cálculo (Ctrl+Shift+F9 para recalcular)
```

---

## 5. Integração Excel + Python (openpyxl / xlwings)

```python
import pandas as pd
import openpyxl
from openpyxl.chart import BarChart, Reference
from openpyxl.utils.dataframe import dataframe_to_rows

def atualizar_dashboard_excel(df: pd.DataFrame, template_path: str,
                               output_path: str) -> None:
    """Atualiza dados de um template Excel preservando formatação."""
    wb = openpyxl.load_workbook(template_path)
    ws = wb['Raw_Dados']

    # Limpar dados antigos (preserva header)
    for row in ws.iter_rows(min_row=2):
        for cell in row:
            cell.value = None

    # Inserir novos dados
    for r_idx, row in enumerate(dataframe_to_rows(df, index=False, header=False), 2):
        for c_idx, value in enumerate(row, 1):
            ws.cell(row=r_idx, column=c_idx, value=value)

    wb.save(output_path)
    print(f"✅ Dashboard atualizado: {output_path}")
```

---

## Regras de Qualidade

- Nomear ranges críticos: `kpi_receita`, `tbl_vendas`, `lst_regionais`
- Nunca mesclar células em tabelas de dados — apenas em headers visuais
- Power Query para transformação, nunca fórmulas complexas em dados brutos
- Proteger abas de cálculo; liberar apenas o Dashboard para o usuário
- VBA: declarar variáveis explicitamente (`Option Explicit`), tratar erros (`On Error GoTo`)
- Comentar macros VBA com propósito, entradas e saídas
- Versionar via timestamp no nome do arquivo: `relatorio_vendas_20240115.xlsx`

## Observações

Para automação de Excel integrada com SharePoint e Teams, use `automacoes-power-platform`.
Para processamento de múltiplos arquivos Excel em Python, use `python-analytics`.
Power Query M está disponível também no Power BI — mesma sintaxe.
