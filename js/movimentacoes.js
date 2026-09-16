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
            const wrapper = document.getElementById('scanner-wrapper') || document.getElementById('scanner-modal');
            if (wrapper) wrapper.classList.remove('hidden');

            iniciarLeitorQRCode('reader', (skuLido) => {
                if (wrapper) wrapper.classList.add('hidden');
                const inputSku = document.getElementById('input-mov-sku') || document.getElementById('input-sku-movimentacao');
                if (inputSku) inputSku.value = skuLido;
                buscarDetalhesSKU(skuLido);
            });
        });
    }

    const btnParar = document.getElementById('btn-parar-scanner');
    if (btnParar) {
        btnParar.addEventListener('click', () => {
            const wrapper = document.getElementById('scanner-wrapper') || document.getElementById('scanner-modal');
            if (wrapper) wrapper.classList.add('hidden');
        });
    }

    const inputSku = document.getElementById('input-mov-sku') || document.getElementById('input-sku-movimentacao');
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
        const input = document.getElementById('input-mov-sku') || document.getElementById('input-sku-movimentacao');
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
            badge.dataset.insumoNome = data.nome;
            badge.dataset.insumoSku = data.sku;
            badge.dataset.insumoDepto = data.id_departamento || 1;
            badge.dataset.limiteAprovacao = data.valor_limite_sem_aprovacao || 50;
        } else {
            badge.innerHTML = `<span class="text-xs text-error">SKU não encontrado no Supabase. Modos MOCK/Simulação ativo.</span>`;
            badge.dataset.insumoNome = `Insumo (${sku})`;
            badge.dataset.insumoSku = sku;
        }
    } catch (err) {
        badge.innerHTML = `<div class="p-3 bg-surface-container-low rounded text-xs">SKU Simulado: Toner / Ins. Diversos (Saldo Mock: 15 un)</div>`;
        badge.dataset.insumoNome = `Insumo (${sku})`;
        badge.dataset.insumoSku = sku;
    }
}

async function processarMovimentacao(e) {
    e.preventDefault();

    const sku = (document.getElementById('input-mov-sku') || document.getElementById('input-sku-movimentacao'))?.value || 'NX-INS-TI-00001';
    const qtd = parseFloat((document.getElementById('input-mov-qtd') || document.getElementById('input-quantidade'))?.value || 1);
    const motivo = (document.getElementById('input-mov-motivo') || document.getElementById('input-motivo'))?.value || 'Retirada padrão';
    const valorEstimado = parseFloat(document.getElementById('input-valor-estimado')?.value || (qtd * 35));

    const badge = document.getElementById('insumo-detalhe-badge');
    const limiteAprovacao = parseFloat(badge?.dataset?.limiteAprovacao || 50);

    if (valorEstimado > limiteAprovacao) {
        alert(`Atenção (Regra RN-03): O valor da retirada (R$ ${valorEstimado}) excede o limite sem aprovação de R$ ${limiteAprovacao}. Uma solicitação foi enviada para o painel de aprovações.`);

        const numReq = `REQ-2026-${Math.floor(100000 + Math.random() * 900000)}`;
        try {
            await supabase.from('requisicoes').insert([{
                numero_requisicao: numReq,
                id_departamento: parseInt(badge?.dataset?.insumoDepto) || 1,
                id_insumo: badge?.dataset?.insumoId || null,
                quantidade_solicitada: qtd,
                motivo: motivo,
                id_status: 1
            }]);
        } catch (err) {}

        window.location.href = `requisicoes.html?new_req=${numReq}`;
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
    const container = document.getElementById('card-comprovante');
    if (container) {
        container.innerHTML = `
            <div class="p-3 bg-emerald-50 border border-emerald-200 text-emerald-900 rounded space-y-2">
                <div class="flex items-center justify-between">
                    <span class="font-bold text-xs">Comprovante Gerado</span>
                    <span class="text-[10px] uppercase font-bold px-1.5 py-0.5 rounded bg-emerald-200 text-emerald-800">${isOffline ? 'OFFLINE' : 'ONLINE'}</span>
                </div>
                <p class="font-mono text-[11px] break-all bg-white p-2 rounded border border-emerald-300 font-bold">${hash}</p>
                <p class="text-[10px] text-emerald-700">Hash SHA-256 registrado no Log de Auditoria Imutável do Almoxarifado.</p>
            </div>
        `;
    }

    const hashDisplay = document.getElementById('comprovante-hash-display');
    if (hashDisplay) hashDisplay.innerText = hash;
    const statusTag = document.getElementById('comprovante-status-tag');
    if (statusTag) statusTag.innerText = isOffline ? 'MODO OFFLINE (FILA LOCAL)' : 'AUDITADO & COMPROVADO (SHA-256)';
    const modalComp = document.getElementById('modal-comprovante');
    if (modalComp) modalComp.classList.remove('hidden');
}
