<#
.SYNOPSIS
    Trennt eine Audiodatei mit pymss in Gesang und Instrumental.

.DESCRIPTION
    Ruft pymss auf und legt die Stems in einem nach Modell benannten
    Unterordner ab, damit sich mehrere Modelle nebeneinander vergleichen lassen.

    Die Ausgabe erfolgt standardmaessig als 32-Bit-Float-WAV. Das ist kein
    Selbstzweck: Float haelt Werte oberhalb 0 dBFS fest, was bei getrennten
    Stems regelmaessig vorkommt, weil sich die Summe zweier Stems lauter
    addieren kann als das Original. In 16 oder 24 Bit wuerde an dieser Stelle
    hart geclippt.

.PARAMETER Path
    Eingangsdatei oder -ordner.

.PARAMETER Model
    pymss-Modellname. Eine Uebersicht liefert 'pymss list'. Bewaehrt fuer
    Gesangsentfernung sind bs_roformer_voc_hyperacev2 und
    model_bs_roformer_ep_317_sdr_12.9755.

.PARAMETER OutDir
    Ausgabeordner. Standard: output\<Modellname>\ im Wurzelverzeichnis.

.PARAMETER Tta
    Aktiviert Test-Time-Augmentation. Verdreifacht die Rechenzeit. Auf dem
    hier vermessenen Material lag der Unterschied rund 47 dB unter Signalpegel,
    war also unhoerbar - siehe docs/messungen.md, bevor du das einschaltest.

.PARAMETER Format
    Ausgabeformat: wav, flac, mp3 oder m4a.

.PARAMETER Device
    Rechenwerk: auto, cuda, cpu, mps oder mlx.

.EXAMPLE
    .\scripts\separate.ps1 -Path ".\input\song.wav"

.EXAMPLE
    .\scripts\separate.ps1 -Path ".\input\song.wav" -Model model_bs_roformer_ep_317_sdr_12.9755
#>
[CmdletBinding()]
param(
    # Nicht $Input nennen: das ist in PowerShell eine automatische Variable
    # und wuerde beim Aufruf still ueberschrieben.
    [Parameter(Mandatory)] [string] $Path,

    [string] $Model = 'bs_roformer_voc_hyperacev2',
    [string] $OutDir,
    [switch] $Tta,

    [ValidateSet('wav', 'flac', 'mp3', 'm4a')]
    [string] $Format = 'wav',

    [ValidateSet('auto', 'cuda', 'cpu', 'mps', 'mlx')]
    [string] $Device = 'auto'
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_common.ps1')

$repoRoot = Split-Path $PSScriptRoot -Parent
$pymss    = Join-Path $repoRoot '.venv\Scripts\pymss.exe'

if (-not (Test-Path $pymss))  { throw "pymss nicht gefunden. Zuerst .\scripts\setup.ps1 ausfuehren." }
if (-not (Test-Path $Path))   { throw "Eingangsdatei nicht gefunden: $Path" }

if (-not $OutDir) {
    $suffix = if ($Tta) { "$Model+tta" } else { $Model }
    $OutDir = Join-Path $repoRoot "output\$suffix"
}

$pymssArgs = @(
    'infer', $Model,
    '-i', $Path,
    '-o', $OutDir,
    '--download',
    '--device', $Device,
    '--format', $Format
)
if ($Format -eq 'wav') { $pymssArgs += @('--wav-bit-depth', 'FLOAT') }
if ($Tta)              { $pymssArgs += '--tta' }

Write-Host "Modell : $Model$(if ($Tta) { ' (+TTA)' })" -ForegroundColor Cyan
Write-Host "Quelle : $Path"
Write-Host "Ziel   : $OutDir`n"

# pymss schreibt Protokoll und Fortschrittsanzeige nach stderr - siehe die
# Begruendung in _common.ps1, weshalb der direkte Aufruf hier abbrechen wuerde.
$started = Get-Date
Invoke-Native -FilePath $pymss -Arguments $pymssArgs | Out-Null
$elapsed = (Get-Date) - $started

Write-Host "`nDauer: $([math]::Round($elapsed.TotalSeconds, 1)) s" -ForegroundColor Green

# Die Stems heissen je nach Modell unterschiedlich - hyperacev2 schreibt
# '_instrument', ep317 dagegen '_Instrumental'. Deshalb wird hier aufgelistet
# statt geraten.
Get-ChildItem $OutDir -File |
    Select-Object Name, @{ n = 'MB'; e = { [math]::Round($_.Length / 1MB, 2) } } |
    Format-Table -AutoSize
