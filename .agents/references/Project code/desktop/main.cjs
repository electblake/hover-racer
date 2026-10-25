const { app, BrowserWindow, dialog } = require('electron');
const path = require('node:path');

const smokeTest = process.argv.includes('--smoke-test');
let window;

async function createWindow() {
  window = new BrowserWindow({
    title: 'Wipeout Racer',
    width: 1440,
    height: 900,
    minWidth: 800,
    minHeight: 600,
    backgroundColor: '#0e1726',
    autoHideMenuBar: true,
    show: !smokeTest,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      sandbox: true
    }
  });
  window.setMenu(null);
  window.webContents.setWindowOpenHandler(() => ({ action: 'deny' }));
  window.webContents.on('will-navigate', event => event.preventDefault());
  window.webContents.on('before-input-event', (event, input) => {
    if (input.type !== 'keyDown') return;
    if (input.key === 'F11') {
      event.preventDefault();
      window.setFullScreen(!window.isFullScreen());
    } else if (input.key === 'Escape' && window.isFullScreen()) {
      window.setFullScreen(false);
    }
  });
  await window.loadFile(path.join(__dirname, '..', 'index.html'));

  if (smokeTest) {
    // Run against the real renderer, including its built-in physics regression tests.
    const result = await window.webContents.executeJavaScript(`(() => {
      const canvas = document.getElementById('view');
      const error = document.getElementById('error');
      document.getElementById('audit').click();
      const report = document.getElementById('report').textContent;
      const counts = report.match(/(\\d+) \\/ (\\d+) regression tests passed/);
      return {
        webgl2: !!canvas.getContext('webgl2'),
        error: error.textContent,
        passed: counts ? Number(counts[1]) : 0,
        total: counts ? Number(counts[2]) : 0,
        isolated: typeof window.require === 'undefined' && typeof window.process === 'undefined'
      };
    })()`);
    console.log(JSON.stringify(result));
    app.exit(result.webgl2 && !result.error && result.isolated &&
      result.total > 0 && result.passed === result.total ? 0 : 1);
  }
}

app.whenReady().then(createWindow).catch(error => {
  console.error(error);
  if (!smokeTest) dialog.showErrorBox('Unable to start Wipeout Racer', error.message);
  app.exit(1);
});
app.on('window-all-closed', () => app.quit());
if (smokeTest) {
  setTimeout(() => {
    console.error('Game smoke test timed out.');
    app.exit(1);
  }, 30000).unref();
}
