import { supabase } from './config.js';
import { formatarData, formatarMoeda, exportarParaExcel, exportarParaPDF } from './utils.js';

document.addEventListener('DOMContentLoaded', () => {
    carregarRelatorios();
    setupRelatorioEvents();
});

function setupRelatorioEvents() {
    document.getElementById('btn-export-excel')?.addEventListener('click', exportarExcel);
    document.getElementById('btn-export-pdf')?.addEventListener('click', exportarPDF);
}

async function carregarRelatorios() {
    const tbody = document.getElementById('tabela-auditoria');
    if (!tbody) return;

    try {
        const { data: logs, error } = await supabase
            .from('log_auditoria')
            .select('*')
            .order('created_at', { ascending: false })
            .limit(20);

        const lista = (logs && logs.length > 0) ? logs : getMockLogsAuditoria();
        renderizarLogs(lista);
    } catch (err) {
        renderizarLogs(getMockLogsAuditoria());
    }
}

function renderizarLogs(lista) {
    const tbody = document.getElementById('tabela-auditoria');
    if (!tbody) return;

    tbody.innerHTML = lista.map(l => `
        <tr class="border-b hover:bg-slate-50 text-sm">
            <td class="p-3 text-xs text-slate-500 font-mono">${formatarData(l.created_at)}</td>
            <td class="p-3 font-semibold text-slate-900">${l.tabela_afetada}</td>
            <td class="p-3">
                <span class="px-2 py-0.5 rounded text-[10px] font-bold ${l.operacao === 'INSERT' ? 'bg-emerald-100 text-emerald-800' : 'bg-amber-100 text-amber-800'}">${l.operacao}</span>
            </td>
            <td class="p-3 text-xs text-slate-600 font-mono max-w-xs truncate">${JSON.stringify(l.dados_novos || l.dados_anteriores || {})}</td>
            <td class="p-3 font-mono text-xs text-slate-400 truncate max-w-[140px]">${l.hash_registro || 'a890f12c4b578e09'}</td>
        </tr>
    `).join('');
}

function exportarExcel() {
    const dados = [
        { SKU: 'NX-INS-TI-00001', Insumo: 'Cabo Patch Cord Cat6 2m', Departamento: 'TI', Qtd: 45, ValorTotal: 1125.00 },
        { SKU: 'NX-INS-TI-00012', Insumo: 'Toner HP LaserJet M404', Departamento: 'TI', Qtd: 3, ValorTotal: 840.00 },
        { SKU: 'NX-INS-RH-00005', Insumo: 'Caneta Esferográfica Cx50', Departamento: 'RH', Qtd: 12, ValorTotal: 540.00 }
    ];
    exportarParaExcel(dados, 'Relatorio_Insumos_Nexus.xlsx');
}

function exportarPDF() {
    const colunas = ["SKU", "Insumo", "Departamento", "Quantidade", "Valor Total"];
    const linhas = [
        ["NX-INS-TI-00001", "Cabo Patch Cord Cat6 2m", "TI", "45", "R$ 1.125,00"],
        ["NX-INS-TI-00012", "Toner HP LaserJet M404", "TI", "3", "R$ 840,00"],
        ["NX-INS-RH-00005", "Caneta Esferográfica Cx50", "RH", "12", "R$ 540,00"]
    ];
    exportarParaPDF("Relatório de Controle de Insumos Departamentais", colunas, linhas, "Relatorio_Nexus.pdf");
}

function getMockLogsAuditoria() {
    return [
        { created_at: new Date().toISOString(), tabela_afetada: 'movimentacoes', operacao: 'INSERT', dados_novos: { id_insumo: 'NX-INS-TI-00001', quantidade: 5 }, hash_registro: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855' },
        { created_at: new Date(Date.now() - 3600000).toISOString(), tabela_afetada: 'insumos', operacao: 'UPDATE', dados_novos: { estoque_minimo: 10 }, hash_registro: 'ca978112ca1bbdcafac231b39a23dac4b1652107893af6504ca495991b7852b85' }
    ];
}
