<#
.SYNOPSIS
    Richtet die vollständige Trennungs-Umgebung ein: venv, PyTorch mit CUDA, pymss, yt-dlp.

.DESCRIPTION
    Legt eine virtuelle Umgebung an und installiert darin den kompletten Stack.
    Der PyTorch-Index wird anhand der gefundenen GPU gewählt: Blackwell-Karten
    (RTX 50xx, Compute Capability 12.0) brauchen zwingend cu128 oder neuer, die
    Standard-Wheels von PyPI laufen dort nur auf der CPU.

    Der Torch-Download ist rund 2,7 GB gross und dauert entsprechend.

.PARAMETER VenvPath
    Zielpfad der virtuellen Umgebung. Standard: .venv im Repository-Wurzelverzeichnis.

.PARAMETER TorchIndex
    Überschreibt den automatisch gewählten PyTorch-Index, etwa für ältere
    CUDA-Versionen (cu126) oder eine reine CPU-Installation
    (https://download.pytorch.org/whl/cpu).

.EXAMPLE
    .\scripts\setup.ps1

.EXAMPLE
    .\scripts\setup.ps1 -TorchIndex "https://download.pytorch.org/whl/cpu"
#>
[CmdletBinding()]
param(
    [string] $VenvPath = (Join-Path (Split-Path $PSScriptRoot -Parent) '.venv'),
    [string] $TorchIndex
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_common.ps1')

Write-Host '== Voraussetzungen ==' -ForegroundColor Cyan

Write-Host "  py     -> $(Assert-Tool -Name 'py'     -Hint 'Python von python.org installieren.')"
Write-Host "  ffmpeg -> $(Assert-Tool -Name 'ffmpeg' -Hint "Installierbar mit 'winget install Gyan.FFmpeg'.")"

# GPU ermitteln, um den passenden PyTorch-Build zu wählen.
if (-not $TorchIndex) {
    $gpu = $null
    try {
        $gpu = (nvidia-smi --query-gpu=name --format=csv,noheader) 2>$null
    }
    catch {
        # nvidia-smi fehlt, wenn kein NVIDIA-Treiber installiert ist. Das ist
        # kein Fehler, sondern genau die gesuchte Auskunft: Es gibt keine
        # passende GPU, also wird unten der CPU-Build gewählt.
        Write-Verbose "nvidia-smi nicht verfügbar: $($_.Exception.Message)"
        $gpu = $null
    }

    if ($gpu) {
        Write-Host "  GPU  -> $gpu"
        # cu128 deckt Blackwell (sm_120) ab und läuft ebenso auf Ada und Ampere.
        $TorchIndex = 'https://download.pytorch.org/whl/cu128'
    }
    else {
        Write-Warning 'Keine NVIDIA-GPU gefunden. Es wird der CPU-Build installiert; die Trennung läuft dann um ein Vielfaches langsamer.'
        $TorchIndex = 'https://download.pytorch.org/whl/cpu'
    }
}

Write-Host "`n== Virtuelle Umgebung ==" -ForegroundColor Cyan
if (Test-Path $VenvPath) {
    Write-Host "  bereits vorhanden: $VenvPath"
}
else {
    py -m venv $VenvPath
    Write-Host "  angelegt: $VenvPath"
}

$python = Join-Path $VenvPath 'Scripts\python.exe'
if (-not (Test-Path $python)) {
    throw "Interpreter nicht gefunden unter $python — ist die venv vollständig angelegt?"
}

Write-Host "`n== Pakete ==" -ForegroundColor Cyan
Invoke-Native -FilePath $python -Arguments @('-m', 'pip', 'install', '--upgrade', 'pip', '--quiet') | Out-Null

Write-Host '  yt-dlp ...'
Invoke-Native -FilePath $python -Arguments @('-m', 'pip', 'install', '--upgrade', 'yt-dlp', '--quiet') | Out-Null

Write-Host "  torch + torchaudio (ca. 2,7 GB, aus $TorchIndex) ..."
Invoke-Native -FilePath $python -Arguments @('-m', 'pip', 'install', 'torch', 'torchaudio', '--index-url', $TorchIndex) | Out-Null

Write-Host '  pymss ...'
Invoke-Native -FilePath $python -Arguments @('-m', 'pip', 'install', 'pymss') | Out-Null

Write-Host "`n== Prüfung ==" -ForegroundColor Cyan
& $python -c @"
import torch
print(f'  torch      {torch.__version__}')
if torch.cuda.is_available():
    print(f'  CUDA       ja - {torch.cuda.get_device_name(0)}')
    print(f'  capability {torch.cuda.get_device_capability(0)}')
else:
    print('  CUDA       nein (CPU-Betrieb)')
"@

Write-Host "`nFertig. Nächster Schritt: .\scripts\fetch.ps1 -Url <youtube-url>" -ForegroundColor Green
