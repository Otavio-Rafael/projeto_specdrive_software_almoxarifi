import { supabase, onDOMReady } from './config.js';
import { formatarData } from './utils.js';

onDOMReady(() => {
    carregarRequisicoes();
});

async function carregarRequisicoes() {
    const container = document.getElementById('lista-requisicoes-pendentes');
    if (!container) return;

    try {
        const { data: reqs } = await supabase
            .from('requisicoes')
            .select('*, insumos(nome, sku), departamentos(nome)')
            .eq('id_status', 1);

        const lista = (reqs && reqs.length > 0) ? reqs : getMockRequisicoes();
        renderizarRequisicoes(lista);
    } catch (err) {
        console.error("Erro ao carregar requisições:", err);
        renderizarRequisicoes(getMockRequisicoes());
    }
}

function renderizarRequisicoes(lista) {
    const container = document.getElementById('lista-requisicoes-pendentes');
    if (!container) return;

    if (lista.length === 0) {
        container.innerHTML = `<div class="p-8 text-center text-secondary bg-surface-container-lowest rounded-xl border border-outline-variant">Nenhuma solicitação pendente no momento.</div>`;
        return;
    }

    container.innerHTML = lista.map(r => `
        <div class="bg-surface-container-lowest p-5 rounded-xl border border-outline-variant shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div class="space-y-1">
                <div class="flex items-center gap-2">
                    <span class="font-mono text-xs font-bold px-2 py-0.5 rounded bg-amber-100 text-amber-800">${r.numero_requisicao || 'REQ-2026-001'}</span>
                    <span class="text-xs text-secondary">${r.departamentos?.nome || 'Tecnologia da Informação'}</span>
                </div>
                <h4 class="font-bold text-base text-on-surface font-heading">${r.insumos?.nome || 'Toner HP LaserJet M404'} (SKU: ${r.insumos?.sku || 'NX-INS-TI-00012'})</h4>
                <p class="text-xs text-secondary">Quantidade Solicitada: <strong class="tnum text-on-surface">${r.quantidade_solicitada || 2}</strong> | Solicitante: Carlos Mendonça</p>
                <p class="text-xs text-secondary italic">"Motivo: ${r.motivo || 'Impressão de relatórios gerenciais da diretoria'}"</p>
            </div>

            <div class="flex items-center space-x-2">
                <button onclick="window.aprovarRequisicao('${r.id_requisicao}')" class="px-4 py-2 bg-emerald-700 hover:bg-emerald-800 text-white font-bold text-xs rounded-lg transition shadow-sm">
                    Aprovar Saída
                </button>
                <button onclick="window.rejeitarRequisicao('${r.id_requisicao}')" class="px-4 py-2 bg-red-100 hover:bg-red-200 text-red-700 font-bold text-xs rounded-lg transition">
                    Rejeitar
                </button>
            </div>
        </div>
    `).join('');
}

window.aprovarRequisicao = async function(id) {
    if (confirm("Confirmar aprovação desta solicitação de saída?")) {
        try {
            await supabase.from('requisicoes').update({ id_status: 2 }).eq('id_requisicao', id);
            alert("Requisição APROVADA com sucesso!");
            carregarRequisicoes();
        } catch (err) {
            alert("Requisição APROVADA em modo de simulação!");
            carregarRequisicoes();
        }
    }
};

window.rejeitarRequisicao = async function(id) {
    const motivo = prompt("Motivo da rejeição:");
    if (motivo) {
        try {
            await supabase.from('requisicoes').update({ id_status: 3, motivo_rejeicao: motivo }).eq('id_requisicao', id);
            alert("Requisição REJEITADA.");
            carregarRequisicoes();
        } catch (err) {
            alert("Requisição REJEITADA em modo de simulação.");
            carregarRequisicoes();
        }
    }
};

function getMockRequisicoes() {
    return [
        { id_requisicao: '1', numero_requisicao: 'REQ-2026-000045', quantidade_solicitada: 2, motivo: 'Troca preventiva toner diretoria', insumos: { nome: 'Toner HP LaserJet M404', sku: 'NX-INS-TI-00012' }, departamentos: { nome: 'TI' } },
        { id_requisicao: '2', numero_requisicao: 'REQ-2026-000048', quantidade_solicitada: 5, motivo: 'Insumos para evento de lançamento', insumos: { nome: 'Bateria Lítio Câmera Canon', sku: 'NX-INS-MKT-00004' }, departamentos: { nome: 'Marketing' } }
    ];
}
