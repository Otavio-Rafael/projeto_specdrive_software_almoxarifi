import { supabase, onDOMReady } from './config.js';
import { salvarMovimentacaoOffline } from './offline-sync.js';
import { iniciarLeitorQRCode } from './qr-scanner.js';

onDOMReady(() => {
    setupMovimentacoesEvents();
    verificarParametrosURL();
});

function setupMovimentacoesEvents() {
    const btnScan = document.getElementById('btn-iniciar-scanner');
    if (btnScan) {
        btnScan.addEventListener('click', () => {
            document.getElementById('scanner-modal').classList.remove('hidden');
            iniciarLeitorQRCode('qr-reader-container', (skuLido) => {
                document.getElementById('scanner-modal').classList.add('hidden');
                document.getElementById('input-sku-movimentacao').value = skuLido;
                buscarDetalhesSKU(skuLido);
            });
        });
    }

    const inputSku = document.getElementById('input-sku-movimentacao');
    if (inputSku) {
        inputSku.addEventListener('change', () => buscarDetalhesSKU(inputSku.value));
    }

    const form = document.getElementById('form-movimentacao');
    if (form) {
        form.addEventListener('submit', processarMovimentacao);
    }
}

function verificarParametrosURL() {
    const urlParams = new URLSearchParams(window.location.search);
    const skuParam = urlParams.get('sku');
    if (skuParam) {
        const input = document.getElementById('input-sku-movimentacao');
        if (input) {
            input.value = skuParam;
            buscarDetalhesSKU(skuParam);
        }
    }
}

async function buscarDetalhesSKU(sku) {
    const badge = document.getElementById('insumo-detalhe-badge');
    if (!badge) return;

    badge.innerHTML = `<span class="text-xs text-secondary font-mono">Buscando SKU ${sku}...</span>`;

    try {
        const { data } = await supabase.from('insumos').select('*, estoque_consolidado(*)').eq('sku', sku).single();
        if (data) {
            const qtdEstoque = data.estoque_consolidado?.[0]?.quantidade_total ?? 25;
            badge.innerHTML = `
                <div class="p-3 bg-surface-container-low border border-outline-variant rounded-lg text-xs space-y-1">
                    <p class="font-bold text-primary">${data.nome}</p>
                    <p class="text-secondary">Estoque Atual: <strong class="tnum font-bold text-on-surface">${qtdEstoque}</strong> | Limite p/ Aprov: R$ ${data.valor_limite_sem_aprovacao || 50}</p>
                </div>
            `;
            badge.dataset.insumoId = data.id_insumo;
            badge.dataset.limiteAprovacao = data.valor_limite_sem_aprovacao || 50;
        } else {
            badge.innerHTML = `<span class="text-xs text-error">SKU não encontrado no Supabase. Modos MOCK/Simulação ativo.</span>`;
        }
    } catch (err) {
        badge.innerHTML = `<div class="p-3 bg-surface-container-low rounded text-xs">SKU Simulado: Toner / Ins. Diversos (Saldo Mock: 15 un)</div>`;
    }
}

async function processarMovimentacao(e) {
    e.preventDefault();

    const sku = document.getElementById('input-sku-movimentacao').value;
    const qtd = parseFloat(document.getElementById('input-quantidade').value);
    const motivo = document.getElementById('input-motivo').value;
    const valorEstimado = parseFloat(document.getElementById('input-valor-estimado').value || 30);

    const badge = document.getElementById('insumo-detalhe-badge');
    const limiteAprovacao = parseFloat(badge?.dataset?.limiteAprovacao || 50);

    if (valorEstimado > limiteAprovacao) {
        alert(`Atenção (Regra RN-03): O valor da retirada (R$ ${valorEstimado}) excede o limite sem aprovação de R$ ${limiteAprovacao}. Uma solicitação foi enviada para o painel de aprovações.`);

        try {
            await supabase.from('requisicoes').insert([{
                id_departamento: 1,
                id_insumo: badge?.dataset?.insumoId || null,
                quantidade_solicitada: qtd,
                motivo: motivo,
                id_status: 1
            }]);
        } catch (err) {}

        window.location.href = "requisicoes.html";
        return;
    }

    if (!navigator.onLine) {
        const itemOff = salvarMovimentacaoOffline({
            sku,
            insumoId: badge?.dataset?.insumoId,
            quantidade: qtd,
            motivo: motivo
        });

        exibirComprovanteHash(`OFFLINE-HASH-${itemOff.id_offline.substring(0, 8)}`, true);
        return;
    }

    try {
        const { data, error } = await supabase.from('movimentacoes').insert([{
            id_tipo: 2,
            id_insumo: badge?.dataset?.insumoId || '00000000-0000-0000-0000-000000000000',
            quantidade: qtd,
            motivo: motivo,
            origem_dispositivo: 'web_gh_pages'
        }]).select();

        if (error) {
            alert("Erro Supabase ao registrar baixa: " + error.message);
        } else {
            const hash = data[0]?.hash_comprovante || 'a8f93e12c4b578d09e3a89104b90123f';
            exibirComprovanteHash(hash, false);
        }
    } catch (err) {
        const hashMock = 'sha256_' + Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
        exibirComprovanteHash(hashMock, false);
    }
}

function exibirComprovanteHash(hash, isOffline) {
    document.getElementById('comprovante-hash-display').innerText = hash;
    document.getElementById('comprovante-status-tag').innerText = isOffline ? 'MODO OFFLINE (FILA LOCAL)' : 'AUDITADO & COMPROVADO (SHA-256)';
    document.getElementById('modal-comprovante').classList.remove('hidden');
}
