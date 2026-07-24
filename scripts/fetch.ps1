<#
.SYNOPSIS
    Lädt die beste verfügbare Tonspur einer Video-URL und legt sie als WAV ab.

.DESCRIPTION
    Holt via yt-dlp die höchstbitratige Audiospur, behält das Original als
    Referenz und erzeugt daraus eine 24-Bit-WAV für die Trennung.

    Zur Quellqualität: YouTube liefert verlustbehaftetes Opus oder AAC. Die
    Umwandlung nach WAV stellt nichts wieder her, sie verhindert nur weitere
    Verluste in der Verarbeitungskette. Wo eine gekaufte WAV oder FLAC
    existiert, ist diese der deutlich bessere Ausgangspunkt — der Unterschied
    im Endergebnis ist grösser als der zwischen zwei Trennungsmodellen.

.PARAMETER Url
    Video-URL, aus der die Tonspur geholt wird.

.PARAMETER OutDir
    Zielordner. Standard: input\ im Repository-Wurzelverzeichnis.

.PARAMETER Name
    Basisname der Zieldatei ohne Endung. Standard: der Videotitel.

.PARAMETER FormatId
    Erzwingt eine bestimmte yt-dlp-Format-ID. Ohne Angabe wählt yt-dlp
    'bestaudio'. Mit -ListFormats siehst du, was zur Auswahl steht.

.PARAMETER ListFormats
    Listet nur die verfügbaren Audioformate auf und lädt nichts.

.EXAMPLE
    .\scripts\fetch.ps1 -Url "https://youtu.be/XXXXXXXXXXX" -ListFormats

.EXAMPLE
    .\scripts\fetch.ps1 -Url "https://youtu.be/XXXXXXXXXXX" -Name "song"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $Url,
    [string] $OutDir = (Join-Path (Split-Path $PSScriptRoot -Parent) 'input'),
    [string] $Name,
    [string] $FormatId,
    [switch] $ListFormats
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_common.ps1')

$repoRoot = Split-Path $PSScriptRoot -Parent
$ytdlp    = Join-Path $repoRoot '.venv\Scripts\yt-dlp.exe'

if (-not (Test-Path $ytdlp)) { throw "yt-dlp nicht gefunden. Zuerst .\scripts\setup.ps1 ausführen." }
Assert-Tool -Name 'ffmpeg' -Hint "Installierbar mit 'winget install Gyan.FFmpeg'." | Out-Null

if ($ListFormats) {
    $formats = Invoke-Native -FilePath $ytdlp -Arguments @('--no-playlist', '-F', $Url) -Capture
    $formats | Select-String -Pattern 'audio only'
    return
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# Metadaten und Download sind bewusst zwei getrennte Aufrufe: --print schaltet
# yt-dlp implizit in den Simulationsmodus. Kombiniert man beides, wird ohne
# jede Fehlermeldung gar keine Datei geschrieben.
$meta = Invoke-Native -FilePath $ytdlp -Capture -Arguments @(
    '--no-playlist',
    '--print', '%(title)s',
    '--print', '%(duration_string)s',
    '--print', '%(acodec)s',
    '--print', '%(abr)s',
    $Url
)

# Warnungen herausfiltern, die yt-dlp ebenfalls in den Ausgabestrom schreibt.
$fields = $meta | Where-Object { $_ -notmatch '^\s*(WARNING|ERROR|\[)' }

$title = $fields[0]
Write-Host "Titel   : $title"
Write-Host "Länge   : $($fields[1])"
Write-Host "Codec   : $($fields[2]) @ $($fields[3]) kbps"

if (-not $Name) {
    # Für Dateisysteme unzulässige Zeichen ersetzen.
    $Name = ($title -replace '[\\/:*?"<>|]', '_').Trim()
}

$downloadArgs = @('--no-playlist', '-o', (Join-Path $OutDir "$Name.%(ext)s"))
$downloadArgs += if ($FormatId) { @('-f', $FormatId) } else { @('-f', 'bestaudio') }
$downloadArgs += $Url

Invoke-Native -FilePath $ytdlp -Arguments $downloadArgs | Out-Null

$original = Get-ChildItem $OutDir -File |
    Where-Object { $_.BaseName -eq $Name -and $_.Extension -ne '.wav' } |
    Select-Object -First 1

if (-not $original) { throw "Nach dem Download wurde keine Quelldatei gefunden. Prüfe die Ausgabe von yt-dlp." }

$wav = Join-Path $OutDir "$Name.wav"
Write-Host "`nWandle nach 24-Bit-WAV ..."

# Keine Neuabtastung: die Abtastrate der Quelle bleibt erhalten. Die Modelle
# rechnen zwar intern mit 44,1 kHz, aber dieser eine Resample-Schritt gehört
# in die Trennung und nicht zusätzlich schon hierhin.
Invoke-Native -FilePath 'ffmpeg' -Arguments @(
    '-hide_banner', '-loglevel', 'error', '-y', '-i', $original.FullName, '-c:a', 'pcm_s24le', $wav
) | Out-Null

$size = [math]::Round((Get-Item $wav).Length / 1MB, 2)
Write-Host "`nBereit: $wav ($size MB)" -ForegroundColor Green
Write-Host "Nächster Schritt: .\scripts\separate.ps1 -Path `"$wav`""
