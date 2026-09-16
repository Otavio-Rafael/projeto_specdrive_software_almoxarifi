# Projeto SpecDrive - Sistema de Controle de Insumos Departamentais (Grupo Nexus)

> **Documento de Referência:** `SPEC.md` | **Código da Especificação:** NX-INS-2026-001
> **Stack:** HTML5, CSS3 (Tailwind CSS), Vanilla JS (ES6+), Supabase (PostgreSQL + RLS + Triggers) e GitHub Pages.

---

## 🚀 Visão Geral

O **Nexus StorageControl** é um sistema web/mobile serverless desenvolvido para eliminar perdas de estoque, garantir rastreabilidade total (100% auditado via Hash SHA-256) e prover baixa expressa de materiais via leitor de QR Code integrado à câmera do navegador em menos de 30 segundos.

---

## 📁 Estrutura do Repositório

```text
.
├── .github/
│   └── workflows/
│       └── deploy-pages.yml     # Workflow CI/CD de Deploy no GitHub Pages
├── css/
│   └── styles.css               # Estilos globais e variáveis do Design System Nexus
├── js/
│   ├── config.js                # Inicialização do Cliente Supabase
│   ├── utils.js                 # Auxiliares de moeda, datas, PDF (jsPDF) e Excel (SheetJS)
│   ├── offline-sync.js          # Engine resiliência offline (IndexedDB / LocalStorage)
│   ├── qr-scanner.js            # Leitura de QR Code via Web Camera API
│   ├── dashboard.js             # Módulo de KPIs e gráficos Chart.js
│   ├── insumos.js               # CRUD de Insumos, regras de estoque min/máx e Auto-SKU
│   ├── movimentacoes.js         # Retirada expressa mobile, validação RN-03 (> R$ 50) e comprovante SHA-256
│   ├── requisicoes.js           # Painel de aprovações de gestor (SLA 48h)
│   └── relatorios.js            # Trilha de auditoria imutável e exportações
├── index.html                   # Redirecionamento de entrada
├── dashboard.html               # Painel Executivo / KPIs / Alertas de Validade
├── insumos.html                 # Catálogo Mestre de Insumos & Impressão QR Code
├── movimentacoes.html           # Tela Mobile-First de Baixa e Leitor QR Code
├── requisicoes.html             # Painel de Aprovações do Gestor
├── relatorios.html              # Trilha de Auditoria e Exportação PDF/Excel
└── supabase/
    ├── schema.sql               # Script DDL PostgreSQL (Tabelas, RLS, Triggers, Views)
    └── seed.sql                 # Dados iniciais de domínios e departamentos
```

---

## ⚡ Como Executar Localmente

Como a aplicação é 100% estática (Serverless Frontend):

1. **Clone este repositório:**
   ```bash
   git clone https://github.com/seu-usuario/projeto_specdrive_software_almoxarifi.git
   cd projeto_specdrive_software_almoxarifi
   ```

2. **Execute um servidor estático local:**
   - Com Python:
     ```bash
     python -m http.server 8000
     ```
   - Com Node / `npx http-server`:
     ```bash
     npx http-server . -p 8000
     ```
   - Ou utilize a extensão **Live Server** no VS Code apontando para a raiz do projeto.

3. **Acesse no navegador:** `http://localhost:8000` ou `http://localhost:8000/dashboard.html`.

---

## 🗄️ Configuração do Banco de Dados (Supabase)

A aplicação está configurada no arquivo `js/config.js` com a instância:
- **Supabase URL:** `https://ctycpwdlywxzlwavckmf.supabase.co`
- **Publishable Key:** `sb_publishable_Ab2dk2FdbvVUFF5V6L72mQ_f3b7lmCW`

Para criar a estrutura em um novo projeto Supabase:
1. Abra o **SQL Editor** do console Supabase.
2. Copie e execute o conteúdo de `supabase/schema.sql`.
3. Em seguida, execute o script de domínios `supabase/seed.sql`.

---

## 🛠️ Regras de Negócio e KPIs Atendidos

- **OE1 (Rastreabilidade SHA-256):** Toda baixa de estoque gera um comprovante imutável auditável.
- **OE2 (Zero Descarte por Validade):** Alertas destacados no Dashboard para vencimentos em 30, 15 e 5 dias.
- **OE3 (Agilidade Mobile < 30s):** Leitura instantânea de QR Code via câmera web em smartphones.
- **RN-02 (Estoque Mínimo / Máximo):** Validação impede cadastro com `estoque_minimo > estoque_maximo`.
- **RN-03 (Alçada de Aprovação R$ 50):** Retiradas com valor > R$ 50,00 geram solicitações pendentes no painel de aprovações.
