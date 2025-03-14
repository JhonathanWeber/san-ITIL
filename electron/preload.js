const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("electronAPI", {
  runPowerShell: (command) => ipcRenderer.invoke("run-powershell", command),
});
