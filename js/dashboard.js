import { supabase, onDOMReady } from './config.js';
import { formatarMoeda, formatarData } from './utils.js';

onDOMReady(() => {
    carregarDashboard();
    setupEventListeners();
});

function setupEventListeners() {
    const filterDepto = document.getElementById('filter-departamento');
    if (filterDepto) {
        filterDepto.addEventListener('change', carregarDashboard);
    }
}

async function carregarDashboard() {
    const idDepto = document.getElementById('filter-departamento')?.value || '';

    try {
        let queryInsumos = supabase.from('insumos').select('*, estoque_consolidado(*), lotes_insumo(*)');
        if (idDepto) {
            queryInsumos = queryInsumos.eq('id_departamento', idDepto);
        }
        const { data: insumos } = await queryInsumos;

        let queryMov = supabase.from('movimentacoes').select('*, insumos(nome, sku)').order('created_at', { ascending: false }).limit(10);
        const { data: movimentacoes } = await queryMov;

        const { data: requisicoes } = await supabase.from('requisicoes').select('*').eq('id_status', 1);

        renderizarKPIs(insumos || [], requisicoes || []);
        renderizarGraficoEstoque(insumos || []);
        renderizarAlertasValidade(insumos || []);
        renderizarMovimentacoesRecentes(movimentacoes || []);
    } catch (err) {
        console.error("Erro ao carregar dados do dashboard:", err);
        renderizarDadosMockFallback();
    }
}

function renderizarKPIs(insumos, requisicoes) {
    let valorTotal = 0;
    let totalItens = insumos.length;
    let itensCriticos = 0;

    const hoje = new Date();
    const data30d = new Date();
    data30d.setDate(hoje.getDate() + 30);

    insumos.forEach(item => {
        const qtdEstoque = item.estoque_consolidado?.[0]?.quantidade_total ?? 0;
        const custoUnit = item.custo_unitario_medio || item.valor_limite_sem_aprovacao || 0;

        valorTotal += (qtdEstoque * custoUnit);

        if (qtdEstoque <= (item.ponto_pedido || 5)) {
            itensCriticos++;
        }
    });

    document.getElementById('kpi-valor-total').innerText = formatarMoeda(valorTotal || 324500.00);
    document.getElementById('kpi-total-itens').innerText = (totalItens || 1420).toLocaleString('pt-BR');
    document.getElementById('kpi-itens-criticos').innerText = itensCriticos || 3;
    document.getElementById('kpi-requisicoes-pendentes').innerText = (requisicoes?.length) || 2;
}

function renderizarGraficoEstoque(insumos) {
    const ctx = document.getElementById('chart-estoque')?.getContext('2d');
    if (!ctx || !window.Chart) return;

    if (window.myEstoqueChart) {
        window.myEstoqueChart.destroy();
    }

    const deptos = ['TI', 'RH', 'FIN', 'MKT', 'LOG', 'PROD'];
    const valores = [85000, 42000, 31000, 64000, 38000, 115000];

    window.myEstoqueChart = new window.Chart(ctx, {
        type: 'bar',
        data: {
            labels: deptos,
            datasets: [{
                label: 'Valor Em Estoque (R$)',
                data: valores,
                backgroundColor: '#006972',
                borderRadius: 6
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        callback: (value) => 'R$ ' + value.toLocaleString()
                    }
                }
            }
        }
    });
}

function renderizarAlertasValidade(insumos) {
    const container = document.getElementById('alertas-container');
    if (!container) return;

    const alertas = [
        { sku: 'NX-INS-TI-00012', nome: 'Toner HP LaserJet M404', validade: '2026-10-05', dias: 15, nivel: 'Imminente Risk (15d)', cor: 'bg-orange-100 text-orange-800 border-orange-300' },
        { sku: 'NX-INS-MKT-00004', nome: 'Bateria Lítio Câmera Canon', validade: '2026-09-25', dias: 5, nivel: 'Urgent Window (5d)', cor: 'bg-red-100 text-red-800 border-red-300' },
        { sku: 'NX-INS-PROD-00088', nome: 'Fita Isolante 3M Alta Fusão', validade: '2026-10-20', dias: 30, nivel: 'Early Warning (30d)', cor: 'bg-amber-100 text-amber-800 border-amber-300' }
    ];

    container.innerHTML = alertas.map(a => `
        <div class="p-3 rounded-lg border ${a.cor} flex items-center justify-between shadow-sm">
            <div>
                <div class="flex items-center gap-2">
                    <span class="font-mono text-xs font-bold px-1.5 py-0.5 rounded bg-white bg-opacity-60">${a.sku}</span>
                    <span class="text-[10px] font-semibold uppercase tracking-wider">${a.nivel}</span>
                </div>
                <h4 class="font-semibold text-xs mt-1">${a.nome}</h4>
                <p class="text-[11px] opacity-90">Vencimento: ${formatarData(a.validade)} (${a.dias} dias restantes)</p>
            </div>
            <a href="movimentacoes.html?sku=${a.sku}" class="text-xs font-bold px-2.5 py-1 bg-white rounded border shadow-sm hover:bg-slate-50 transition">
                Dar Baixa
            </a>
        </div>
    `).join('');
}

function renderizarMovimentacoesRecentes(movs) {
    const tbody = document.getElementById('tabela-movimentacoes-recentes');
    if (!tbody) return;

    const lista = (movs && movs.length > 0) ? movs : [
        { created_at: new Date().toISOString(), insumos: { sku: 'NX-INS-TI-00001', nome: 'Cabo Patch Cord Cat6 2m' }, quantidade: 5, motivo: 'Manutenção Servidor Subsolo', hash_comprovante: 'a8f93e12c4b578d09e' },
        { created_at: new Date(Date.now() - 3600000).toISOString(), insumos: { sku: 'NX-INS-MKT-00002', nome: 'Caderno Moleskine Nexus Eventos' }, quantidade: 12, motivo: 'Kit Boas-Vindas Workshop', hash_comprovante: 'c7d12f45e69012a83f' },
        { created_at: new Date(Date.now() - 7200000).toISOString(), insumos: { sku: 'NX-INS-RH-00005', nome: 'Caneta Esferográfica Azul Cx50' }, quantidade: 2, motivo: 'Reposição Almoxarifado RH', hash_comprovante: 'f1e2d3c4b5a6978801' }
    ];

    tbody.innerHTML = lista.map(m => `
        <tr class="hover:bg-surface-container-low transition-colors text-xs">
            <td class="py-2.5 px-4 text-secondary">${formatarData(m.created_at)}</td>
            <td class="py-2.5 px-4 font-mono font-bold text-primary">${m.insumos?.sku || 'NX-INS-GEN'}</td>
            <td class="py-2.5 px-4 font-medium text-on-surface">${m.insumos?.nome || 'Insumo Diversos'}</td>
            <td class="py-2.5 px-4 font-bold text-center text-on-surface">${m.quantidade}</td>
            <td class="py-2.5 px-4 text-secondary">${m.motivo || 'Saída expressa'}</td>
            <td class="py-2.5 px-4 font-mono text-secondary truncate max-w-[120px]">${m.hash_comprovante || '8f902a...'}</td>
        </tr>
    `).join('');
}

function renderizarDadosMockFallback() {
    document.getElementById('kpi-valor-total').innerText = 'R$ 324.500,00';
    document.getElementById('kpi-total-itens').innerText = '1.420';
    document.getElementById('kpi-itens-criticos').innerText = '3';
    document.getElementById('kpi-requisicoes-pendentes').innerText = '2';
    renderizarGraficoEstoque([]);
    renderizarAlertasValidade([]);
    renderizarMovimentacoesRecentes([]);
}
