// Engine de sincronização offline para resiliência no mobile (IndexedDB / LocalStorage)
import { supabase } from './config.js';

const QUEUE_KEY = 'nexus_offline_movimentacoes_queue';

export function salvarMovimentacaoOffline(payload) {
    const queue = JSON.parse(localStorage.getItem(QUEUE_KEY) || '[]');
    const itemOffline = {
        ...payload,
        id_offline: crypto.randomUUID(),
        created_at: new Date().toISOString()
    };
    queue.push(itemOffline);
    localStorage.setItem(QUEUE_KEY, JSON.stringify(queue));
    atualizarContadorOffline();
    return itemOffline;
}

export function obterFilaOffline() {
    return JSON.parse(localStorage.getItem(QUEUE_KEY) || '[]');
}

export async function sincronizarFilaOffline() {
    if (!navigator.onLine) return;
    const queue = obterFilaOffline();
    if (queue.length === 0) return;

    console.log(`Sincronizando ${queue.length} movimentações offline com o Supabase...`);
    const itensSucesso = [];

    for (const item of queue) {
        try {
            const { error } = await supabase.from('movimentacoes').insert([{
                id_tipo: item.id_tipo || 2,
                id_insumo: item.insumoId || item.id_insumo,
                id_lote: item.loteId || item.id_lote || null,
                quantidade: parseFloat(item.quantidade),
                id_departamento_destino: item.id_departamento_destino || null,
                motivo: item.motivo,
                origem_dispositivo: 'web_offline_sync',
                sincronizado: true,
                id_offline: item.id_offline
            }]);

            if (!error) {
                itensSucesso.push(item.id_offline);
            } else {
                console.error("Erro ao sincronizar item offline:", error);
            }
        } catch (err) {
            console.error("Exceção na sincronização offline:", err);
        }
    }

    // Remover itens sincronizados
    const novaFila = queue.filter(i => !itensSucesso.includes(i.id_offline));
    localStorage.setItem(QUEUE_KEY, JSON.stringify(novaFila));
    atualizarContadorOffline();

    if (itensSucesso.length > 0 && window.showToast) {
        window.showToast(`${itensSucesso.length} movimentação(ões) offline sincronizada(s)!`);
    }
}

export function atualizarContadorOffline() {
    const queue = obterFilaOffline();
    const el = document.getElementById('offline-badge');
    if (el) {
        if (queue.length > 0) {
            el.innerText = `${queue.length} pendente(s) offline`;
            el.classList.remove('hidden');
        } else {
            el.classList.add('hidden');
        }
    }
}

// Event Listeners de Conexão
window.addEventListener('online', () => {
    console.log('Conexão restabelecida. Iniciando sincronização...');
    sincronizarFilaOffline();
});

window.addEventListener('DOMContentLoaded', () => {
    atualizarContadorOffline();
    if (navigator.onLine) {
        sincronizarFilaOffline();
    }
});
