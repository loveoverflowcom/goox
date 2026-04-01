(function () {
  const input = () => window.__EXTENSION_INPUT__ || null;

  const frame = document.getElementById('pdfFrame');
  const emptyState = document.getElementById('emptyState');
  const titleEl = document.getElementById('title');
  const statusText = document.getElementById('statusText');
  const sourceText = document.getElementById('sourceText');
  const pageInput = document.getElementById('pageInput');
  const zoomInput = document.getElementById('zoomInput');
  const fitButton = document.getElementById('fitButton');
  const prevButton = document.getElementById('prevPage');
  const nextButton = document.getElementById('nextPage');
  const zoomOutButton = document.getElementById('zoomOut');
  const zoomInButton = document.getElementById('zoomIn');

  const state = {
    objectUrl: null,
    fileName: 'PDF Viewer',
    filePath: '',
    page: 1,
    zoom: 100,
    fit: true,
    loaded: false,
  };

  function emit(type, payload) {
    window.host?.postMessage({
      type,
      payload: {
        source: 'pdf-viewer',
        ...payload,
      },
    });
  }

  function decodeBase64(base64) {
    const raw = atob(base64);
    const bytes = new Uint8Array(raw.length);
    for (let index = 0; index < raw.length; index += 1) {
      bytes[index] = raw.charCodeAt(index);
    }
    return bytes;
  }

  function revokeObjectUrl() {
    if (state.objectUrl && state.objectUrl.startsWith('blob:')) {
      URL.revokeObjectURL(state.objectUrl);
    }
    state.objectUrl = null;
  }

  function setStatus(text) {
    statusText.textContent = text;
  }

  function updateSourceLabel() {
    sourceText.textContent = state.filePath ? state.filePath : '';
  }

  function currentFragment() {
    const zoomValue = state.fit ? 'page-fit' : `${state.zoom}`;
    return `#page=${state.page}&zoom=${zoomValue}`;
  }

  function renderFrame() {
    if (!state.objectUrl) {
      return;
    }

    frame.src = `${state.objectUrl}${currentFragment()}`;
    pageInput.value = String(state.page);
    zoomInput.value = String(state.zoom);
    fitButton.textContent = state.fit ? 'Fit' : 'Fit On';
    setStatus(`Page ${state.page} · ${state.fit ? 'fit' : `${state.zoom}%`}`);
  }

  function applyInput(nextInput) {
    if (!nextInput) {
      return;
    }

    revokeObjectUrl();

    const bytes = nextInput.fileContentBase64
      ? decodeBase64(String(nextInput.fileContentBase64))
      : null;

    if (bytes) {
      state.objectUrl = URL.createObjectURL(
        new Blob([bytes], { type: 'application/pdf' }),
      );
    } else if (nextInput.fileUri) {
      state.objectUrl = String(nextInput.fileUri);
    } else if (nextInput.filePath) {
      state.objectUrl = String(nextInput.filePath);
    } else {
      state.objectUrl = null;
    }

    state.fileName = String(nextInput.fileName || nextInput.extensionName || 'PDF Viewer');
    state.filePath = String(nextInput.filePath || '');
    state.page = 1;
    state.zoom = 100;
    state.fit = true;
    state.loaded = true;

    titleEl.textContent = state.fileName;
    emptyState.style.display = 'none';
    updateSourceLabel();
    renderFrame();

    emit('event', {
      topic: 'document.loaded',
      filePath: state.filePath,
      fileName: state.fileName,
    });
  }

  function setPage(page) {
    state.page = Math.max(1, Number(page) || 1);
    renderFrame();
  }

  function setZoom(zoom) {
    state.zoom = Math.min(400, Math.max(25, Number(zoom) || 100));
    state.fit = false;
    renderFrame();
  }

  function toggleFit() {
    state.fit = !state.fit;
    renderFrame();
  }

  function initControls() {
    prevButton.addEventListener('click', () => setPage(state.page - 1));
    nextButton.addEventListener('click', () => setPage(state.page + 1));
    pageInput.addEventListener('change', () => setPage(pageInput.value));
    zoomInput.addEventListener('change', () => setZoom(zoomInput.value));
    fitButton.addEventListener('click', toggleFit);
    zoomOutButton.addEventListener('click', () => setZoom(state.zoom - 10));
    zoomInButton.addEventListener('click', () => setZoom(state.zoom + 10));
  }

  function boot() {
    initControls();

    if (input()) {
      applyInput(input());
    }

    window.addEventListener('goox-extension-input', (event) => {
      applyInput(event.detail);
    });

    frame.addEventListener('load', () => {
      if (!state.loaded) {
        return;
      }
      emit('log', {
        topic: 'frame.loaded',
        page: state.page,
      });
    });

    window.addEventListener('keydown', (event) => {
      if (event.key === 'ArrowLeft') {
        setPage(state.page - 1);
      } else if (event.key === 'ArrowRight') {
        setPage(state.page + 1);
      } else if (event.key === '+' || event.key === '=') {
        setZoom(state.zoom + 10);
      } else if (event.key === '-') {
        setZoom(state.zoom - 10);
      } else if (event.key.toLowerCase() === 'f') {
        toggleFit();
      }
    });

    setStatus('Waiting for file input...');
    emit('event', { topic: 'viewer.ready' });
  }

  document.addEventListener('DOMContentLoaded', boot, { once: true });
})();
