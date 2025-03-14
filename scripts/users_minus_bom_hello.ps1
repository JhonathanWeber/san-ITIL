# Eleva para modo administrador se necessário
param (
    [switch]$Elevated
)

if (-not $Elevated) {
    Start-Process powershell.exe -ArgumentList "-File `"$PSCommandPath`" -Elevated" -Verb RunAs -Wait -NoNewWindow
    exit
}


# Definir política de execução
Set-ExecutionPolicy Bypass -Scope Process -Force

# Forçar codificação UTF-8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Ativar logs do script com UTF-8
Start-Transcript -Path "$env:USERPROFILE\Desktop\log_windows10.txt" -Append -NoClobber

Write-Host "Iniciando otimizações avançadas para Windows 10..." -ForegroundColor Cyan
Start-Sleep -Seconds 3
# ===============================================
# 🔄 Verificar e ajustar usuários 'user' e 'sanemar'
# ===============================================

Write-Host "Iniciando processo de verificação e ajustes nos usuários..." -ForegroundColor Cyan

# Remover usuários com nomes fora do padrão
$usuariosParaRemover = @("User", "Sanemar", "USER", "SANEMAR")
foreach ($usuario in $usuariosParaRemover) {
    $usuarioEncontrado = Get-LocalUser -Name $usuario -ErrorAction SilentlyContinue
    if ($usuarioEncontrado) {
        Write-Host "Removendo usuário com nome fora do padrão: $usuario" -ForegroundColor Yellow
        try {
            Remove-LocalUser -Name $usuario -ErrorAction Stop
            Write-Host "Usuário removido: $usuario" -ForegroundColor Green
        } catch {
            Write-Host "Falha ao remover usuário $usuario: $_" -ForegroundColor Red
        }
    }
}

Start-Sleep -Seconds 2

# Usuário 'user' - remover senha caso exista
$userExiste = Get-LocalUser -Name "user" -ErrorAction SilentlyContinue
if ($userExiste) {
    Write-Host "Usuário 'user' existe, removendo senha..." -ForegroundColor Yellow
    try {
        Set-LocalUser -Name "user" -Password ([securestring]::new()) -ErrorAction Stop
        Write-Host "Senha removida do usuário 'user'." -ForegroundColor Green
    } catch {
        Write-Host "Falha ao remover senha do usuário 'user': $_" -ForegroundColor Red
    }
} else {
    Write-Host "Usuário 'user' não encontrado, criando usuário sem senha..." -ForegroundColor Cyan
    try {
        New-LocalUser -Name "user" -NoPassword -FullName "Usuário Padrão" -Description "Usuário padrão sem senha" -ErrorAction Stop
        Write-Host "Usuário 'user' criado com sucesso." -ForegroundColor Green
    } catch {
        Write-Host "Falha ao criar usuário 'user': $_" -ForegroundColor Red
    }
}

Start-Sleep -Seconds 2

# Usuário 'sanemar' - aplicar senha se existir, caso contrário criar usuário
$senhaSanemar = ConvertTo-SecureString "Sanemar@ti@" -AsPlainText -Force
$sanemarExiste = Get-LocalUser -Name "sanemar" -ErrorAction SilentlyContinue
if ($sanemarExiste) {
    Write-Host "Usuário 'sanemar' existe, aplicando senha..." -ForegroundColor Yellow
    try {
        Set-LocalUser -Name "sanemar" -Password $senhaSanemar -ErrorAction Stop
        Write-Host "Senha aplicada com sucesso no usuário 'sanemar'." -ForegroundColor Green
    } catch {
        Write-Host "Falha ao aplicar senha no usuário 'sanemar': $_" -ForegroundColor Red
    }
} else {
    Write-Host "Usuário 'sanemar' não encontrado, criando usuário com senha..." -ForegroundColor Cyan
    try {
        New-LocalUser -Name "sanemar" -Password $senhaSanemar -FullName "Sanemar TI" -Description "Usuário administrador com senha padrão" -PasswordNeverExpires:$true -ErrorAction Stop
        Write-Host "Usuário 'sanemar' criado com sucesso." -ForegroundColor Green
    } catch {
        Write-Host "Falha ao criar usuário 'sanemar': $_" -ForegroundColor Red
    }
}

Start-Sleep -Seconds 2

# ===============================================
# 🏗️ Adicionar usuários ao grupo Administradores
# ===============================================

$grupoAdministradores = "Administradores"
$usuariosParaAdicionar = @("user", "sanemar")
Write-Host "Adicionando usuários ao grupo '$grupoAdministradores'..." -ForegroundColor Cyan

foreach ($usuario in $usuariosParaAdicionar) {
    try {
        Add-LocalGroupMember -Group $grupoAdministradores -Member $usuario -ErrorAction Stop
        Write-Host "Usuário '$usuario' adicionado ao grupo '$grupoAdministradores'." -ForegroundColor Green
    } catch {
        Write-Host "Falha ao adicionar usuário '$usuario': $_" -ForegroundColor Red
    }
}

# ===============================================
# ❓ Pergunta sobre inativação de usuários ativos
# ===============================================

$resposta = Read-Host "Deseja inativar todos os usuários ativos exceto 'user' e 'sanemar'? (S/N)"

if ($resposta -eq "s") {
    $usuariosAtivos = Get-LocalUser | Where-Object { $_.Enabled -eq $true -and $_.Name -notin @("user", "sanemar") }
    foreach ($usuario in $usuariosAtivos) {
        Write-Host "Inativando usuário ativo: $($usuario.Name)" -ForegroundColor Yellow
        try {
            Disable-LocalUser -Name $usuario.Name -ErrorAction Stop
            Write-Host "Usuário inativado: $($usuario.Name)" -ForegroundColor Green
        } catch {
            Write-Host "Falha ao inativar usuário '$($usuario.Name)': $_" -ForegroundColor Red
        }
    }
    Write-Host "Usuários ativos foram inativados com sucesso." -ForegroundColor Cyan
} else {
    Write-Host "Nenhuma alteração feita nos usuários ativos." -ForegroundColor Cyan
}

# ===============================================
# ➕ Criar novo usuário (Opcional)
# ===============================================

$novoUsuario = Read-Host "Deseja criar um novo usuário? (S/N)"
if ($novoUsuario -eq "s") {
    $nomeCompleto = Read-Host "Digite o nome completo do novo usuário"
    $nomeUsuario = $nomeCompleto -replace "\s", "_"
    try {
        New-LocalUser -Name $nomeUsuario -NoPassword -FullName $nomeCompleto -Description "Usuário criado via script" -PasswordChangeRequired:$true -ErrorAction Stop
        Write-Host "Usuário '$nomeCompleto' criado com sucesso!" -ForegroundColor Green
        
        # Alterar nome e descrição do computador
        $novoNomePC = "SAN-$nomeUsuario"
        Rename-Computer -NewName $novoNomePC -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\services\LanmanServer\Parameters" -Name "srvcomment" -Value "SAN-$nomeUsuario"
    } catch {
        Write-Host "Falha ao criar usuário '$nomeCompleto' ou alterar configurações do computador: $_" -ForegroundColor Red
    }
}

# ===============================================
# 📦 Instalação de Aplicativos
# ===============================================

$applications = @(
    @{ Name="Firefox"; Command="winget install -e --id Mozilla.Firefox" },
    @{ Name="Chrome"; Command="winget install -e --id Google.Chrome" },
    @{ Name="Git"; Command="winget install -e --id Git.Git" },
    @{ Name="Bun"; Command="winget install -e --id oven-sh.bun" },
    @{ Name="7-Zip"; Command="winget install -e --id 7zip.7zip" },
    @{ Name="AnyDesk"; Command="winget install -e --id AnyDeskSoftwareGmbH.AnyDesk" }
)

foreach ($app in $applications) {
    $resposta = Read-Host "Deseja instalar $($app.Name)? (S/N)"
    if ($resposta -eq "s") {
        Write-Host "Instalando $($app.Name)..." -ForegroundColor Cyan
        try {
            Invoke-Expression $app.Command
            Write-Host "$($app.Name) instalado com sucesso!" -ForegroundColor Green
        } catch {
            Write-Host "Falha ao instalar $($app.Name): $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Instalação de $($app.Name) ignorada." -ForegroundColor Yellow
    }
}


Write-Host "Processo concluído com sucesso!" -ForegroundColor Cyan


# 🔄 8. Atualização da lista de usuários
Write-Host "Usuários configurados com sucesso!"
Start-Sleep -Seconds 2
Get-LocalUser | Format-Table -AutoSize | Out-File -FilePath "$env:USERPROFILE\Desktop\usuarios.txt" -Encoding utf8

# Finaliza logs
Stop-Transcript

Write-Host "Script concluído! Reinicie o sistema para aplicar todas as alterações." -ForegroundColor Green
Start-Sleep -Seconds 5
Write-Host "Pressione Enter para sair..." -ForegroundColor Cyan
Read-Host