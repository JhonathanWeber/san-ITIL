const { app, BrowserWindow, ipcMain } = require("electron");
const path = require("path");
const { exec } = require("child_process");

const createWindow = () => {
  const mainWindow = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
      preload: path.join(__dirname, "preload.js"),
    },
  });

  mainWindow.loadURL("http://localhost:5173");
};

app.whenReady().then(createWindow);

// Comando IPC para executar PowerShell como administrador
ipcMain.handle("run-powershell", (_, command) => {
  return new Promise((resolve, reject) => {
    exec(
      `powershell.exe -Command "Start-Process powershell -Verb RunAs"`,
      (error) => {
        if (error) reject(error.message);
        else resolve("PowerShell aberto com sucesso!");
      }
    );
  });
});
