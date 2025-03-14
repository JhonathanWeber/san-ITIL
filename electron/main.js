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



ipcMain.handle("run-powershell", () => {
  return new Promise((resolve, reject) => {
    // Caminho absoluto até o script hello.ps1 dentro da pasta scripts do projeto
    const scriptPath = path.join(__dirname, "../scripts/users_minus_bom.ps1");

    // Executa o PowerShell como administrador rodando o script diretamente
    const command = `powershell.exe -ExecutionPolicy Bypass "${scriptPath}"`;

    exec(command, (error) => {
      if (error) reject(error.message);
      else resolve("Script executado com sucesso!");
    });
  });
});
