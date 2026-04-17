# Git DataOps Rules

## Objetivo
Definir padrões para versionamento, organização de projeto, qualidade de código e práticas DataOps em times de dados.

## Quando usar
Use esta rule quando a demanda envolver Git, branches, commits, pull requests, CI/CD, ambiente virtual, requirements, `.env`, pre-commit, estrutura de projeto ou governança técnica para dados.

## Regras principais
- tratar pipeline de dados como código de produção
- usar versionamento com clareza e disciplina
- adotar estrutura de projeto organizada e reprodutível
- usar conventional commits quando aplicável
- separar dependências de produção e desenvolvimento
- proteger segredos e credenciais
- considerar lint, testes e CI antes de merge
- documentar o projeto de forma mínima e útil

## Estrutura esperada
1. contexto do projeto
2. estrutura recomendada
3. fluxo de versionamento
4. padrões de commit e branch
5. qualidade e automação
6. riscos e observações
7. próximos passos

## Regras de qualidade
- nunca commitar credenciais ou dados sensíveis
- não usar branch principal como área de desenvolvimento direto
- não deixar projeto sem README, `.gitignore` e `.env.example`
- não ignorar testes e validações mínimas
- priorizar rastreabilidade, colaboração e reprodutibilidade

## Observações
Esta rule orienta a execução da skill `git-dataops.md`.
