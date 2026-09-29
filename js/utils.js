// Utilitários globais do sistema Nexus StorageControl

export function formatarMoeda(valor) {
    const num = parseFloat(valor) || 0;
    return new Intl.NumberFormat('pt-BR', {
        style: 'currency',
        currency: 'BRL'
    }).format(num);
}

export function formatarData(dataIso) {
    if (!dataIso) return '-';
    const data = new Date(dataIso);
    return isNaN(data.getTime()) ? '-' : data.toLocaleDateString('pt-BR');
}

export function formatarDataHora(dataIso) {
    if (!dataIso) return '-';
    const data = new Date(dataIso);
    return isNaN(data.getTime()) ? '-' : data.toLocaleString('pt-BR');
}

export function gerarCodigoQRCanvas(elementId, texto) {
    const container = document.getElementById(elementId);
    if (!container) return;
    container.innerHTML = '';

    // Utiliza QRCode via CDN se disponível globalmente ou gera SVG simples
    if (window.QRCode) {
        new window.QRCode(container, {
            text: texto,
            width: 180,
            height: 180,
            colorDark: "#0F172A",
            colorLight: "#FFFFFF",
            correctLevel: window.QRCode.CorrectLevel.H
        });
    } else {
        container.innerHTML = `<div class="p-4 bg-gray-100 rounded text-center font-mono border">${texto}</div>`;
    }
}

export function exportarParaExcel(dados, nomeArquivo = 'relatorio.xlsx') {
    if (!window.XLSX) {
        alert('Biblioteca SheetJS (XLSX) não foi carregada.');
        return;
    }
    const ws = window.XLSX.utils.json_to_sheet(dados);
    const wb = window.XLSX.utils.book_new();
    window.XLSX.utils.book_append_sheet(wb, ws, "Relatorio");
    window.XLSX.writeFile(wb, nomeArquivo);
}

export function exportarParaPDF(titulo, dadosColunas, dadosLinhas, nomeArquivo = 'relatorio.pdf') {
    if (!window.jspdf || !window.jspdf.jsPDF) {
        alert('Biblioteca jsPDF não foi carregada.');
        return;
    }
    const { jsPDF } = window.jspdf;
    const doc = new jsPDF();

    doc.setFont("helvetica", "bold");
    doc.setFontSize(16);
    doc.setTextColor(15, 23, 42);
    doc.text("GRUPO NEXUS - ALMOXARIFADO", 14, 15);

    doc.setFontSize(12);
    doc.setFont("helvetica", "normal");
    doc.setTextColor(100, 116, 139);
    doc.text(titulo, 14, 23);

    if (doc.autoTable) {
        doc.autoTable({
            startY: 30,
            head: [dadosColunas],
            body: dadosLinhas,
            theme: 'striped',
            headStyles: { fillColor: [0, 105, 114] }
        });
    } else {
        let y = 35;
        doc.setFontSize(10);
        dadosLinhas.forEach(linha => {
            doc.text(linha.join(' | '), 14, y);
            y += 7;
        });
    }

    doc.save(nomeArquivo);
}
