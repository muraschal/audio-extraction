<#
.SYNOPSIS
    Vergleicht mehrere Trennungsergebnisse objektiv miteinander.

.DESCRIPTION
    Misst je Datei Format, integrierte Lautheit (EBU R128) und RMS-Pegel und
    bildet anschliessend für jedes Dateipaar das Differenzsignal.

    Der Differenz-RMS ist die eigentlich interessante Zahl. Er beantwortet:
    wie weit unterscheiden sich zwei Versionen überhaupt? Liegt die Differenz
    40 dB oder mehr unter dem Signalpegel, ist der Unterschied praktisch nicht
    hörbar und die aufwendigere Variante ist verschenkte Rechenzeit. Liegt sie
    bei 25 bis 30 dB darunter, lohnt sich das Gegenhören.

    Ersetzt kein Hören. Kein Messwert sagt, ob eine übrig gebliebene Silbe
    stört oder ob die Becken metallisch klingen — er sagt nur, wo es sich
    lohnt, genau hinzuhören.

.PARAMETER Files
    Zwei oder mehr zu vergleichende Audiodateien.

.PARAMETER WriteDiff
    Schreibt die Differenzsignale zusätzlich als FLAC in den angegebenen
    Ordner, um 20 dB angehoben. Was darin zu hören ist, ist exakt das, worin
    sich die beiden Versionen unterscheiden — der schnellste Weg, den
    Unterschied zweier Modelle zu beurteilen.

.EXAMPLE
    .\scripts\compare.ps1 -Files ".\output\a\song_instrument.wav", ".\output\b\song_Instrumental.wav"

.EXAMPLE
    .\scripts\compare.ps1 -Files $wavs -WriteDiff ".\output\diagnose"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string[]] $Files,
    [string] $WriteDiff
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_common.ps1')

Assert-Tool -Name 'ffmpeg'  -Hint "Installierbar mit 'winget install Gyan.FFmpeg'." | Out-Null
Assert-Tool -Name 'ffprobe' -Hint 'Gehört zur ffmpeg-Installation.'                 | Out-Null

foreach ($f in $Files) {
    if (-not (Test-Path $f)) { throw "Datei nicht gefunden: $f" }
}

# Hinweis für spätere Änderungen: 'Diff' ist in PowerShell ein Alias für
# Compare-Object. Eine Funktion dieses Namens würde nicht greifen, der Aufruf
# landete stattdessen bei Compare-Object. Daher die Verb-Nomen-Namen.

function Get-RmsLevel {
    param([string] $File, [string[]] $ExtraInputs, [string] $FilterGraph)

    $ffArgs = @('-hide_banner', '-nostats', '-i', $File)
    foreach ($extra in $ExtraInputs) { $ffArgs += @('-i', $extra) }
    $ffArgs += @('-filter_complex', $FilterGraph, '-f', 'null', '-')

    $output = Invoke-Native -FilePath 'ffmpeg' -Arguments $ffArgs -Capture

    # astats gibt den RMS je Kanal aus und zuletzt für die Summe — daher -Last 1.
    $line = $output | Select-String -Pattern 'RMS level dB:' | Select-Object -Last 1
    if (-not $line) { return $null }

    # Select-String liefert ein MatchInfo-Objekt, keinen String. Ohne .Line
    # scheitert jede Zeichenkettenoperation darauf.
    if ($line.Line -match 'RMS level dB:\s*(-?[\d.]+|-inf)') { return $Matches[1] }
    return $null
}

function Get-Lufs {
    param([string] $File)

    $output = Invoke-Native -FilePath 'ffmpeg' -Capture -Arguments @(
        '-hide_banner', '-nostats', '-i', $File, '-filter_complex', 'ebur128', '-f', 'null', '-'
    )
    $line = $output | Select-String -Pattern '^\s+I:\s' | Select-Object -Last 1
    if ($line -and $line.Line -match 'I:\s*(-?[\d.]+)') { return $Matches[1] }
    return 'n/a'
}

Write-Host '== Einzelwerte ==' -ForegroundColor Cyan
'{0,-46} {1,-22} {2,10} {3,10}' -f 'Datei', 'Format', 'LUFS', 'RMS dB'
'-' * 92

$stats = @{}
foreach ($f in $Files) {
    $item = Get-Item $f

    # Kein Leerzeichen nach dem Komma: PowerShell würde den Ausdruck sonst als
    # zwei Argumente übergeben und ffprobe meldet 'sample_rate was already
    # specified'.
    $format = (& ffprobe -v error -select_streams a:0 `
                 -show_entries stream=codec_name,sample_rate -of csv=p=0 $f) -join ','

    $lufs = Get-Lufs -File $f
    $rms  = Get-RmsLevel -File $f -FilterGraph 'astats=metadata=0'
    $stats[$f] = $rms

    $short = $item.Name.Substring(0, [Math]::Min(46, $item.Name.Length))
    '{0,-46} {1,-22} {2,10} {3,10}' -f $short, $format, $lufs, $rms
}

if ($Files.Count -lt 2) { return }

Write-Host "`n== Paarweise Differenz ==" -ForegroundColor Cyan
Write-Host '(Differenz-RMS, und wie weit er unter dem Signalpegel liegt)'
'-' * 92

if ($WriteDiff) { New-Item -ItemType Directory -Force -Path $WriteDiff | Out-Null }

# Eine Spur wird invertiert und beide summiert — das ergibt das Differenzsignal.
# normalize=0 ist zwingend, sonst halbiert amix die Pegel und die Zahlen stimmen nicht.
$graph = '[1:a]volume=-1[b];[0:a][b]amix=inputs=2:duration=shortest:normalize=0[m];[m]astats=metadata=0'

for ($i = 0; $i -lt $Files.Count; $i++) {
    for ($j = $i + 1; $j -lt $Files.Count; $j++) {
        $a = $Files[$i]
        $b = $Files[$j]

        $diff  = Get-RmsLevel -File $a -ExtraInputs @($b) -FilterGraph $graph
        $label = '{0}  vs  {1}' -f (Get-Item $a).Directory.Name, (Get-Item $b).Directory.Name

        $below = ''
        if ($diff -and $stats[$a] -and $diff -ne '-inf') {
            $below = '  ({0} dB unter Signal)' -f [math]::Round([double]$stats[$a] - [double]$diff, 1)
        }

        '{0,-52} {1,10}{2}' -f $label.Substring(0, [Math]::Min(52, $label.Length)), $diff, $below

        if ($WriteDiff) {
            $name   = 'diff_{0}_vs_{1}.flac' -f (Get-Item $a).Directory.Name, (Get-Item $b).Directory.Name
            $target = Join-Path $WriteDiff $name

            Invoke-Native -FilePath 'ffmpeg' -Arguments @(
                '-hide_banner', '-loglevel', 'error', '-y', '-i', $a, '-i', $b,
                '-filter_complex',
                '[1:a]volume=-1[b];[0:a][b]amix=inputs=2:duration=shortest:normalize=0[m];[m]volume=20dB[o]',
                '-map', '[o]', '-c:a', 'flac', $target
            ) | Out-Null

            Write-Host "    geschrieben: $target" -ForegroundColor DarkGray
        }
    }
}
