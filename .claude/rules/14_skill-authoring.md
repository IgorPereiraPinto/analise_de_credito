# Skill Authoring Rules

## Objetivo
Definir padrões para criação e revisão de skills reutilizáveis para Claude Code e Claude.ai.

## Quando usar
Use esta rule quando a demanda envolver criação de uma nova skill, padronização de SKILL.md, transformação de prompt em skill formal ou revisão da arquitetura de skills.

## Regras principais
- definir claramente o domínio e os triggers da skill
- manter a skill específica o suficiente para ser útil
- incluir frontmatter com `name` e `description`
- deixar claro quando usar e quando não usar
- definir entradas esperadas e formato de saída padrão
- incluir conteúdo técnico real, não apenas placeholders
- manter consistência com o restante do repositório
- evitar sobreposição excessiva com skills existentes

## Estrutura esperada
1. nome da skill
2. objetivo
3. quando usar
4. como atuar
5. entradas esperadas
6. formato de saída
7. conteúdo técnico
8. regras de qualidade
9. observações

## Regras de qualidade
- não criar skills genéricas demais
- não deixar a ativação ambígua
- não repetir habilidades já cobertas por outra skill sem necessidade
- priorizar reutilização, clareza e manutenção
- manter o conteúdo organizado e acionável

## Observações
Esta rule orienta a execução da skill `skill-authoring.md`.
