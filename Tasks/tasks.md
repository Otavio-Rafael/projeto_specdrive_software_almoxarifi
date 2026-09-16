# TASKS.md — Plano de Execução e Tarefas para Agente de IA / Desenvolvedor

> **SISTEMA DE CONTROLE DE INSUMOS DEPARTAMENTAIS — GRUPO NEXUS (NX-INS-2026-001)**  
> **Stack:** HTML5, CSS3 (Tailwind CSS), Vanilla JS (ES6+), Supabase (PostgreSQL 15+, RLS, Triggers, Storage), GitHub Pages.  
> **Referência:** `SPEC.md` / `schema.sql`

---

## 📋 VISÃO GERAL DO PLANO DE IMPLEMENTAÇÃO

Este documento contém a relação hierárquica e ordenada de tarefas atômicas necessárias para construir o sistema completo. Cada tarefa contém o arquivo-alvo, objetivo claro, dependências e critério de aceite (Definition of Done).

---

## FASE 1: INFRAESTRUTURA & BANCO DE DADOS SUPABASE

### [ ] TASK-101: Configuração da Estrutura Inicial e Workflow de CI/CD
- **Arquivo-Alvo:** `.github/workflows/deploy-pages.yml` e estrutura de diretórios do repositório
- **Objetivo:** Criar a estrutura completa de pastas do projeto conforme a seção 4 do `SPEC.md` e configurar o GitHub Actions para deploy estático automatizado no GitHub Pages ao realizar push na branch `main`.
- **Dependências:** Nenhuma.
- **Critério de Aceite:**
  - Diretórios `/css`, `/js`, `/supabase`, `.github/workflows` criados.
  - Workflow `deploy-pages.yml` testado e validado sintaticamente.

---

### [ ] TASK-102: Implantação do Schema SQL no Supabase
- **Arquivo-Alvo:** `supabase/schema.sql`
- **Objetivo:** Garantir que o script DDL contendo a criação de tabelas, extensões (`uuid-ossp`, `pgcrypto`), restrições, views (`vw_estoque_por_departamento`, `vw_insumos_criticos`, `vw_requisicoes_pendentes`), funções PL/pgSQL, triggers e políticas RLS seja versionado no repositório.
- **Dependências:** TASK-101
- **Critério de Aceite:**
  - Script `supabase/schema.sql` atualizado e executável sem erros no SQL Editor do Supabase.
  - Habilitação de RLS ativada para todas as tabelas transacionais.

---

### [ ] TASK-103: População de Dados Iniciais (Seed SQL)
- **Arquivo-Alvo:** `supabase/seed.sql`
- **Objetivo:** Criar um arquivo SQL contendo os dados iniciais de domínios (departamentos do Grupo Nexus, unidades de medida, categorias de insumo, tipos de movimentação, perfis de acesso e locais de estoque padrão).
- **Dependências:** TASK-102
- **Critério de Aceite:**
  - Inserção dos 8 departamentos com seus respectivos centros de custo.
  - Inserção dos perfis de acesso (OPERADOR, GESTOR_DEPTO, DIRETOR_OPS, CONTROLLER, CEO, ADMIN).

---

### [ ] TASK-104: Configuração de Bucket de Mídia no Supabase Storage
- **Arquivo-Alvo:** `supabase/schema.sql` (seção de storage)
- **Objetivo:** Configurar a criação do bucket `insumos-fotos` com visibilidade pública para leitura e políticas RLS para upload apenas por usuários autenticados.
- **Dependências:** TASK-102
- **Critério de Aceite:**
  - Bucket `insumos-fotos` registrado.
  - Políticas de upload e leitura aplicadas corretamente no Supabase.

---

## FASE 2: NÚCLEO CLIENT-SIDE & AUTENTICAÇÃO (JS / HTML)

### [ ] TASK-201: Módulo de Configuração do Cliente Supabase
- **Arquivo-Alvo:** `js/config.js`
- **Objetivo:** Instanciar o cliente Supabase via CDN ES6 Module (`@supabase/supabase-js@2`), exportando a instância `supabase` e constantes globais de ambiente (URL e ANON_KEY).
- **Dependências:** TASK-101
- **Critério de Aceite:**
  - Módulo exporta `supabase` utilizando ES6 syntax.
  - Tratamento para alertar desenvolvedor caso as variáveis de ambiente não estejam configuradas.

---

### [ ] TASK-202: Módulo de Autenticação e Controle de Sessão
- **Arquivo-Alvo:** `js/auth.js`
- **Objetivo:** Implementar funções para login com e-mail/senha, logout, verificação de sessão ativa, obtenção do perfil do usuário logado (join com `public.usuarios` e `public.perfis_acesso`) e redirecionamento de páginas não autorizadas.
- **Dependências:** TASK-201
- **Critério de Aceite:**
  - Função `login(email, password)` funcional.
  - Função `logout()` encerra a sessão e limpa credenciais.
  - Guarda de rotas: redireciona para `index.html` se o usuário tentar acessar páginas protegidas sem estar autenticado.

---

### [ ] TASK-203: Interface Visual da Tela de Login
- **Arquivo-Alvo:** `index.html` e `css/styles.css`
- **Objetivo:** Desenvolver a página de login responsiva (Mobile e Desktop) utilizando Tailwind CSS, com formulário de autenticação, feedback de erro/sucesso e indicador de carregamento.
- **Dependências:** TASK-202
- **Critério de Aceite:**
  - Design limpo, profissional e alinhado à identidade do Grupo Nexus.
  - Validação de campos obrigatórios no frontend.
  - Integração total com `js/auth.js`.

---

### [ ] TASK-204: Módulo de Utilitários e Exportação de Documentos
- **Arquivo-Alvo:** `js/utils.js`
- **Objetivo:** Desenvolver funções auxiliares para formatação de moeda (BRL), formatação de datas, geração de QR Code visual (via biblioteca `qrcode.js`), e exportação de tabelas para PDF (`jsPDF`) e Excel (`SheetJS`).
- **Dependências:** TASK-101
- **Critério de Aceite:**
  - Função `formatarMoeda(valor)` retorna `R$ X,XX`.
  - Função `exportarParaExcel(dados, nomeArquivo)` gera arquivo `.xlsx`.
  - Função `exportarParaPDF(elementId, titulo)` gera PDF com cabeçalho do Grupo Nexus.

---

## FASE 3: GESTÃO DO CATÁLOGO DE INSUMOS E LOTES

### [ ] TASK-301: Módulo de Lógica para Cadastro e Consulta de Insumos
- **Arquivo-Alvo:** `js/insumos.js`
- **Objetivo:** Implementar as operações de CRUD para insumos e lotes, incluindo upload de imagem para o Supabase Storage, validação de estoque mínimo/máximo (`RN-02`) e consulta por departamento ou busca textual.
- **Dependências:** TASK-201, TASK-202, TASK-104
- **Critério de Aceite:**
  - Inserção dispara a Trigger PL/pgSQL de SKU automático (`NX-INS-[SIGLA]-[SEQ]`).
  - Upload de fotos insere a URL pública gerada no campo `url_foto`.
  - Validação impede cadastrar `estoque_minimo > estoque_maximo`.

---

### [ ] TASK-302: Interface Visual de Gestão de Insumos
- **Arquivo-Alvo:** `insumos.html`
- **Objetivo:** Construir a interface com tabela listando os insumos cadastrados, badges de status de estoque (Normal, Baixo, Crítico), filtro por categoria e departamento, e modal para cadastro/edição de insumo com upload de foto.
- **Dependências:** TASK-301, TASK-204
- **Critério de Aceite:**
  - Tabela responsiva com paginação e busca em tempo real.
  - Modal intuitivo permitindo cadastrar lote e data de validade.
  - Botão para exibir e imprimir QR Code do SKU do insumo.

---

## FASE 4: MOVIMENTAÇÃO DE ESTOQUE & QR CODE (RETIRADA EXPRESSA)

### [ ] TASK-401: Módulo de Leitura de QR Code via Web Camera API
- **Arquivo-Alvo:** `js/qr-scanner.js`
- **Objetivo:** Criar o componente de leitura de QR Code utilizando a biblioteca `html5-qrcode` para acessar a câmera do smartphone/notebook via navegador e capturar o SKU impresso no insumo.
- **Dependências:** TASK-101
- **Critério de Aceite:**
  - Inicialização da câmera do dispositivo (`facingMode: "environment"`).
  - Leitura em < 2 segundos com retorno do SKU decodificado para preenchimento automático do formulário de baixa.
  - Tratamento para navegadores sem permissão de câmera.

---

### [ ] TASK-402: Módulo de Lógica para Retirada e Entrada de Estoque
- **Arquivo-Alvo:** `js/movimentacoes.js`
- **Objetivo:** Implementar as funções de lançamento de movimentação. Aplicar a Regra de Negócio `RN-03`: retiradas com valor total <= R$ 50,00 realizam baixa direta; retiradas com valor > R$ 50,00 ou categorias com flag `requer_aprovacao = true` criam uma solicitação na tabela `requisicoes`.
- **Dependências:** TASK-201, TASK-401, TASK-301
- **Critério de Aceite:**
  - Baixa expressa concluída em < 30 segundos (`OE3`).
  - Acionamento automático da Trigger `trg_estoque` e geração do Hash SHA-256 (`trg_hash`).
  - Redirecionamento automático para requisição em caso de exceder R$ 50,00.

---

### [ ] TASK-403: Interface Mobile-First de Movimentação de Estoque
- **Arquivo-Alvo:** `movimentacoes.html`
- **Objetivo:** Construir uma página otimizada para smartphones com botão de destaque para "Escanear QR Code", formulário rápido de quantidade e motivo, e exibição imediata do comprovante com o Hash SHA-256 gerado.
- **Dependências:** TASK-401, TASK-402
- **Critério de Aceite:**
  - Interface fluida com botões grandes para toque em telas móveis.
  - Modal de confirmação exibindo o saldo atual e o saldo projetado do insumo.

---

## FASE 5: OPERAÇÃO OFFLINE-FIRST (OFFLINE SYNC)

### [ ] TASK-501: Módulo de Sincronização Local (IndexedDB / LocalStorage)
- **Arquivo-Alvo:** `js/offline-sync.js`
- **Objetivo:** Desenvolver o mecanismo de resiliência offline. Quando `navigator.onLine` for `false`, as baixas de estoque devem ser salvas na fila local (`IndexedDB` ou `LocalStorage`). Ao detectar o evento `online`, realizar o flush da fila enviando as movimentações para o Supabase.
- **Dependências:** TASK-402
- **Critério de Aceite:**
  - Armazenamento local estruturado do payload da movimentação com ID temporário (`id_offline`).
  - Event listener `window.addEventListener('online', ...)` sincroniza os itens pendentes sem duplicação.
  - Atualização da flag `sincronizado = true` após persistência no banco.

---

## FASE 6: GESTÃO DE REQUISIÇÕES & APROVAÇÕES

### [ ] TASK-601: Módulo de Lógica de Aprovações de Saída
- **Arquivo-Alvo:** `js/requisicoes.js`
- **Objetivo:** Criar as funções para listagem de requisições pendentes por departamento, aprovação/rejeição por gestores (nível hierárquico >= 1) e efetivação da movimentação de estoque após aprovação.
- **Dependências:** TASK-201, TASK-202, TASK-402
- **Critério de Aceite:**
  - Apenas gestores/diretores do departamento podem aprovar.
  - Ao aprovar, o sistema converte a requisição em uma movimentação de saída real na tabela `movimentacoes`.
  - Tratamento para SLA de aprovação (alertar requisições pendentes há mais de 48h).

---

### [ ] TASK-602: Interface do Painel de Aprovações do Gestor
- **Arquivo-Alvo:** `requisicoes.html`
- **Objetivo:** Desenvolver a página de gestão de requisições com abas ("Pendentes", "Aprovadas", "Rejeitadas"), modal com detalhes da solicitação e botões de ação expressa ("Aprovar", "Rejeitar com Justificativa").
- **Dependências:** TASK-601, TASK-204
- **Critério de Aceite:**
  - Badge visual destacando o número de solicitações aguardando aprovação.
  - Campo obrigatório para motivo de rejeição.

---

## FASE 7: DASHBOARD, ANALYTICS & RELATÓRIOS

### [ ] TASK-701: Módulo de Lógica para Renderização de KPIs e Gráficos
- **Arquivo-Alvo:** `js/dashboard.js`
- **Objetivo:** Integrar a biblioteca `Chart.js` via CDN para consultar views do Supabase (`vw_estoque_por_departamento`, `vw_insumos_criticos`) e renderizar indicadores quantitativos (Valor Total em Estoque, Itens Críticos, Lotes Vencendo, Movimentações no Mês).
- **Dependências:** TASK-201, TASK-301, TASK-402
- **Critério de Aceite:**
  - Gráfico de pizza/rosca: Distribuição do valor estocado por departamento.
  - Gráfico de barras: Consumo de insumos nos últimos 6 meses.
  - Respeito à visibilidade por perfil (`dashboard_visivel`: 'proprio' vs 'todos').

---

### [ ] TASK-702: Painel Principal (Dashboard Executivo)
- **Arquivo-Alvo:** `dashboard.html`
- **Objetivo:** Construir o dashboard principal do sistema contendo os cartões de KPIs no topo, seção de alertas de validade (30, 15 e 5 dias), gráficos interativos e tabela rápida de insumos com estoque crítico.
- **Dependências:** TASK-701, TASK-204
- **Critério de Aceite:**
  - Atualização automática dos cards a cada carregamento.
  - Alertas com cores indicativas (Amarelo = 30d, Laranja = 15d, Vermelho = 5d / Vencido).

---

### [ ] TASK-703: Interface de Relatórios e Auditoria
- **Arquivo-Alvo:** `relatorios.html`
- **Objetivo:** Criar a página para geração de relatórios customizados (Relatório de Consumo por Centro de Custo, Trilha de Auditoria com Hash SHA-256 e Relatório de Validade de Lotes) com opção de exportação em PDF e Excel.
- **Dependências:** TASK-701, TASK-204
- **Critério de Aceite:**
  - Filtro por período de datas, departamento e categoria.
  - Exibição transparente da trilha de auditoria imutável (`log_auditoria`).

---

## FASE 8: POLIMENTO, QUALITY GATE & DEPLOY FINAL

### [ ] TASK-801: Documentação e Guia de Utilização
- **Arquivo-Alvo:** `README.md`
- **Objetivo:** Elaborar o arquivo `README.md` completo com instruções de instalação, configuração das variáveis do Supabase, execução local e guia passo a passo para o usuário final.
- **Dependências:** Todas as fases anteriores.
- **Critério de Aceite:**
  - Instruções claras de como executar o projeto sem necessidade de Node.js (servidor HTTP simples como `Live Server` ou Python `http.server`).

---

### [ ] TASK-802: Validação Integrada do Quality Gate
- **Arquivo-Alvo:** Todo o repositório
- **Objetivo:** Realizar a verificação ponta a ponta dos cenários de teste BDD descritos no `SPEC.md` (SPEC-F01, SPEC-F02, SPEC-F03).
- **Dependências:** TASK-801
- **Critério de Aceite:**
  - Retirada mobile realizada e auditada via QR Code em < 30s.
  - Sincronização offline validada simulando desativação da rede no navegador.
  - Deploy final no GitHub Pages funcionando 100% via GitHub Actions.

---
*Plano de Tarefas (tasks.md) gerado para execução automatizada por Agentes de IA.*
