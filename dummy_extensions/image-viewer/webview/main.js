(function () {
  const input = () => window.__EXTENSION_INPUT__ || null;

  const viewport = document.getElementById('viewport');
  const image = document.getElementById('image');
  const emptyState = document.getElementById('emptyState');
  const titleEl = document.getElementById('title');
  const statusText = document.getElementById('statusText');
  const sourceText = document.getElementById('sourceText');
  const fitButton = document.getElementById('fitButton');
  const oneToOneButton = document.getElementById('oneToOneButton');
  const resetButton = document.getElementById('resetButton');
  const zoomOutButton = document.getElementById('zoomOut');
  const zoomInButton = document.getElementById('zoomIn');

  const state = {
    objectUrl: null,
    fileName: 'Image Viewer',
    filePath: '',
    naturalWidth: 1,
    naturalHeight: 1,
    zoom: 1,
    fit: true,
    panX: 0,
    panY: 0,
    loaded: false,
    pointer: null,
  };

  function emit(type, payload) {
    window.host?.postMessage({
      type,
      payload: {
        source: 'image-viewer',
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

  function updateTransform() {
    const scale = state.fit ? computeFitScale() : state.zoom;
    const translateX = state.fit ? 0 : state.panX;
    const translateY = state.fit ? 0 : state.panY;

    image.style.transform = `translate(calc(-50% + ${translateX}px), calc(-50% + ${translateY}px)) scale(${scale})`;
    fitButton.textContent = state.fit ? 'Fit' : 'Fit On';
    setStatus(state.fit ? 'Fit to screen' : `${Math.round(state.zoom * 100)}%`);
  }

  function computeFitScale() {
    const pad = 24;
    const width = Math.max(1, viewport.clientWidth - pad * 2);
    const height = Math.max(1, viewport.clientHeight - pad * 2);
    return Math.min(width / state.naturalWidth, height / state.naturalHeight, 1);
  }

  function render() {
    updateTransform();
  }

  function setZoom(nextZoom) {
    state.fit = false;
    state.zoom = Math.min(4, Math.max(0.25, Number(nextZoom) || 1));
    render();
  }

  function fitToScreen() {
    state.fit = true;
    state.panX = 0;
    state.panY = 0;
    render();
  }

  function oneToOne() {
    state.fit = false;
    state.zoom = 1;
    state.panX = 0;
    state.panY = 0;
    render();
  }

  function resetView() {
    state.zoom = 1;
    state.panX = 0;
    state.panY = 0;
    state.fit = true;
    render();
  }

  function updateImageSource(nextInput) {
    if (!nextInput) {
      return;
    }

    revokeObjectUrl();

    const bytes = nextInput.fileContentBase64
      ? decodeBase64(String(nextInput.fileContentBase64))
      : null;

    if (bytes) {
      const mimeType = guessMimeType(String(nextInput.fileType || 'image'));
      state.objectUrl = URL.createObjectURL(new Blob([bytes], { type: mimeType }));
    } else if (nextInput.fileUri) {
      state.objectUrl = String(nextInput.fileUri);
    } else if (nextInput.filePath) {
      state.objectUrl = String(nextInput.filePath);
    } else {
      state.objectUrl = null;
    }

    state.fileName = String(nextInput.fileName || nextInput.extensionName || 'Image Viewer');
    state.filePath = String(nextInput.filePath || '');
    state.loaded = true;

    titleEl.textContent = state.fileName;
    updateSourceLabel();
    emptyState.style.display = 'none';

    image.onload = () => {
      state.naturalWidth = image.naturalWidth || 1;
      state.naturalHeight = image.naturalHeight || 1;
      fitToScreen();
      emit('event', {
        topic: 'document.loaded',
        width: state.naturalWidth,
        height: state.naturalHeight,
        filePath: state.filePath,
      });
    };

    image.src = state.objectUrl || '';
  }

  function guessMimeType(fileType) {
    const normalized = String(fileType).toLowerCase();
    if (normalized === 'svg') return 'image/svg+xml';
    if (normalized === 'jpg' || normalized === 'jpeg') return 'image/jpeg';
    if (normalized === 'webp') return 'image/webp';
    if (normalized === 'gif') return 'image/gif';
    return 'image/png';
  }

  function startDrag(event) {
    if (state.fit) {
      return;
    }

    state.pointer = {
      id: event.pointerId,
      x: event.clientX,
      y: event.clientY,
      panX: state.panX,
      panY: state.panY,
    };
    viewport.classList.add('is-dragging');
    viewport.setPointerCapture(event.pointerId);
  }

  function moveDrag(event) {
    if (!state.pointer || state.pointer.id !== event.pointerId) {
      return;
    }

    state.panX = state.pointer.panX + (event.clientX - state.pointer.x);
    state.panY = state.pointer.panY + (event.clientY - state.pointer.y);
    render();
  }

  function endDrag(event) {
    if (!state.pointer || state.pointer.id !== event.pointerId) {
      return;
    }

    state.pointer = null;
    viewport.classList.remove('is-dragging');
    viewport.releasePointerCapture(event.pointerId);
  }

  function initControls() {
    fitButton.addEventListener('click', fitToScreen);
    oneToOneButton.addEventListener('click', oneToOne);
    resetButton.addEventListener('click', resetView);
    zoomOutButton.addEventListener('click', () => setZoom(state.zoom - 0.1));
    zoomInButton.addEventListener('click', () => setZoom(state.zoom + 0.1));

    viewport.addEventListener('pointerdown', startDrag);
    viewport.addEventListener('pointermove', moveDrag);
    viewport.addEventListener('pointerup', endDrag);
    viewport.addEventListener('pointercancel', endDrag);

    viewport.addEventListener(
      'wheel',
      (event) => {
        if (state.fit) {
          event.preventDefault();
          setZoom(1 + (event.deltaY > 0 ? -0.1 : 0.1));
          return;
        }

        event.preventDefault();
        setZoom(state.zoom + (event.deltaY > 0 ? -0.1 : 0.1));
      },
      { passive: false },
    );

    window.addEventListener('keydown', (event) => {
      if (event.key === '+') {
        setZoom(state.zoom + 0.1);
      } else if (event.key === '-') {
        setZoom(state.zoom - 0.1);
      } else if (event.key.toLowerCase() === 'f') {
        fitToScreen();
      } else if (event.key.toLowerCase() === 'r') {
        resetView();
      }
    });
  }

  function boot() {
    initControls();

    if (input()) {
      updateImageSource(input());
    }

    window.addEventListener('goox-extension-input', (event) => {
      updateImageSource(event.detail);
    });

    window.addEventListener('resize', () => {
      if (state.fit) {
        render();
      }
    });

    setStatus('Waiting for file input...');
    emit('event', { topic: 'viewer.ready' });
  }

  document.addEventListener('DOMContentLoaded', boot, { once: true });
})();
