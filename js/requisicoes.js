import { supabase, onDOMReady } from './config.js';
import { formatarData } from './utils.js';

onDOMReady(() => {
    carregarRequisicoes();
});

async function carregarRequisicoes() {
    const container = document.getElementById('tabela-requisicoes') || document.getElementById('lista-requisicoes-pendentes');
    if (!container) return;

    try {
        const { data: reqs } = await supabase
            .from('requisicoes')
            .select('*, insumos(nome, sku), departamentos(nome)')
            .eq('id_status', 1)
            .order('created_at', { ascending: false });

        const lista = (reqs && reqs.length > 0) ? reqs : getMockRequisicoes();
        renderizarRequisicoes(lista);
    } catch (err) {
        console.error("Erro ao carregar requisições:", err);
        renderizarRequisicoes(getMockRequisicoes());
    }
}

function renderizarRequisicoes(lista) {
    const container = document.getElementById('tabela-requisicoes') || document.getElementById('lista-requisicoes-pendentes');
    if (!container) return;

    if (lista.length === 0) {
        container.innerHTML = `<tr><td colspan="7" class="text-center p-6 text-secondary">Nenhuma solicitação pendente no momento.</td></tr>`;
        return;
    }

    container.innerHTML = lista.map((r, index) => {
        const numReq = r.numero_requisicao || `REQ-2026-${(index + 1).toString().padStart(6, '0')}`;
        const nomeDepto = r.departamentos?.nome || 'Departamento Operacional';
        const nomeInsumo = r.insumos?.nome || r.nome_insumo_temp || 'Insumo Solicitado';
        const skuInsumo = r.insumos?.sku || r.sku_insumo_temp || 'NX-INS-GEN';
        const qtd = r.quantidade_solicitada || 1;
        const motivo = r.motivo || 'Sem motivo especificado';
        const valorEstimado = (qtd * 65.00);

        return `
            <tr class="hover:bg-surface-container-low transition-colors text-xs">
                <td class="py-2.5 px-4 font-mono font-bold text-primary">${numReq}</td>
                <td class="py-2.5 px-4">
                    <div class="font-semibold text-on-surface">${nomeInsumo}</div>
                    <div class="text-[11px] text-secondary font-mono">${skuInsumo}</div>
                </td>
                <td class="py-2.5 px-4">
                    <div class="font-medium text-on-surface">${nomeDepto}</div>
                    <div class="text-[11px] text-secondary">Solicitante Operacional</div>
                </td>
                <td class="py-2.5 px-4 font-bold text-center tnum">${qtd}</td>
                <td class="py-2.5 px-4 font-bold text-amber-800">R$ ${valorEstimado.toFixed(2)}</td>
                <td class="py-2.5 px-4 text-center">
                    <span class="px-2 py-0.5 rounded text-[10px] font-bold bg-amber-100 text-amber-800">Aguardando Aprovação (RN-03)</span>
                </td>
                <td class="py-2.5 px-4 text-right space-x-1 whitespace-nowrap">
                    <button onclick="window.aprovarRequisicao('${r.id_requisicao}')" class="px-2.5 py-1 bg-emerald-700 hover:bg-emerald-800 text-white font-bold text-xs rounded transition shadow-xs">
                        Aprovar
                    </button>
                    <button onclick="window.rejeitarRequisicao('${r.id_requisicao}')" class="px-2 py-1 bg-red-100 hover:bg-red-200 text-red-700 font-bold text-xs rounded transition">
                        Rejeitar
                    </button>
                </td>
            </tr>
        `;
    }).join('');
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
