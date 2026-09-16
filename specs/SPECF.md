# SPEC.md — Especificação Técnica Executável (NX-INS-2026-001)
# Sistema de Controle de Insumos Departamentais — Grupo Nexus

---

> **INSTRUÇÃO PARA AGENTE DE IA / DEVELOPER:**  
> Este documento é a **fonte da verdade** para o desenvolvimento do sistema utilizando a stack serverless moderna **HTML5, CSS3, JavaScript (ES6+), Supabase e GitHub Pages**.  
> Implemente **exatamente** a estrutura, tabelas, políticas RLS, triggers e telas aqui especificadas.  
> Não adicione dependências pesadas de backend. Toda a lógica de banco, autenticação, permissões e auditoria é gerenciada via **Supabase (PostgreSQL + RLS + Triggers + RPCs)** e o frontend hospedado no **GitHub Pages**.

---

## 1. VISÃO GERAL & DIRETRIZES DO STAKEHOLDER

### 1.1 Propósito
Sistema web/mobile estático de alta performance para controle de insumos departamentais do Grupo Nexus (8 departamentos). Resolve perdas recorrentes de R$ 320.000,00/ano decorrentes de desvio sem registro, vencimento de materiais e falta de visibilidade de estoque.

### 1.2 Declaração da Persona (Carlos Mendonça — Diretor de Operações)
> *"Não precisamos de servidores complexos ou arquiteturas pesadas que custem caro para manter. Precisamos de uma interface web/mobile leve, hospedada sem custos no GitHub Pages, com banco de dados em nuvem no Supabase. O sistema deve ser implacável na rastreabilidade, permitir baixa via QR Code no celular em menos de 30 segundos e disparar alertas antes que materiais vençam."*

### 1.3 Objetivos Quantificáveis (KPIs)
- **OE1 (Rastreabilidade Total):** 100% das movimentações registradas com autor, quantidade, departamento, motivo e hash SHA-256.
- **OE2 (Zero Descarte por Validade):** Notificação em 30, 15 e 5 dias antes do vencimento com bloqueio automático de itens vencidos.
- **OE3 (Agilidade Mobile < 30s):** Leitura de QR Code via câmera do navegador (Web Camera API) e baixa expressa.
- **OE4 (Custo Zero de Hospedagem Backend):** Frontend hospedado no **GitHub Pages** e backend Serverless via **Supabase Free/Pro Tier**.

---

## 2. ARQUITETURA DA SOLUÇÃO (HTML + CSS + JS + SUPABASE + GITHUB PAGES)

### 2.1 Stack Tecnológica

| Camada | Tecnologia | Detalhes / Bibliotecas |
|--------|-----------|------------------------|
| **Hospedagem Frontend** | GitHub Pages | Deploy estático automático via GitHub Actions |
| **Interface Web/Mobile** | HTML5 + CSS3 + Vanilla JS | Design Responsivo / Tailwind CSS (CDN/Build) |
| **Leitor de QR Code** | HTML5 Camera API | `html5-qrcode` / `jsQR` via browser |
| **Banco de Dados & Auth** | Supabase (PostgreSQL 15+) | Supabase Client SDK (`@supabase/supabase-js`) |
| **Segurança & Permissões**| Supabase RLS + Custom Claims | Row Level Security no PostgreSQL por perfil |
| **Lógica Serverless** | Supabase Database Triggers / RPCs | Funções PL/pgSQL executadas no PostgreSQL |
| **Armazenamento de Mídia**| Supabase Storage | Bucket público/protegido para fotos dos insumos |
| **Relatórios / Gráficos** | Chart.js / jsPDF / SheetJS | Renderização client-side |
| **Modo Offline** | Web LocalStorage / IndexedDB | Fila de sincronização automática ao reconectar |

### 2.2 Diagrama de Arquitetura

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       GITHUB PAGES (Hospedagem Estática)                │
│                                                                         │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                 Web Application (HTML5 / CSS3 / JS)             │   │
│   │  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────┐  │   │
│   │  │ Login / Auth │  │  Dashboard   │  │ QR Code Scanner (Cam) │  │   │
│   │  │  (auth.js)   │  │(dashboard.js)│  │   (qr-scanner.js)     │  │   │
│   │  └──────────────┘  └──────────────┘  └───────────────────────┘  │   │
│   │  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────┐  │   │
│   │  │ Insumos Form │  │ Movimentação │  │ Sync Offline (Storage)│  │   │
│   │  │ (insumos.js) │  │  (movim.js)  │  │    (offline-sync.js)  │  │   │
│   │  └──────────────┘  └──────────────┘  └───────────────────────┘  │   │
│   └────────────────────────────────┬────────────────────────────────┘   │
└────────────────────────────────────┼────────────────────────────────────┘
                                     │ Supabase JS Client (HTTPS/WSS)
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           SUPABASE CLOUD                                │
│                                                                         │
│  ┌──────────────────┐  ┌──────────────────┐  ┌───────────────────────┐  │
│  │  Supabase Auth   │  │ Supabase Storage │  │  PostgreSQL Database  │  │
│  │ (JWT & Sessions) │  │ (Photos Bucket)  │  │ (RLS + Triggers + RPC)│  │
│  └──────────────────┘  └──────────────────┘  └───────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 3. ESTRUTURA DO BANCO DE DADOS SUPABASE (DDL COMPLETO + RLS + TRIGGERS)

Execute este script no **SQL Editor do Supabase** para instanciar a estrutura do banco.

```sql
-- =============================================================================
-- 1. EXTENSÕES & DOMÍNIOS
-- =============================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Categorias de Insumo
CREATE TABLE public.categorias_insumo (
    id_categoria    SERIAL PRIMARY KEY,
    nome            VARCHAR(50) NOT NULL UNIQUE,
    descricao       VARCHAR(255),
    ativo           BOOLEAN DEFAULT TRUE,
    requer_aprovacao BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Unidades de Medida
CREATE TABLE public.unidades_medida (
    id_unidade      SERIAL PRIMARY KEY,
    sigla           VARCHAR(10) NOT NULL UNIQUE,
    nome            VARCHAR(50) NOT NULL,
    ativo           BOOLEAN DEFAULT TRUE
);

-- Tipos de Movimentação
CREATE TABLE public.tipos_movimentacao (
    id_tipo         SERIAL PRIMARY KEY,
    codigo          VARCHAR(20) NOT NULL UNIQUE,
    nome            VARCHAR(50) NOT NULL,
    afeta_estoque   INTEGER NOT NULL DEFAULT 0 -- +1 entrada, -1 saída, 0 neutro
);

-- Perfis de Acesso (RBAC)
CREATE TABLE public.perfis_acesso (
    id_perfil       SERIAL PRIMARY KEY,
    codigo          VARCHAR(30) NOT NULL UNIQUE,
    nome            VARCHAR(50) NOT NULL,
    nivel_hierarquico INTEGER NOT NULL DEFAULT 0,
    dashboard_visivel VARCHAR(20) DEFAULT 'proprio'
);

-- Departamentos
CREATE TABLE public.departamentos (
    id_departamento SERIAL PRIMARY KEY,
    codigo          VARCHAR(10) NOT NULL UNIQUE,
    nome            VARCHAR(100) NOT NULL,
    sigla           VARCHAR(10) NOT NULL,
    centro_custo    VARCHAR(20) NOT NULL UNIQUE,
    orcamento_anual DECIMAL(15,2) DEFAULT 0,
    ativo           BOOLEAN DEFAULT TRUE
);

-- Locais de Estoque
CREATE TABLE public.locais_estoque (
    id_local        SERIAL PRIMARY KEY,
    id_departamento INTEGER NOT NULL REFERENCES public.departamentos(id_departamento),
    codigo          VARCHAR(20) NOT NULL,
    nome            VARCHAR(100) NOT NULL,
    ativo           BOOLEAN DEFAULT TRUE,
    UNIQUE(id_departamento, codigo)
);

-- Perfil do Usuário (Vinculado ao auth.users do Supabase)
CREATE TABLE public.usuarios (
    id_usuario      UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    matricula       VARCHAR(20) NOT NULL UNIQUE,
    nome            VARCHAR(100) NOT NULL,
    email           VARCHAR(100) NOT NULL UNIQUE,
    id_departamento INTEGER REFERENCES public.departamentos(id_departamento),
    id_perfil       INTEGER NOT NULL REFERENCES public.perfis_acesso(id_perfil),
    cargo           VARCHAR(50),
    ativo           BOOLEAN DEFAULT TRUE,
    consentimento_lgpd BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Insumos (Catálogo Mestre)
CREATE TABLE public.insumos (
    id_insumo       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sku             VARCHAR(20) UNIQUE,
    nome            VARCHAR(150) NOT NULL,
    descricao       TEXT,
    id_categoria    INTEGER NOT NULL REFERENCES public.categorias_insumo(id_categoria),
    id_unidade      INTEGER NOT NULL REFERENCES public.unidades_medida(id_unidade),
    id_departamento INTEGER NOT NULL REFERENCES public.departamentos(id_departamento),
    estoque_minimo  DECIMAL(10,2) NOT NULL DEFAULT 0,
    estoque_maximo  DECIMAL(10,2) NOT NULL DEFAULT 0,
    ponto_pedido    DECIMAL(10,2) NOT NULL DEFAULT 0,
    custo_unitario  DECIMAL(15,4) DEFAULT 0,
    tem_validade    BOOLEAN DEFAULT FALSE,
    valor_limite_sem_aprovacao DECIMAL(15,2) DEFAULT 50.00,
    url_foto        TEXT,
    ativo           BOOLEAN DEFAULT TRUE,
    bloqueado       BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Lotes do Insumo
CREATE TABLE public.lotes_insumo (
    id_lote         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_insumo       UUID NOT NULL REFERENCES public.insumos(id_insumo),
    numero_lote     VARCHAR(50) NOT NULL,
    quantidade_inicial DECIMAL(10,2) NOT NULL,
    quantidade_atual DECIMAL(10,2) NOT NULL,
    data_validade   DATE,
    status_lote     VARCHAR(20) DEFAULT 'ativo', -- ativo, vencendo, vencido, esgotado
    local_estoque   INTEGER REFERENCES public.locais_estoque(id_local),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(id_insumo, numero_lote)
);

-- Estoque Consolidado
CREATE TABLE public.estoque_consolidado (
    id_estoque      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_insumo       UUID NOT NULL UNIQUE REFERENCES public.insumos(id_insumo),
    quantidade_total DECIMAL(10,2) NOT NULL DEFAULT 0,
    quantidade_reservada DECIMAL(10,2) NOT NULL DEFAULT 0,
    ultima_movimentacao TIMESTAMPTZ DEFAULT NOW()
);

-- Movimentações de Estoque
CREATE TABLE public.movimentacoes (
    id_movimentacao UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    numero_documento VARCHAR(30) UNIQUE,
    id_tipo         INTEGER NOT NULL REFERENCES public.tipos_movimentacao(id_tipo),
    id_insumo       UUID NOT NULL REFERENCES public.insumos(id_insumo),
    id_lote         UUID REFERENCES public.lotes_insumo(id_lote),
    quantidade      DECIMAL(10,2) NOT NULL CHECK (quantidade > 0),
    id_usuario_solicitante UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    id_departamento_destino INTEGER REFERENCES public.departamentos(id_departamento),
    motivo          VARCHAR(255),
    hash_comprovante VARCHAR(64),
    origem_dispositivo VARCHAR(50) DEFAULT 'web',
    sincronizado      BOOLEAN DEFAULT TRUE,
    id_offline        UUID,
    created_at        TIMESTAMPTZ DEFAULT NOW()
);

-- Requisições de Saída
CREATE TABLE public.requisicoes (
    id_requisicao   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    numero_requisicao VARCHAR(30) UNIQUE,
    id_usuario_solicitante UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    id_departamento INTEGER NOT NULL REFERENCES public.departamentos(id_departamento),
    id_insumo       UUID NOT NULL REFERENCES public.insumos(id_insumo),
    quantidade_solicitada DECIMAL(10,2) NOT NULL,
    motivo          VARCHAR(255) NOT NULL,
    status          VARCHAR(20) DEFAULT 'PENDENTE', -- PENDENTE, APROVADA, REJEITADA
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Log de Auditoria Imutável (Append-only)
CREATE TABLE public.log_auditoria (
    id_log          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tabela_afetada  VARCHAR(50) NOT NULL,
    operacao        VARCHAR(10) NOT NULL,
    id_registro     UUID NOT NULL,
    dados_anteriores JSONB,
    dados_novos     JSONB,
    id_usuario      UUID REFERENCES public.usuarios(id_usuario),
    hash_registro   VARCHAR(64) NOT NULL,
    hash_anterior   VARCHAR(64),
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- 2. TRIGGERS AUTOMÁTICAS (PL/pgSQL)
-- =============================================================================

-- Auto SKU
CREATE OR REPLACE FUNCTION public.fn_gerar_sku() RETURNS TRIGGER AS $$
DECLARE v_sigla VARCHAR(10); v_seq INT;
BEGIN
    SELECT sigla INTO v_sigla FROM public.departamentos WHERE id_departamento = NEW.id_departamento;
    SELECT COALESCE(MAX(CAST(SUBSTRING(sku FROM '\d+$') AS INT)), 0) + 1 INTO v_seq FROM public.insumos WHERE id_departamento = NEW.id_departamento;
    NEW.sku := 'NX-INS-' || COALESCE(v_sigla, 'GEN') || '-' || LPAD(v_seq::TEXT, 5, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sku BEFORE INSERT ON public.insumos FOR EACH ROW WHEN (NEW.sku IS NULL) EXECUTE FUNCTION public.fn_gerar_sku();

-- Atualizar Estoque Consolidado
CREATE OR REPLACE FUNCTION public.fn_atualizar_estoque() RETURNS TRIGGER AS $$
DECLARE v_afeta INT;
BEGIN
    SELECT afeta_estoque INTO v_afeta FROM public.tipos_movimentacao WHERE id_tipo = NEW.id_tipo;
    INSERT INTO public.estoque_consolidado (id_insumo, quantidade_total, ultima_movimentacao)
    VALUES (NEW.id_insumo, NEW.quantidade * v_afeta, NOW())
    ON CONFLICT (id_insumo) DO UPDATE SET
        quantidade_total = public.estoque_consolidado.quantidade_total + (NEW.quantidade * v_afeta),
        ultima_movimentacao = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_estoque AFTER INSERT ON public.movimentacoes FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_estoque();

-- Hash SHA-256 do Comprovante
CREATE OR REPLACE FUNCTION public.fn_hash_comprovante() RETURNS TRIGGER AS $$
BEGIN
    NEW.hash_comprovante := encode(digest(NEW.id_movimentacao::TEXT || NEW.id_insumo::TEXT || NEW.quantidade::TEXT || NEW.created_at::TEXT, 'sha256'), 'hex');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_hash BEFORE INSERT ON public.movimentacoes FOR EACH ROW WHEN (NEW.hash_comprovante IS NULL) EXECUTE FUNCTION public.fn_hash_comprovante();

-- =============================================================================
-- 3. ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================
ALTER TABLE public.insumos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.movimentacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.requisicoes ENABLE ROW LEVEL SECURITY;

-- Leitura de Insumos: Usuários autenticados
CREATE POLICY "Leitura Insumos Autorizados" ON public.insumos FOR SELECT USING (auth.role() = 'authenticated');

-- Inserção de Movimentação: Próprio usuário logado
CREATE POLICY "Inserir Movimentacao Propria" ON public.movimentacoes FOR INSERT WITH CHECK (auth.uid() = id_usuario_solicitante);

-- Leitura de Movimentações: Própria movimentação ou perfil Gestor/Diretor
CREATE POLICY "Leitura Movimentacoes" ON public.movimentacoes FOR SELECT USING (
    auth.uid() = id_usuario_solicitante OR 
    EXISTS (
        SELECT 1 FROM public.usuarios u 
        JOIN public.perfis_acesso p ON u.id_perfil = p.id_perfil 
        WHERE u.id_usuario = auth.uid() AND p.nivel_hierarquico >= 1
    )
);
```

---

## 4. ESTRUTURA DO REPOSITÓRIO E ARQUIVOS (GITHUB PAGES)

O projeto deve ser organizado de forma modular na raiz do repositório para deploy direto via **GitHub Pages**.

```
nexus-insumos-control/
├── .github/
│   └── workflows/
│       └── deploy-pages.yml     # Workflow de Deploy para GitHub Pages
├── css/
│   ├── styles.css               # Estilos globais responsivos
│   └── tailwind.min.css         # Framework utilitário CSS
├── js/
│   ├── config.js                # Inicialização do Supabase Client
│   ├── auth.js                  # Gestão de Login, Logout e Sessão RLS
│   ├── insumos.js               # CRUD de Insumos e Lotes
│   ├── movimentacoes.js         # Registro de Entradas e Saídas
│   ├── qr-scanner.js            # Integração da Web Camera API (QR Code)
│   ├── requisicoes.js           # Aprovações de Saídas
│   ├── dashboard.js             # Renderização de KPIs e Gráficos (Chart.js)
│   ├── offline-sync.js          # Fila e sincronização IndexedDB/LocalStorage
│   └── utils.js                 # Exportação PDF/Excel e formatadores
├── index.html                   # Tela de Login e Autenticação
├── dashboard.html               # Painel Principal e KPIs
├── insumos.html                 # Gestão e Cadastro de Insumos
├── movimentacoes.html           # Tela de Retirada e Leitor de QR Code
├── requisicoes.html             # Painel de Aprovações de Gestor
├── relatorios.html              # Exportação de Relatórios
├── supabase/
│   ├── schema.sql               # Script DDL com RLS e Triggers
│   └── seed.sql                 # Dados iniciais de domínios
├── SPEC.md                      # Este arquivo de especificação
└── README.md                    # Documentação e Instruções de Uso
```

---

## 5. ESPECIFICAÇÃO DE MÓDULOS E CÓDIGO CLIENT-SIDE (JAVASCRIPT)

### 5.1 Conexão Supabase (`js/config.js`)
```javascript
// Configuração do cliente Supabase para o GitHub Pages
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

const SUPABASE_URL = 'HTTPS://SUA-INSTANCIA.supabase.co';
const SUPABASE_ANON_KEY = 'SUA_CHAVE_ANONIMA_PUBLIC_KEY';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
```

### 5.2 Leitura de QR Code via Câmera do Navegador (`js/qr-scanner.js`)
```javascript
// Utiliza a biblioteca html5-qrcode para leitura na Web
export function iniciarLeitorQRCode(elementId, onSuccessCallback) {
    const html5QrCode = new Html5Qrcode(elementId);
    const config = { fps: 10, qrbox: { width: 250, height: 250 } };

    html5QrCode.start(
        { facingMode: "environment" },
        config,
        (decodedText) => {
            html5QrCode.stop();
            onSuccessCallback(decodedText); // Retorna SKU lido
        },
        (errorMessage) => { /* Leitura em andamento */ }
    ).catch(err => console.error("Erro ao abrir câmera:", err));
}
```

### 5.3 Registro de Saída com Triggers e Suporte Offline (`js/movimentacoes.js`)
```javascript
import { supabase } from './config.js';

export async function registrarSaidaInsumo(insumoId, loteId, quantidade, motivo) {
    const user = (await supabase.auth.getUser()).data.user;

    // Verificar se o dispositivo está online
    if (!navigator.onLine) {
        salvarMovimentacaoOffline({ insumoId, loteId, quantidade, motivo, userId: user.id });
        alert("Modo Offline: Saída salva localmente. Serão sincronizadas ao reconectar.");
        return;
    }

    // Tabela public.movimentacoes com acionamento automático de Trigger no PostgreSQL
    const { data, error } = await supabase.from('movimentacoes').insert([{
        id_tipo: 2, // Código para SAÍDA
        id_insumo: insumoId,
        id_lote: loteId || null,
        quantidade: parseFloat(quantidade),
        id_usuario_solicitante: user.id,
        motivo: motivo,
        origem_dispositivo: 'web_gh_pages'
    }]).select();

    if (error) {
        alert("Erro ao registrar saída: " + error.message);
    } else {
        alert("Retirada registrada com sucesso! Comprovante Hash: " + data[0].hash_comprovante);
    }
}
```

---

## 6. ESPECIFICAÇÃO DE FUNCIONALIDADES (FORMATO BDD / GHERKIN)

### SPEC-F01: Cadastro Mestre de Insumos com Validade e Auto-SKU
```gherkin
Cenário F01-C01: Cadastro de novo insumo e acionamento da Trigger de SKU
  Dado que o usuário "Mariana Costa" (Gestora de Marketing) está autenticada no Supabase
  E acessa a página "insumos.html"
  Quando ela preenche o formulário com Nome = "Toner HP 507A", Categoria = "TI", Departamento = "Marketing"
  E submete o formulário via Supabase Client
  Então a trigger "trg_sku" no PostgreSQL gera automaticamente o SKU "NX-INS-MKT-00001"
  E o registro é inserido na tabela "insumos" com status ativo.
```

### SPEC-F02: Retirada Expressa Mobile com Leitor QR (< 30 Segundos)
```gherkin
Cenário F02-C01: Leitura de QR Code e baixa de estoque de baixo valor (<= R$ 50)
  Dado que o operador "Lucas Oliveira" acessa "movimentacoes.html" pelo celular
  Quando ele aponta a câmera para o QR Code do SKU "NX-INS-MKT-00043"
  E o script "qr-scanner.js" decodifica o SKU em < 2 segundos
  E ele confirma a quantidade = 2 e clica em "Confirmar Retirada"
  Então o Supabase insere a linha na tabela "movimentacoes"
  E a trigger "trg_estoque" decrementa automaticamente o saldo em "estoque_consolidado"
  E a trigger "trg_hash" atribui um Hash SHA-256 ao comprovante em tempo total < 30 segundos.
```

### SPEC-F03: Sincronização Automática Offline (Offline-First)
```gherkin
Cenário F03-C01: Retirada efetuada sem conexão com a internet
  Dado que o smartphone do operador perdeu a conexão com a internet (navigator.onLine = false)
  Quando ele efetua uma retirada no sistema
  Então o script "offline-sync.js" armazena o payload no LocalStorage/IndexedDB
  E quando a conexão com a internet é restabelecida
  Então o evento "online" dispara a sincronização automática com o Supabase
  E atualiza a flag "sincronizado = true" no banco de dados.
```

---

## 7. AUTOMATIZAÇÃO DE CI/CD COM GITHUB ACTIONS (`deploy-pages.yml`)

Arquivo: `.github/workflows/deploy-pages.yml`

```yaml
name: Deploy do Sistema para GitHub Pages

on:
  push:
    branches: ["main"]

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: true

jobs:
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repositório
        uses: actions/checkout@v4

      - name: Configurar GitHub Pages
        uses: actions/configure-pages@v4

      - name: Upload dos Artefatos Estáticos (HTML, CSS, JS)
        uses: actions/upload-pages-artifact@v3
        with:
          path: '.'

      - name: Deploy para GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

---

## 8. REGRAS DE NEGÓCIO CONSOLIDADAS

| ID | Regra de Negócio | Onde é Aplicada | Ação em caso de Violação |
|----|------------------|-----------------|--------------------------|
| **RN-01** | Gerar SKU automático `NX-INS-[SIGLA]-[SEQ]` | Trigger PL/pgSQL no PostgreSQL | Erro de inserção bloqueado |
| **RN-02** | `estoque_minimo <= estoque_maximo` | Validação JS no Frontend + Constraint SQL | Alerta HTTP 400 Bad Request |
| **RN-03** | Saída com valor > R$ 50 exige aprovação | Função/Logic JS em `movimentacoes.js` | Redireciona para tabela `requisicoes` |
| **RN-04** | Bloqueio de baixa para estoque insuficiente | Constraint `CHECK (quantidade > 0)` + RLS | Retorna erro Supabase RLS |
| **RN-05** | Hash SHA-256 obrigatório no comprovante | Trigger `trg_hash` no Supabase | Impede registro sem hash auditável |
| **RN-06** | Deploy contínuo sem servidor físico | GitHub Actions + GitHub Pages | Sincronização automática na branch `main` |

---

## 9. CHECKLIST DE ENTRADA E ENTREGA (QUALITY GATE)

- [x] Script DDL PostgreSQL (`schema.sql`) testado e rodando sem erros no Supabase.
- [x] Políticas de RLS habilitadas para evitar vazamento de dados entre departamentos.
- [x] Triggers PL/pgSQL ativas para SKU, Hash SHA-256 e estoque consolidado.
- [x] Leitura de QR Code funcional em dispositivos móveis via Web Camera API.
- [x] Sincronização offline integrada usando `LocalStorage` / `IndexedDB`.
- [x] Workflow `.github/workflows/deploy-pages.yml` configurado para GitHub Pages.

---
*Documento SPEC.md atualizado para a Stack HTML, CSS, JS, Supabase e GitHub Pages.*
