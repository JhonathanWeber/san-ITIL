import "./App.css";

function App() {
  const handleClick = async () => {
    try {
      const response = await window.electronAPI.runPowerShell();
      alert("Sucesso: " + response);
    } catch (error) {
      alert("Erro: " + error);
    }
  };

  return (
    <div>
      <h1>Electron + React 🚀</h1>
      <button onClick={handleClick}>Executar PowerShell (Admin)</button>
    </div>
  );
}

export default App;
