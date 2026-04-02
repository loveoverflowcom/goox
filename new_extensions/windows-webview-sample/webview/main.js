(function () {
  const state = {
    input: null,
    bridgeLog: [],
  };

  const el = {
    statusPill: document.getElementById('statusPill'),
    statusText: document.getElementById('statusText'),
    fileName: document.getElementById('fileName'),
    filePath: document.getElementById('filePath'),
    fileType: document.getElementById('fileType'),
    inputSequence: document.getElementById('inputSequence'),
    fileContent: document.getElementById('fileContent'),
    bridgeLog: document.getElementById('bridgeLog'),
    pingButton: document.getElementById('pingButton'),
    reloadButton: document.getElementById('reloadButton'),
  };

  function encodeMessage(payload) {
    return typeof payload === 'string' ? payload : JSON.stringify(payload);
  }

  function sendToHost(payload) {
    const message = encodeMessage(payload);
    appendBridgeLog('out', message);

    try {
      if (window.host && typeof window.host.postMessage === 'function') {
        window.host.postMessage(message);
        return;
      }
      if (window.chrome && window.chrome.webview && window.chrome.webview.postMessage) {
        window.chrome.webview.postMessage(message);
        return;
      }
      if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.host) {
        window.webkit.messageHandlers.host.postMessage(message);
        return;
      }
      if (window.external && typeof window.external.invoke === 'function') {
        window.external.invoke(message);
      }
    } catch (error) {
      setStatus('Bridge error', 'error', String(error));
    }
  }

  function setStatus(label, tone, detail) {
    el.statusPill.className = `pill pill--${tone}`;
    el.statusPill.textContent = label;
    el.statusText.textContent = detail;
  }

  function appendBridgeLog(direction, message) {
    const prefix = direction === 'in' ? '<-' : '->';
    const line = `${prefix} ${message}`;
    state.bridgeLog.unshift(line);
    state.bridgeLog = state.bridgeLog.slice(0, 8);
    el.bridgeLog.textContent = state.bridgeLog.join('\n\n');
  }

  function renderInput(input) {
    state.input = input && typeof input === 'object' ? input : null;

    if (!state.input) {
      el.fileName.textContent = '-';
      el.filePath.textContent = '-';
      el.fileType.textContent = '-';
      el.inputSequence.textContent = '-';
      el.fileContent.textContent = 'Waiting for host injection...';
      setStatus('Waiting for host input', 'idle', 'No input received yet.');
      return;
    }

    el.fileName.textContent = state.input.fileName || '-';
    el.filePath.textContent = state.input.filePath || '-';
    el.fileType.textContent = state.input.fileType || '-';
    el.inputSequence.textContent = String(state.input.inputSequence ?? '-');
    el.fileContent.textContent =
      state.input.fileContentBase64
        ? atob(state.input.fileContentBase64)
        : 'No file content was provided by the host.';

    setStatus(
      'Ready',
      'ready',
      `Received ${state.input.fileName || 'file'} from Flutter.`
    );
  }

  function handleInjectedInput(detail) {
    const input = detail || window.__EXTENSION_INPUT__ || null;
    if (!input) return;

    renderInput(input);
    appendBridgeLog('in', JSON.stringify({
      type: 'goox-extension-input',
      fileName: input.fileName,
      inputSequence: input.inputSequence,
    }));
  }

  document.addEventListener('goox-extension-input', (event) => {
    handleInjectedInput(event.detail);
  });

  el.pingButton.addEventListener('click', () => {
    sendToHost({
      type: 'ping',
      source: 'windows-webview-sample',
      fileName: state.input?.fileName || null,
      timestamp: new Date().toISOString(),
    });
    setStatus('Ping sent', 'ready', 'A ping message was posted to the host.');
  });

  el.reloadButton.addEventListener('click', () => {
    handleInjectedInput(window.__EXTENSION_INPUT__);
    sendToHost({
      type: 'refresh_request',
      source: 'windows-webview-sample',
    });
  });

  window.addEventListener('DOMContentLoaded', () => {
    handleInjectedInput(window.__EXTENSION_INPUT__);
    sendToHost({
      type: 'ready',
      source: 'windows-webview-sample',
      platform: 'windows',
    });
  });

  window.addEventListener('message', (event) => {
    if (!event || !event.data) return;
    appendBridgeLog('in', JSON.stringify(event.data));
  });
})();
