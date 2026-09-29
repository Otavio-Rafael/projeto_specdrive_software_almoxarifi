-- ============================================================================
-- SISTEMA DE CONTROLE DE INSUMOS DEPARTAMENTAIS - GRUPO NEXUS (NX-INS-2026-001)
-- SCRIPT DE SEED COMPLETO PARA POPULAÇÃO DE DOMÍNIOS E TESTES
-- ============================================================================

-- DOMÍNIOS E CATEGORIAS
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
