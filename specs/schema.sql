-- ============================================================================
-- SISTEMA DE CONTROLE DE INSUMOS DEPARTAMENTAIS - GRUPO NEXUS (NX-INS-2026-001)
-- SCHEMA COMPLETO PARA SUPABASE (POSTGRESQL 15+ WITH RLS, TRIGGERS & SEEDS)
-- ============================================================================
-- Instruções: Copie este script e execute diretamente no "SQL Editor" do Supabase.
-- ============================================================================

-- =============================================================================
-- 1. EXTENSÕES
-- =============================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA extensions;

-- =============================================================================
-- 2. TABELAS DE DOMÍNIO / LOOKUPS
-- =============================================================================

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
    afeta_estoque   INTEGER NOT NULL DEFAULT 0, -- +1 entrada, -1 saída, 0 neutro
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
    nivel_hierarquico INTEGER NOT NULL DEFAULT 0, -- 0=operador, 1=gestor, 2=diretor, 3=ceo, 4=admin
    dashboard_visivel VARCHAR(20) NOT NULL DEFAULT 'proprio'
);

-- Permissões Granulares
CREATE TABLE IF NOT EXISTS public.permissoes (
    id_permissao    SERIAL PRIMARY KEY,
    codigo          VARCHAR(50) NOT NULL UNIQUE,
    nome            VARCHAR(100) NOT NULL,
    modulo          VARCHAR(30) NOT NULL,
    acao            VARCHAR(20) NOT NULL
);

-- Relação Perfil - Permissão
CREATE TABLE IF NOT EXISTS public.perfil_permissao (
    id_perfil       INTEGER NOT NULL REFERENCES public.perfis_acesso(id_perfil) ON DELETE CASCADE,
    id_permissao    INTEGER NOT NULL REFERENCES public.permissoes(id_permissao) ON DELETE CASCADE,
    PRIMARY KEY (id_perfil, id_permissao)
);

-- =============================================================================
-- 3. TABELAS ORGANIZACIONAIS
-- =============================================================================

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

-- =============================================================================
-- 4. USUÁRIOS E PERMISSÕES (SUPABASE AUTH LINKED)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.usuarios (
    id_usuario      UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    matricula       VARCHAR(20) NOT NULL UNIQUE,
    nome            VARCHAR(100) NOT NULL,
    email           VARCHAR(100) NOT NULL UNIQUE,
    id_departamento INTEGER REFERENCES public.departamentos(id_departamento),
    id_perfil       INTEGER NOT NULL REFERENCES public.perfis_acesso(id_perfil),
    cargo           VARCHAR(50),
    telefone        VARCHAR(20),
    ativo           BOOLEAN DEFAULT TRUE,
    ultimo_acesso   TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    consentimento_lgpd BOOLEAN DEFAULT FALSE,
    data_consentimento TIMESTAMPTZ,
    dados_anonimizados BOOLEAN DEFAULT FALSE
);

-- =============================================================================
-- 5. TABELAS DE INSUMOS E LOTES
-- =============================================================================

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
    sap_item_code   VARCHAR(50),
    sap_sync_at     TIMESTAMPTZ,
    sap_sync_status VARCHAR(20) DEFAULT 'pending',
    created_by      UUID REFERENCES public.usuarios(id_usuario),
    created_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_by      UUID REFERENCES public.usuarios(id_usuario),
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
    status_lote     VARCHAR(20) DEFAULT 'ativo', -- ativo, vencendo, vencido, esgotado
    local_estoque   INTEGER REFERENCES public.locais_estoque(id_local),
    custo_unitario  DECIMAL(15,4) DEFAULT 0,
    sap_batch_number VARCHAR(50),
    created_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(id_insumo, numero_lote)
);

-- =============================================================================
-- 6. TABELAS DE ESTOQUE
-- =============================================================================

-- Estoque Consolidado
CREATE TABLE IF NOT EXISTS public.estoque_consolidado (
    id_estoque      UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    id_insumo       UUID NOT NULL UNIQUE REFERENCES public.insumos(id_insumo) ON DELETE CASCADE,
    quantidade_total DECIMAL(10,2) NOT NULL DEFAULT 0,
    quantidade_reservada DECIMAL(10,2) NOT NULL DEFAULT 0,
    ultima_movimentacao TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Posição de Estoque por Lote e Local
CREATE TABLE IF NOT EXISTS public.estoque_posicao (
    id_posicao      UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    id_lote         UUID NOT NULL REFERENCES public.lotes_insumo(id_lote) ON DELETE CASCADE,
    id_local        INTEGER NOT NULL REFERENCES public.locais_estoque(id_local),
    quantidade      DECIMAL(10,2) NOT NULL DEFAULT 0,
    updated_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(id_lote, id_local)
);

-- =============================================================================
-- 7. MOVIMENTAÇÕES E REQUISIÇÕES
-- =============================================================================

-- Movimentações de Estoque
CREATE TABLE IF NOT EXISTS public.movimentacoes (
    id_movimentacao UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    numero_documento VARCHAR(30) UNIQUE,
    id_tipo         INTEGER NOT NULL REFERENCES public.tipos_movimentacao(id_tipo),
    id_status       INTEGER NOT NULL REFERENCES public.status_movimentacao(id_status),
    id_insumo       UUID NOT NULL REFERENCES public.insumos(id_insumo),
    id_lote         UUID REFERENCES public.lotes_insumo(id_lote),
    quantidade      DECIMAL(10,2) NOT NULL,
    id_local_origem INTEGER REFERENCES public.locais_estoque(id_local),
    id_local_destino INTEGER REFERENCES public.locais_estoque(id_local),
    id_departamento_origem INTEGER REFERENCES public.departamentos(id_departamento),
    id_departamento_destino INTEGER REFERENCES public.departamentos(id_departamento),
    id_usuario_solicitante UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    id_usuario_executor UUID REFERENCES public.usuarios(id_usuario),
    id_requisicao   UUID,
    motivo          VARCHAR(255),
    observacao      TEXT,
    hash_comprovante VARCHAR(64),
    comprovante_gerado_at TIMESTAMPTZ,
    custo_unitario  DECIMAL(15,4),
    origem_dispositivo VARCHAR(50) DEFAULT 'web',
    sincronizado      BOOLEAN DEFAULT TRUE,
    data_sincronizacao TIMESTAMPTZ,
    id_offline        UUID,
    sap_doc_entry     VARCHAR(50),
    sap_sync_at       TIMESTAMPTZ,
    sap_sync_status   VARCHAR(20) DEFAULT 'pending',
    created_at        TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_quantidade_positiva CHECK (quantidade > 0)
);

-- Requisições de Saída
CREATE TABLE IF NOT EXISTS public.requisicoes (
    id_requisicao   UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    numero_requisicao VARCHAR(30) UNIQUE,
    id_usuario_solicitante UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    id_departamento INTEGER NOT NULL REFERENCES public.departamentos(id_departamento),
    id_insumo       UUID NOT NULL REFERENCES public.insumos(id_insumo),
    id_lote         UUID REFERENCES public.lotes_insumo(id_lote),
    quantidade_solicitada DECIMAL(10,2) NOT NULL,
    motivo          VARCHAR(255) NOT NULL,
    finalidade      VARCHAR(255),
    id_status       INTEGER NOT NULL REFERENCES public.status_requisicao(id_status),
    nivel_aprovacao_necessario INTEGER DEFAULT 1,
    id_aprovador_nivel1 UUID REFERENCES public.usuarios(id_usuario),
    data_aprovacao_nivel1 TIMESTAMPTZ,
    justificativa_nivel1 TEXT,
    id_aprovador_nivel2 UUID REFERENCES public.usuarios(id_usuario),
    data_aprovacao_nivel2 TIMESTAMPTZ,
    justificativa_nivel2 TEXT,
    rejeitado_por   UUID REFERENCES public.usuarios(id_usuario),
    data_rejeicao   TIMESTAMPTZ,
    motivo_rejeicao TEXT,
    id_movimentacao UUID REFERENCES public.movimentacoes(id_movimentacao),
    data_solicitacao TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    data_limite_aprovacao TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 8. ALERTAS E AUDITORIA
-- =============================================================================

-- Alertas Gerados
CREATE TABLE IF NOT EXISTS public.alertas (
    id_alerta       UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    id_nivel        INTEGER NOT NULL REFERENCES public.niveis_alerta(id_nivel),
    id_insumo       UUID REFERENCES public.insumos(id_insumo),
    id_lote         UUID REFERENCES public.lotes_insumo(id_lote),
    id_departamento INTEGER REFERENCES public.departamentos(id_departamento),
    titulo          VARCHAR(200) NOT NULL,
    mensagem        TEXT NOT NULL,
    dados_json      JSONB,
    id_usuario_destinatario UUID REFERENCES public.usuarios(id_usuario),
    enviado_email   BOOLEAN DEFAULT FALSE,
    enviado_push    BOOLEAN DEFAULT FALSE,
    enviado_dashboard BOOLEAN DEFAULT FALSE,
    data_envio      TIMESTAMPTZ,
    lido            BOOLEAN DEFAULT FALSE,
    data_leitura    TIMESTAMPTZ,
    acao_tomada     VARCHAR(50),
    id_usuario_acao UUID REFERENCES public.usuarios(id_usuario),
    data_acao       TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Log de Auditoria Imutável (Append-only)
CREATE TABLE IF NOT EXISTS public.log_auditoria (
    id_log          UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    tabela_afetada  VARCHAR(50) NOT NULL,
    operacao        VARCHAR(10) NOT NULL,
    id_registro     UUID NOT NULL,
    dados_anteriores JSONB,
    dados_novos     JSONB,
    id_usuario      UUID REFERENCES public.usuarios(id_usuario),
    ip_address      INET,
    user_agent      VARCHAR(500),
    session_id      VARCHAR(100),
    hash_registro   VARCHAR(64) NOT NULL,
    hash_anterior   VARCHAR(64),
    created_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Log de Acesso
CREATE TABLE IF NOT EXISTS public.log_acesso (
    id_log          UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    id_usuario      UUID NOT NULL REFERENCES public.usuarios(id_usuario),
    acao            VARCHAR(50) NOT NULL,
    recurso         VARCHAR(100),
    id_recurso      UUID,
    ip_address      INET,
    user_agent      VARCHAR(500),
    sucesso         BOOLEAN DEFAULT TRUE,
    detalhes        JSONB,
    created_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 9. CONFIGURAÇÕES E ANALYTICS
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.configuracoes (
    id_config       SERIAL PRIMARY KEY,
    chave           VARCHAR(100) NOT NULL UNIQUE,
    valor           TEXT NOT NULL,
    tipo            VARCHAR(20) NOT NULL DEFAULT 'string',
    descricao       VARCHAR(255),
    modulo          VARCHAR(30),
    editavel        BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.historico_consumo (
    id_historico    UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    id_insumo       UUID NOT NULL REFERENCES public.insumos(id_insumo),
    id_departamento INTEGER NOT NULL REFERENCES public.departamentos(id_departamento),
    ano_mes         VARCHAR(6) NOT NULL, -- YYYYMM
    quantidade_consumida DECIMAL(10,2) NOT NULL DEFAULT 0,
    valor_consumido DECIMAL(15,2) NOT NULL DEFAULT 0,
    quantidade_requisicoes INTEGER DEFAULT 0,
    created_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(id_insumo, id_departamento, ano_mes)
);

CREATE TABLE IF NOT EXISTS public.sugestoes_compra (
    id_sugestao     UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    id_insumo       UUID NOT NULL REFERENCES public.insumos(id_insumo),
    id_departamento INTEGER NOT NULL REFERENCES public.departamentos(id_departamento),
    estoque_atual   DECIMAL(10,2) NOT NULL,
    ponto_pedido    DECIMAL(10,2) NOT NULL,
    consumo_medio_mensal DECIMAL(10,2) NOT NULL,
    quantidade_sugerida DECIMAL(10,2) NOT NULL,
    justificativa_calculo TEXT,
    status          VARCHAR(20) DEFAULT 'pendente',
    id_pedido_compra UUID,
    sap_pedido_numero VARCHAR(50),
    created_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 10. VIEWS PARA DASHBOARDS E RELATÓRIOS
-- =============================================================================

-- View: Estoque por Departamento
CREATE OR REPLACE VIEW public.vw_estoque_por_departamento AS
SELECT 
    d.id_departamento,
    d.nome AS departamento,
    d.sigla,
    COUNT(DISTINCT i.id_insumo) AS total_insumos,
    COALESCE(SUM(ec.quantidade_total), 0) AS total_itens_estoque,
    COALESCE(SUM(ec.quantidade_total * i.custo_unitario_medio), 0) AS valor_total_estoque,
    COUNT(DISTINCT CASE WHEN ec.quantidade_total <= i.ponto_pedido THEN i.id_insumo END) AS itens_estoque_baixo,
    COUNT(DISTINCT CASE WHEN l.status_lote = 'vencendo' THEN l.id_lote END) AS lotes_vencendo,
    COUNT(DISTINCT CASE WHEN l.status_lote = 'vencido' THEN l.id_lote END) AS lotes_vencidos
FROM public.departamentos d
LEFT JOIN public.insumos i ON i.id_departamento = d.id_departamento AND i.ativo = TRUE
LEFT JOIN public.estoque_consolidado ec ON ec.id_insumo = i.id_insumo
LEFT JOIN public.lotes_insumo l ON l.id_insumo = i.id_insumo
WHERE d.ativo = TRUE
GROUP BY d.id_departamento, d.nome, d.sigla;

-- View: Insumos Críticos
CREATE OR REPLACE VIEW public.vw_insumos_criticos AS
SELECT 
    i.id_insumo,
    i.sku,
    i.nome AS insumo,
    d.nome AS departamento,
    d.sigla,
    c.nome AS categoria,
    COALESCE(ec.quantidade_total, 0) AS estoque_atual,
    i.ponto_pedido,
    i.estoque_minimo,
    CASE 
        WHEN COALESCE(ec.quantidade_total, 0) <= i.estoque_minimo THEN 'CRITICO'
        WHEN COALESCE(ec.quantidade_total, 0) <= i.ponto_pedido THEN 'BAIXO'
        ELSE 'NORMAL'
    END AS status_estoque,
    l.numero_lote,
    l.data_validade,
    l.status_lote AS status_validade,
    i.custo_unitario_medio
FROM public.insumos i
JOIN public.departamentos d ON d.id_departamento = i.id_departamento
JOIN public.categorias_insumo c ON c.id_categoria = i.id_categoria
LEFT JOIN public.estoque_consolidado ec ON ec.id_insumo = i.id_insumo
LEFT JOIN public.lotes_insumo l ON l.id_insumo = i.id_insumo AND l.status_lote IN ('vencendo', 'vencido')
WHERE i.ativo = TRUE
  AND (COALESCE(ec.quantidade_total, 0) <= i.ponto_pedido OR l.status_lote IN ('vencendo', 'vencido'));

-- View: Requisições Pendentes
CREATE OR REPLACE VIEW public.vw_requisicoes_pendentes AS
SELECT 
    r.id_requisicao,
    r.numero_requisicao,
    i.sku,
    i.nome AS insumo,
    r.quantidade_solicitada,
    d.nome AS departamento,
    u.nome AS solicitante,
    r.motivo,
    sr.nome AS status,
    r.data_solicitacao,
    r.data_limite_aprovacao,
    EXTRACT(EPOCH FROM (r.data_limite_aprovacao - CURRENT_TIMESTAMP))/3600 AS horas_restantes
FROM public.requisicoes r
JOIN public.insumos i ON i.id_insumo = r.id_insumo
JOIN public.departamentos d ON d.id_departamento = r.id_departamento
JOIN public.usuarios u ON u.id_usuario = r.id_usuario_solicitante
JOIN public.status_requisicao sr ON sr.id_status = r.id_status
WHERE r.id_status = 1 -- PENDENTE
ORDER BY r.data_limite_aprovacao ASC;

-- =============================================================================
-- 11. FUNÇÕES E TRIGGERS AUTOMÁTICAS (PL/pgSQL)
-- =============================================================================

-- Função: Gerar SKU Automático
CREATE OR REPLACE FUNCTION public.fn_gerar_sku()
RETURNS TRIGGER AS $$
DECLARE
    v_sigla VARCHAR(10);
    v_seq INT;
BEGIN
    SELECT sigla INTO v_sigla FROM public.departamentos WHERE id_departamento = NEW.id_departamento;
    SELECT COALESCE(MAX(CAST(SUBSTRING(sku FROM '\d+$') AS INT)), 0) + 1 INTO v_seq 
    FROM public.insumos WHERE id_departamento = NEW.id_departamento;
    
    NEW.sku := 'NX-INS-' || COALESCE(v_sigla, 'GEN') || '-' || LPAD(v_seq::TEXT, 5, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_gerar_sku ON public.insumos;
CREATE TRIGGER trg_gerar_sku
    BEFORE INSERT ON public.insumos
    FOR EACH ROW WHEN (NEW.sku IS NULL)
    EXECUTE FUNCTION public.fn_gerar_sku();

-- Função: Gerar Número de Documento de Movimentação
CREATE OR REPLACE FUNCTION public.fn_gerar_numero_documento()
RETURNS TRIGGER AS $$
DECLARE
    v_seq INT;
    v_prefixo VARCHAR(15);
BEGIN
    v_prefixo := 'MOV-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-';
    SELECT COALESCE(MAX(CAST(SUBSTRING(numero_documento FROM '\d+$') AS INT)), 0) + 1 INTO v_seq
    FROM public.movimentacoes WHERE numero_documento LIKE v_prefixo || '%';
    
    NEW.numero_documento := v_prefixo || LPAD(v_seq::TEXT, 6, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_gerar_numero_documento ON public.movimentacoes;
CREATE TRIGGER trg_gerar_numero_documento
    BEFORE INSERT ON public.movimentacoes
    FOR EACH ROW WHEN (NEW.numero_documento IS NULL)
    EXECUTE FUNCTION public.fn_gerar_numero_documento();

-- Função: Gerar Número de Requisição com SLA 48h
CREATE OR REPLACE FUNCTION public.fn_gerar_numero_requisicao()
RETURNS TRIGGER AS $$
DECLARE
    v_seq INT;
    v_prefixo VARCHAR(15);
BEGIN
    v_prefixo := 'REQ-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-';
    SELECT COALESCE(MAX(CAST(SUBSTRING(numero_requisicao FROM '\d+$') AS INT)), 0) + 1 INTO v_seq
    FROM public.requisicoes WHERE numero_requisicao LIKE v_prefixo || '%';
    
    NEW.numero_requisicao := v_prefixo || LPAD(v_seq::TEXT, 6, '0');
    NEW.data_limite_aprovacao := COALESCE(NEW.data_solicitacao, CURRENT_TIMESTAMP) + INTERVAL '48 hours';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_gerar_numero_requisicao ON public.requisicoes;
CREATE TRIGGER trg_gerar_numero_requisicao
    BEFORE INSERT ON public.requisicoes
    FOR EACH ROW WHEN (NEW.numero_requisicao IS NULL)
    EXECUTE FUNCTION public.fn_gerar_numero_requisicao();

-- Função: Atualizar Estoque Consolidado
CREATE OR REPLACE FUNCTION public.fn_atualizar_estoque()
RETURNS TRIGGER AS $$
DECLARE
    v_afeta INT;
    v_delta DECIMAL(10,2);
BEGIN
    SELECT afeta_estoque INTO v_afeta FROM public.tipos_movimentacao WHERE id_tipo = NEW.id_tipo;
    v_delta := NEW.quantidade * COALESCE(v_afeta, 0);

    INSERT INTO public.estoque_consolidado (id_insumo, quantidade_total, ultima_movimentacao)
    VALUES (NEW.id_insumo, v_delta, NEW.created_at)
    ON CONFLICT (id_insumo) DO UPDATE SET
        quantidade_total = public.estoque_consolidado.quantidade_total + v_delta,
        ultima_movimentacao = NEW.created_at,
        updated_at = CURRENT_TIMESTAMP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_atualizar_estoque ON public.movimentacoes;
CREATE TRIGGER trg_atualizar_estoque
    AFTER INSERT ON public.movimentacoes
    FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_estoque();

-- Função: Atualizar Status do Lote por Validade
CREATE OR REPLACE FUNCTION public.fn_atualizar_status_lote()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.data_validade IS NOT NULL THEN
        IF NEW.data_validade < CURRENT_DATE THEN
            NEW.status_lote := 'vencido';
        ELSIF NEW.data_validade <= CURRENT_DATE + INTERVAL '15 days' THEN
            NEW.status_lote := 'vencendo';
        ELSIF NEW.quantidade_atual <= 0 THEN
            NEW.status_lote := 'esgotado';
        ELSE
            NEW.status_lote := 'ativo';
        END IF;
    ELSIF NEW.quantidade_atual <= 0 THEN
        NEW.status_lote := 'esgotado';
    ELSE
        NEW.status_lote := 'ativo';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_atualizar_status_lote ON public.lotes_insumo;
CREATE TRIGGER trg_atualizar_status_lote
    BEFORE INSERT OR UPDATE ON public.lotes_insumo
    FOR EACH ROW EXECUTE FUNCTION public.fn_atualizar_status_lote();

-- Função: Hash SHA-256 do Comprovante
CREATE OR REPLACE FUNCTION public.fn_hash_comprovante()
RETURNS TRIGGER AS $$
BEGIN
    NEW.hash_comprovante := encode(
        extensions.digest(
            NEW.id_movimentacao::TEXT || NEW.id_insumo::TEXT || NEW.quantidade::TEXT || 
            NEW.id_usuario_solicitante::TEXT || NEW.created_at::TEXT,
            'sha256'
        ), 'hex'
    );
    NEW.comprovante_gerado_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_hash_comprovante ON public.movimentacoes;
CREATE TRIGGER trg_hash_comprovante
    BEFORE INSERT ON public.movimentacoes
    FOR EACH ROW WHEN (NEW.hash_comprovante IS NULL)
    EXECUTE FUNCTION public.fn_hash_comprovante();

-- Função: Trilha de Auditoria Imutável (Append-only)
CREATE OR REPLACE FUNCTION public.fn_registrar_auditoria()
RETURNS TRIGGER AS $$
DECLARE
    v_hash_ant VARCHAR(64);
    v_novos JSONB;
    v_antigos JSONB;
BEGIN
    SELECT hash_registro INTO v_hash_ant FROM public.log_auditoria ORDER BY created_at DESC LIMIT 1;

    IF TG_OP = 'INSERT' THEN
        v_novos := to_jsonb(NEW);
    ELSIF TG_OP = 'UPDATE' THEN
        v_novos := to_jsonb(NEW);
        v_antigos := to_jsonb(OLD);
    ELSIF TG_OP = 'DELETE' THEN
        v_antigos := to_jsonb(OLD);
    END IF;

    INSERT INTO public.log_auditoria (
        tabela_afetada, operacao, id_registro, dados_anteriores, dados_novos,
        id_usuario, hash_registro, hash_anterior
    ) VALUES (
        TG_TABLE_NAME, TG_OP,
        COALESCE(NEW.id_insumo, OLD.id_insumo, NEW.id_usuario, OLD.id_usuario, NEW.id_movimentacao, OLD.id_movimentacao),
        v_antigos, v_novos, auth.uid(),
        encode(extensions.digest(
            TG_TABLE_NAME || TG_OP || COALESCE(v_novos::TEXT, '') || COALESCE(v_hash_ant, ''), 'sha256'
        ), 'hex'),
        v_hash_ant
    );
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Triggers de Auditoria
DROP TRIGGER IF EXISTS trg_audit_insumos ON public.insumos;
CREATE TRIGGER trg_audit_insumos AFTER INSERT OR UPDATE OR DELETE ON public.insumos
FOR EACH ROW EXECUTE FUNCTION public.fn_registrar_auditoria();

DROP TRIGGER IF EXISTS trg_audit_movimentacoes ON public.movimentacoes;
CREATE TRIGGER trg_audit_movimentacoes AFTER INSERT OR UPDATE OR DELETE ON public.movimentacoes
FOR EACH ROW EXECUTE FUNCTION public.fn_registrar_auditoria();

-- =============================================================================
-- 12. SUPABASE ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================

ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.insumos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lotes_insumo ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.estoque_consolidado ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.movimentacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.requisicoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alertas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.log_auditoria ENABLE ROW LEVEL SECURITY;

-- Politicas para Usuarios
CREATE POLICY "Leitura de Perfis por Autenticados" ON public.usuarios
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Atualizar Proprio Perfil" ON public.usuarios
    FOR UPDATE USING (auth.uid() = id_usuario);

-- Politicas para Insumos
CREATE POLICY "Leitura Geral de Insumos" ON public.insumos
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Inserção/Edição de Insumos por Gestores/Admin" ON public.insumos
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.usuarios u
            JOIN public.perfis_acesso p ON u.id_perfil = p.id_perfil
            WHERE u.id_usuario = auth.uid() AND p.nivel_hierarquico >= 1
        )
    );

-- Politicas para Lotes e Estoque Consolidado
CREATE POLICY "Leitura Lotes Autenticados" ON public.lotes_insumo FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Leitura Estoque Autenticados" ON public.estoque_consolidado FOR SELECT USING (auth.role() = 'authenticated');

-- Politicas para Movimentacoes
CREATE POLICY "Criar Movimentação Propria" ON public.movimentacoes
    FOR INSERT WITH CHECK (auth.uid() = id_usuario_solicitante);

CREATE POLICY "Leitura de Movimentações Permitidas" ON public.movimentacoes
    FOR SELECT USING (
        auth.uid() = id_usuario_solicitante OR
        EXISTS (
            SELECT 1 FROM public.usuarios u
            JOIN public.perfis_acesso p ON u.id_perfil = p.id_perfil
            WHERE u.id_usuario = auth.uid() AND p.nivel_hierarquico >= 1
        )
    );

-- Politicas para Requisições
CREATE POLICY "Criar Requisição Própria" ON public.requisicoes
    FOR INSERT WITH CHECK (auth.uid() = id_usuario_solicitante);

CREATE POLICY "Leitura e Aprovação de Requisições" ON public.requisicoes
    FOR ALL USING (
        auth.uid() = id_usuario_solicitante OR
        EXISTS (
            SELECT 1 FROM public.usuarios u
            JOIN public.perfis_acesso p ON u.id_perfil = p.id_perfil
            WHERE u.id_usuario = auth.uid() AND p.nivel_hierarquico >= 1
        )
    );

-- Politicas para Alertas
CREATE POLICY "Leitura de Alertas Destinados" ON public.alertas
    FOR SELECT USING (
        id_usuario_destinatario = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.usuarios u
            JOIN public.perfis_acesso p ON u.id_perfil = p.id_perfil
            WHERE u.id_usuario = auth.uid() AND p.nivel_hierarquico >= 2
        )
    );

-- =============================================================================
-- 13. SEED DE DADOS INICIAIS (LOOKUPS & DOMÍNIOS)
-- =============================================================================

INSERT INTO public.categorias_insumo (nome, descricao, requer_aprovacao) VALUES
('Escritório', 'Materiais de escritório e expediente', FALSE),
('TI', 'Insumos de Tecnologia da Informação', TRUE),
('Limpeza', 'Materiais de higiene e limpeza', FALSE),
('Produção', 'Insumos para linha de produção', TRUE),
('Eventos', 'Materiais de marketing e eventos', FALSE),
('Outros', 'Demais itens não especificados', FALSE)
ON CONFLICT (nome) DO NOTHING;

INSERT INTO public.unidades_medida (sigla, nome) VALUES
('un', 'Unidade'),
('cx', 'Caixa'),
('pct', 'Pacote'),
('kg', 'Quilograma'),
('lt', 'Litro'),
('rs', 'Resma')
ON CONFLICT (sigla) DO NOTHING;

INSERT INTO public.tipos_movimentacao (codigo, nome, afeta_estoque, gera_lancamento_contabil) VALUES
('ENTRADA', 'Entrada de Estoque', 1, TRUE),
('SAIDA', 'Saída de Estoque', -1, TRUE),
('TRANSFERENCIA', 'Transferência Interna', 0, FALSE),
('BAIXA_VENCIDO', 'Baixa por Vencimento', -1, TRUE),
('BAIXA_PERDA', 'Baixa por Perda ou Avaria', -1, TRUE)
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO public.status_movimentacao (codigo, nome, descricao) VALUES
('CONCLUIDA', 'Concluída', 'Movimentação realizada com sucesso'),
('PENDENTE', 'Pendente', 'Aguardando aprovação ou sincronização'),
('CANCELADA', 'Cancelada', 'Movimentação cancelada')
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO public.niveis_alerta (codigo, nome, cor, prioridade, dias_antecedencia, notifica_diretor) VALUES
('vencimento_30d', 'Vencimento em 30 dias', '#FFA500', 2, 30, FALSE),
('vencimento_15d', 'Vencimento em 15 dias', '#FF8C00', 3, 15, FALSE),
('vencimento_5d', 'Vencimento em 5 dias', '#FF0000', 4, 5, TRUE),
('estoque_baixo', 'Estoque Baixo', '#FFD700', 2, NULL, FALSE),
('estoque_critico', 'Estoque Crítico', '#FF0000', 4, NULL, TRUE)
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO public.status_requisicao (codigo, nome, cor) VALUES
('PENDENTE', 'Pendente de Aprovação', '#FFD700'),
('APROVADA', 'Aprovada', '#008000'),
('REJEITADA', 'Rejeitada', '#FF0000'),
('CANCELADA', 'Cancelada por SLA', '#808080')
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO public.perfis_acesso (codigo, nome, descricao, nivel_hierarquico, dashboard_visivel) VALUES
('OPERADOR', 'Operador', 'Colaborador que solicita e retira insumos', 0, 'proprio'),
('GESTOR_DEPTO', 'Gestor de Departamento', 'Responsável pelas aprovações do departamento', 1, 'proprio'),
('DIRETOR_OPS', 'Diretor de Operações', 'Visão operacional total dos 8 departamentos', 2, 'todos'),
('CONTROLLER', 'Controller / Financeiro', 'Visão contábil e orçamentária', 2, 'todos'),
('CEO', 'Diretor-Presidente', 'Visão executiva anonimizada', 3, 'consolidado'),
('ADMIN', 'Administrador do Sistema', 'Acesso irrestrito a configurações', 4, 'todos')
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO public.departamentos (codigo, nome, sigla, centro_custo, orcamento_anual_insumos) VALUES
('DEPT-001', 'Recursos Humanos', 'RH', 'CC-1010-RH', 45000.00),
('DEPT-002', 'Tecnologia da Informação', 'TI', 'CC-2010-TI', 85000.00),
('DEPT-003', 'Financeiro', 'FIN', 'CC-3010-FIN', 35000.00),
('DEPT-004', 'Comercial', 'COM', 'CC-4010-COM', 55000.00),
('DEPT-005', 'Logística', 'LOG', 'CC-5010-LOG', 40000.00),
('DEPT-006', 'Produção', 'PROD', 'CC-6010-PROD', 120000.00),
('DEPT-007', 'Jurídico', 'JUR', 'CC-7010-JUR', 25000.00),
('DEPT-008', 'Marketing', 'MKT', 'CC-8010-MKT', 65000.00)
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO public.locais_estoque (id_departamento, codigo, nome, descricao) VALUES
(1, 'ARM-RH-01', 'Armário RH - Principal', 'Armário de insumos do RH'),
(2, 'ARM-TI-01', 'Almoxarifado TI', 'Sala de estoque TI - Subsolo'),
(8, 'ARM-MKT-01', 'Armário Marketing', 'Prateleira A - Materiais de evento')
ON CONFLICT (id_departamento, codigo) DO NOTHING;

-- =============================================================================
-- 14. SUPABASE STORAGE BUCKET CONFIGURATION (FOTOS DOS INSUMOS)
-- =============================================================================

INSERT INTO storage.buckets (id, name, public) 
VALUES ('insumos-fotos', 'insumos-fotos', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Public Read Access Photos" ON storage.objects
    FOR SELECT USING (bucket_id = 'insumos-fotos');

CREATE POLICY "Authenticated Upload Photos" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'insumos-fotos' AND 
        auth.role() = 'authenticated'
    );

-- ============================================================================
-- FIM DO SCRIPT SCHEMA.SQL
-- ============================================================================
