Este arquivo define as regras de governança, restrições e o fluxo operacional obrigatório para todos os agentes de IA (incluindo Google Jules) que operam neste repositório.

## 1. Princípio Fundamental: A Especificação é a Fonte Única da Verdade (SSOT)
* **Proibição de "Vibe Coding":** O agente não deve gerar código baseado em suposições ou prompts soltos do usuário. Toda e qualquer alteração no código fonte deve ser estritamente derivada de um arquivo de especificação (`SPEC.md` ou similar).
* **Fluxo de Alteração de Código:** O agente não pode modificar o código para corrigir comportamentos ou adicionar funcionalidades sem que a especificação técnica correspondente tenha sido revisada ou atualizada primeiro.
* **Falta de Contexto:** Se uma especificação omitir detalhes críticos de implementação ou regras de negócio, o agente deve interromper o processo imediatamente e solicitar clarificação ao usuário antes de prosseguir.

## 2. Papéis e Fluxo Operacional (Roles & Workflow)

### Arquiteto de Especificação (Spec Architect)
* **Responsabilidade:** Analisar os requisitos do usuário e atualizar os documentos de especificação, critérios de aceitação e arquitetura técnica.
* **Entregável:** Arquivos `.md` de especificação atualizados e revisados.