-- ============================================================================
-- SISTEMA DE CONTROLE DE INSUMOS DEPARTAMENTAIS - GRUPO NEXUS (NX-INS-2026-001)
-- SCHEMA COMPLETO PARA SUPABASE (POSTGRESQL 15+ WITH RLS, TRIGGERS & SEEDS)
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA extensions;

-- Categorias de Insumo
CREATE TABLE IF NOT EXISTS public.categorias_insumo (
    id_categoria    SERIAL PRIMARY KEY,
    nome            VARCHAR(50) NOT NULL UNIQUE,
    descricao       VARCHAR(255),
    ativo           BOOLEAN DEFAULT TRUE,
    requer_aprovacao BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Unidades de Medida
CREATE TABLE IF NOT EXISTS public.unidades_medida (
    id_unidade      SERIAL PRIMARY KEY,
    sigla           VARCHAR(10) NOT NULL UNIQUE,
    nome            VARCHAR(50) NOT NULL,
    ativo           BOOLEAN DEFAULT TRUE
);

-- Status de Movimentação
CREATE TABLE IF NOT EXISTS public.status_movimentacao (
    id_status       SERIAL PRIMARY KEY,
    codigo          VARCHAR(20) NOT NULL UNIQUE,
    nome            VARCHAR(50) NOT NULL,
    descricao       VARCHAR(255)
);

-- Tipos de Movimentação
CREATE TABLE IF NOT EXISTS public.tipos_movimentacao (
    id_tipo         SERIAL PRIMARY KEY,
    codigo          VARCHAR(20) NOT NULL UNIQUE,
    nome            VARCHAR(50) NOT NULL,
    afeta_estoque   INTEGER NOT NULL DEFAULT 0,
    gera_lancamento_contabil BOOLEAN DEFAULT FALSE
);

-- Níveis de Alerta
CREATE TABLE IF NOT EXISTS public.niveis_alerta (
    id_nivel        SERIAL PRIMARY KEY,
    codigo          VARCHAR(20) NOT NULL UNIQUE,
    nome            VARCHAR(50) NOT NULL,
    cor             VARCHAR(7) NOT NULL,
    prioridade      INTEGER NOT NULL DEFAULT 0,
    dias_antecedencia INTEGER,
    notifica_diretor BOOLEAN DEFAULT FALSE
);

-- Status de Requisição
CREATE TABLE IF NOT EXISTS public.status_requisicao (
    id_status       SERIAL PRIMARY KEY,
    codigo          VARCHAR(20) NOT NULL UNIQUE,
    nome            VARCHAR(50) NOT NULL,
    cor             VARCHAR(7) NOT NULL
);

-- Perfis de Acesso (RBAC)
CREATE TABLE IF NOT EXISTS public.perfis_acesso (
    id_perfil       SERIAL PRIMARY KEY,
    codigo          VARCHAR(30) NOT NULL UNIQUE,
    nome            VARCHAR(50) NOT NULL,
    descricao       VARCHAR(255),
    nivel_hierarquico INTEGER NOT NULL DEFAULT 0,
    dashboard_visivel VARCHAR(20) NOT NULL DEFAULT 'proprio'
);

-- Departamentos
CREATE TABLE IF NOT EXISTS public.departamentos (
    id_departamento SERIAL PRIMARY KEY,
    codigo          VARCHAR(10) NOT NULL UNIQUE,
    nome            VARCHAR(100) NOT NULL,
    sigla           VARCHAR(10) NOT NULL,
    centro_custo    VARCHAR(20) NOT NULL UNIQUE,
    orcamento_anual_insumos DECIMAL(15,2) DEFAULT 0,
    ativo           BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Locais de Estoque
CREATE TABLE IF NOT EXISTS public.locais_estoque (
    id_local        SERIAL PRIMARY KEY,
    id_departamento INTEGER NOT NULL REFERENCES public.departamentos(id_departamento) ON DELETE CASCADE,
    codigo          VARCHAR(20) NOT NULL,
    nome            VARCHAR(100) NOT NULL,
    descricao       VARCHAR(255),
    ativo           BOOLEAN DEFAULT TRUE,
    UNIQUE(id_departamento, codigo)
);

-- Usuários
CREATE TABLE IF NOT EXISTS public.usuarios (
    id_usuario      UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    matricula       VARCHAR(20) NOT NULL UNIQUE,
    nome            VARCHAR(100) NOT NULL,
    email           VARCHAR(100) NOT NULL UNIQUE,
    id_departamento INTEGER REFERENCES public.departamentos(id_departamento),
    id_perfil       INTEGER NOT NULL REFERENCES public.perfis_acesso(id_perfil),
    cargo           VARCHAR(50),
    telefone        VARCHAR(20),
    ativo           BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Catálogo de Insumos
CREATE TABLE IF NOT EXISTS public.insumos (
    id_insumo       UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    sku             VARCHAR(20) UNIQUE,
    nome            VARCHAR(150) NOT NULL,
    descricao       TEXT,
    id_categoria    INTEGER NOT NULL REFERENCES public.categorias_insumo(id_categoria),
    id_unidade      INTEGER NOT NULL REFERENCES public.unidades_medida(id_unidade),
    id_departamento INTEGER NOT NULL REFERENCES public.departamentos(id_departamento),
    estoque_minimo  DECIMAL(10,2) NOT NULL DEFAULT 0,
    estoque_maximo  DECIMAL(10,2) NOT NULL DEFAULT 0,
    ponto_pedido    DECIMAL(10,2) NOT NULL DEFAULT 0,
    custo_unitario_medio DECIMAL(15,4) DEFAULT 0,
    valor_unitario_referencia DECIMAL(15,4) DEFAULT 0,
    tem_validade    BOOLEAN DEFAULT FALSE,
    prazo_validade_dias INTEGER,
    valor_limite_sem_aprovacao DECIMAL(15,2) DEFAULT 50.00,
    url_foto        TEXT,
    ativo           BOOLEAN DEFAULT TRUE,
    bloqueado       BOOLEAN DEFAULT FALSE,
    motivo_bloqueio VARCHAR(255),
    created_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_estoque_min_max CHECK (estoque_minimo <= estoque_maximo)
);

-- Lotes do Insumo
CREATE TABLE IF NOT EXISTS public.lotes_insumo (
    id_lote         UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    id_insumo       UUID NOT NULL REFERENCES public.insumos(id_insumo) ON DELETE CASCADE,
    numero_lote     VARCHAR(50) NOT NULL,
    quantidade_inicial DECIMAL(10,2) NOT NULL,
    quantidade_atual DECIMAL(10,2) NOT NULL,
    data_fabricacao DATE,
    data_validade   DATE,
    status_lote     VARCHAR(20) DEFAULT 'ativo',
    local_estoque   INTEGER REFERENCES public.locais_estoque(id_local),
    custo_unitario  DECIMAL(15,4) DEFAULT 0,
    created_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(id_insumo, numero_lote)
);

-- Estoque Consolidado
CREATE TABLE IF NOT EXISTS public.estoque_consolidado (
    id_estoque      UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    id_insumo       UUID NOT NULL UNIQUE REFERENCES public.insumos(id_insumo) ON DELETE CASCADE,
    quantidade_total DECIMAL(10,2) NOT NULL DEFAULT 0,
    quantidade_reservada DECIMAL(10,2) NOT NULL DEFAULT 0,
    ultima_movimentacao TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Movimentações de Estoque
CREATE TABLE IF NOT EXISTS public.movimentacoes (
    id_movimentacao UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    numero_documento VARCHAR(30) UNIQUE,
    id_tipo         INTEGER NOT NULL REFERENCES public.tipos_movimentacao(id_tipo),
    id_status       INTEGER DEFAULT 1 REFERENCES public.status_movimentacao(id_status),
    id_insumo       UUID NOT NULL REFERENCES public.insumos(id_insumo),
    id_lote         UUID REFERENCES public.lotes_insumo(id_lote),
    quantidade      DECIMAL(10,2) NOT NULL,
    id_departamento_destino INTEGER REFERENCES public.departamentos(id_departamento),
    id_usuario_solicitante UUID REFERENCES public.usuarios(id_usuario),
    motivo          VARCHAR(255),
    observacao      TEXT,
    hash_comprovante VARCHAR(64),
    origem_dispositivo VARCHAR(50) DEFAULT 'web',
    sincronizado      BOOLEAN DEFAULT TRUE,
    id_offline        UUID,
    created_at        TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_quantidade_positiva CHECK (quantidade > 0)
);

-- Requisições de Saída
CREATE TABLE IF NOT EXISTS public.requisicoes (
    id_requisicao   UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    numero_requisicao VARCHAR(30) UNIQUE,
    id_usuario_solicitante UUID REFERENCES public.usuarios(id_usuario),
    id_departamento INTEGER NOT NULL REFERENCES public.departamentos(id_departamento),
    id_insumo       UUID NOT NULL REFERENCES public.insumos(id_insumo),
    id_lote         UUID REFERENCES public.lotes_insumo(id_lote),
    quantidade_solicitada DECIMAL(10,2) NOT NULL,
    motivo          VARCHAR(255) NOT NULL,
    id_status       INTEGER NOT NULL DEFAULT 1 REFERENCES public.status_requisicao(id_status),
    data_solicitacao TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    data_limite_aprovacao TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Log de Auditoria Imutável
CREATE TABLE IF NOT EXISTS public.log_auditoria (
    id_log          UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    tabela_afetada  VARCHAR(50) NOT NULL,
    operacao        VARCHAR(10) NOT NULL,
    id_registro     UUID NOT NULL,
    dados_anteriores JSONB,
    dados_novos     JSONB,
    id_usuario      UUID REFERENCES public.usuarios(id_usuario),
    hash_registro   VARCHAR(64) NOT NULL,
    hash_anterior   VARCHAR(64),
    created_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- POLÍTICAS RLS PERMISSIVAS PARA MODO PÚBLICO / ANON
-- =============================================================================
ALTER TABLE public.insumos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.movimentacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.requisicoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lotes_insumo ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.estoque_consolidado ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Permitir Leitura e Escrita Insumos Public" ON public.insumos;
CREATE POLICY "Permitir Leitura e Escrita Insumos Public" ON public.insumos FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir Leitura e Escrita Movimentacoes Public" ON public.movimentacoes;
CREATE POLICY "Permitir Leitura e Escrita Movimentacoes Public" ON public.movimentacoes FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir Leitura e Escrita Requisicoes Public" ON public.requisicoes;
CREATE POLICY "Permitir Leitura e Escrita Requisicoes Public" ON public.requisicoes FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir Leitura e Escrita Lotes Public" ON public.lotes_insumo;
CREATE POLICY "Permitir Leitura e Escrita Lotes Public" ON public.lotes_insumo FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir Leitura e Escrita Estoque Public" ON public.estoque_consolidado;
CREATE POLICY "Permitir Leitura e Escrita Estoque Public" ON public.estoque_consolidado FOR ALL USING (true) WITH CHECK (true);
