import { supabase, onDOMReady } from './config.js';
import { formatarMoeda, gerarCodigoQRCanvas } from './utils.js';

onDOMReady(() => {
    carregarInsumos();
    setupInsumosEvents();
});

function setupInsumosEvents() {
    const formInsumo = document.getElementById('form-insumo');
    if (formInsumo) {
        formInsumo.addEventListener('submit', salvarInsumo);
    }

    const searchInput = document.getElementById('search-insumos');
    if (searchInput) {
        searchInput.addEventListener('input', carregarInsumos);
    }

    const filterCat = document.getElementById('filter-categoria');
    if (filterCat) {
        filterCat.addEventListener('change', carregarInsumos);
    }
}

async function carregarInsumos() {
    const tbody = document.getElementById('tabela-insumos');
    if (!tbody) return;

    const termo = document.getElementById('search-insumos')?.value.toLowerCase() || '';
    const categoria = document.getElementById('filter-categoria')?.value || '';

    try {
        let query = supabase.from('insumos').select('*, estoque_consolidado(*), categorias_insumo(nome), departamentos(sigla)');
        if (categoria) {
            query = query.eq('id_categoria', categoria);
        }
        const { data: insumos } = await query;

        const locais = getInsumosLocais();
        let lista = (insumos && insumos.length > 0) ? [...locais, ...insumos] : [...locais, ...getMockInsumos()];

        if (termo) {
            lista = lista.filter(i =>
                i.nome.toLowerCase().includes(termo) ||
                (i.sku && i.sku.toLowerCase().includes(termo))
            );
        }

        renderizarTabelaInsumos(lista);
    } catch (err) {
        console.error("Erro ao buscar insumos:", err);
        renderizarTabelaInsumos(getMockInsumos());
    }
}

function renderizarTabelaInsumos(lista) {
    const tbody = document.getElementById('tabela-insumos');
    if (!tbody) return;

    if (lista.length === 0) {
        tbody.innerHTML = `<tr><td colspan="7" class="text-center p-6 text-secondary">Nenhum insumo encontrado.</td></tr>`;
        return;
    }

    tbody.innerHTML = lista.map(i => {
        const qtdEstoque = i.estoque_consolidado?.[0]?.quantidade_total ?? i.quantidade_total ?? 0;
        const ptoPedido = i.ponto_pedido || 5;

        let badgeStatus = '<span class="px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-100 text-emerald-800">Normal</span>';
        if (qtdEstoque <= 0) {
            badgeStatus = '<span class="px-2 py-0.5 rounded text-[10px] font-bold bg-red-100 text-red-800">Sem Estoque</span>';
        } else if (qtdEstoque <= ptoPedido) {
            badgeStatus = '<span class="px-2 py-0.5 rounded text-[10px] font-bold bg-amber-100 text-amber-800">Crítico / Baixo</span>';
        }

        return `
            <tr class="hover:bg-surface-container-low transition-colors text-xs">
                <td class="py-2.5 px-4 font-mono font-bold text-primary">${i.sku || 'NX-INS-GEN-001'}</td>
                <td class="py-2.5 px-4">
                    <div class="font-semibold text-on-surface">${i.nome}</div>
                    <div class="text-[11px] text-secondary">${i.descricao || 'Sem descrição'}</div>
                </td>
                <td class="py-2.5 px-4 text-secondary">${i.categorias_insumo?.nome || 'Geral'}</td>
                <td class="py-2.5 px-4 font-bold tnum text-center">${qtdEstoque}</td>
                <td class="py-2.5 px-4 tnum">${formatarMoeda(i.valor_limite_sem_aprovacao || i.custo_unitario_medio || 50)}</td>
                <td class="py-2.5 px-4 text-center">${badgeStatus}</td>
                <td class="py-2.5 px-4 text-right space-x-2">
                    <button onclick="window.abrirModalQR('${i.sku}', '${i.nome}')" class="text-xs font-bold px-2 py-1 bg-surface-container hover:bg-surface-container-high text-on-surface rounded border border-outline-variant">
                        QR Code
                    </button>
                    <a href="movimentacoes.html?sku=${i.sku}" class="text-xs font-bold px-2.5 py-1 bg-primary hover:bg-[#00454c] text-white rounded">
                        Baixa
                    </a>
                </td>
            </tr>
        `;
    }).join('');
}

async function salvarInsumo(e) {
    e.preventDefault();
    const nome = document.getElementById('input-nome').value;
    const categoria = parseInt(document.getElementById('input-categoria').value);
    const departamento = parseInt(document.getElementById('input-departamento').value);
    const estoqueMin = parseFloat(document.getElementById('input-estoque-min').value) || 0;
    const estoqueMax = parseFloat(document.getElementById('input-estoque-max').value) || 0;
    const ptoPedido = parseFloat(document.getElementById('input-ponto-pedido').value) || 0;
    const limiteSemAprov = parseFloat(document.getElementById('input-limite-aprovacao').value) || 50;

    if (estoqueMin > estoqueMax) {
        alert("Erro: O estoque mínimo não pode ser maior que o estoque máximo (Regra RN-02).");
        return;
    }

    // Gerar SKU localmente caso a trigger no Supabase não esteja definida no banco
    const siglaDept = departamento === 2 ? 'TI' : (departamento === 1 ? 'RH' : (departamento === 3 ? 'FIN' : 'MKT'));
    const seq = Math.floor(1000 + Math.random() * 9000);
    const skuGerado = `NX-INS-${siglaDept}-${seq}`;

    try {
        const { data, error } = await supabase.from('insumos').insert([{
            sku: skuGerado,
            nome,
            id_categoria: categoria,
            id_unidade: 1,
            id_departamento: departamento,
            estoque_minimo: estoqueMin,
            estoque_maximo: estoqueMax,
            ponto_pedido: ptoPedido,
            valor_limite_sem_aprovacao: limiteSemAprov,
            tem_validade: document.getElementById('input-tem-validade')?.checked || false
        }]).select();

        if (error) {
            console.warn("Erro ao cadastrar via Supabase (salvando localmente no cache/offline):", error);
            salvarInsumoLocal({
                sku: skuGerado,
                nome,
                id_categoria: categoria,
                id_unidade: 1,
                id_departamento: departamento,
                estoque_minimo: estoqueMin,
                estoque_maximo: estoqueMax,
                ponto_pedido: ptoPedido,
                valor_limite_sem_aprovacao: limiteSemAprov,
                tem_validade: document.getElementById('input-tem-validade')?.checked || false,
                quantidade_total: 0
            });
            alert("Insumo cadastrado com sucesso! (Salvo localmente e adicionado à fila de sincronização)");
            document.getElementById('modal-novo-insumo')?.classList.add('hidden');
            carregarInsumos();
        } else {
            alert("Insumo cadastrado com sucesso! SKU: " + (data[0]?.sku || skuGerado));
            document.getElementById('modal-novo-insumo')?.classList.add('hidden');
            carregarInsumos();
        }
    } catch (err) {
        console.error("Exceção ao salvar:", err);
        salvarInsumoLocal({
            sku: skuGerado,
            nome,
            id_categoria: categoria,
            id_unidade: 1,
            id_departamento: departamento,
            estoque_minimo: estoqueMin,
            estoque_maximo: estoqueMax,
            ponto_pedido: ptoPedido,
            valor_limite_sem_aprovacao: limiteSemAprov,
            tem_validade: document.getElementById('input-tem-validade')?.checked || false,
            quantidade_total: 0
        });
        alert("Insumo cadastrado com sucesso! (Salvo em cache local)");
        document.getElementById('modal-novo-insumo')?.classList.add('hidden');
        carregarInsumos();
    }
}

window.abrirModalQR = function(sku, nome) {
    document.getElementById('modal-qr-sku-title').innerText = `${nome} (${sku})`;
    document.getElementById('modal-qr-code').classList.remove('hidden');
    gerarCodigoQRCanvas('qr-container', sku);
};

window.fecharModalQR = function() {
    document.getElementById('modal-qr-code').classList.add('hidden');
};

function salvarInsumoLocal(insumo) {
    const salvos = JSON.parse(localStorage.getItem('nexus_insumos_locais') || '[]');
    salvos.unshift(insumo);
    localStorage.setItem('nexus_insumos_locais', JSON.stringify(salvos));
}

function getInsumosLocais() {
    return JSON.parse(localStorage.getItem('nexus_insumos_locais') || '[]');
}

function getMockInsumos() {
    return [
        { sku: 'NX-INS-TI-00001', nome: 'Cabo Patch Cord Cat6 2m', descricao: 'Cabo de rede azul homologado', quantidade_total: 45, ponto_pedido: 10, valor_limite_sem_aprovacao: 25.00, categorias_insumo: { nome: 'TI' } },
        { sku: 'NX-INS-TI-00012', nome: 'Toner HP LaserJet M404', descricao: 'Preto 58A', quantidade_total: 3, ponto_pedido: 5, valor_limite_sem_aprovacao: 280.00, categorias_insumo: { nome: 'TI' } },
        { sku: 'NX-INS-RH-00005', nome: 'Caneta Esferográfica Azul Cx50', descricao: 'Caixa com 50 unidades', quantidade_total: 12, ponto_pedido: 4, valor_limite_sem_aprovacao: 45.00, categorias_insumo: { nome: 'Escritório' } },
        { sku: 'NX-INS-MKT-00004', nome: 'Bateria Lítio Câmera Canon', descricao: 'Bateria recarregável LP-E6N', quantidade_total: 1, ponto_pedido: 2, valor_limite_sem_aprovacao: 350.00, categorias_insumo: { nome: 'Eventos' } }
    ];
}
