// Módulo de integração do leitor de QR Code via câmera do navegador (Web Camera API)

export function iniciarLeitorQRCode(elementId, onSuccessCallback, onErrorCallback) {
    if (!window.Html5Qrcode) {
        alert("Biblioteca html5-qrcode não foi carregada no navegador.");
        return;
    }

    const html5QrCode = new window.Html5Qrcode(elementId);
    const config = { fps: 10, qrbox: { width: 250, height: 250 } };

    html5QrCode.start(
        { facingMode: "environment" },
        config,
        (decodedText) => {
            html5QrCode.stop().then(() => {
                onSuccessCallback(decodedText);
            }).catch(err => console.error("Erro ao parar a câmera:", err));
        },
        (errorMessage) => {
            if (onErrorCallback) onErrorCallback(errorMessage);
        }
    ).catch(err => {
        console.error("Erro ao iniciar a câmera do dispositivo:", err);
        alert("Não foi possível acessar a câmera do dispositivo. Verifique as permissões do navegador.");
    });

    return html5QrCode;
}
