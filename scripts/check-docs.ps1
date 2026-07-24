<#
.SYNOPSIS
    Prüft Skripte und Dokumentation auf die Fehler, die in diesem Projekt real aufgetreten sind.

.DESCRIPTION
    Führt sechs Prüfungen aus und endet mit Exit-Code 1, sobald eine davon
    fehlschlägt. Gedacht für die CI und zum Ausführen vor einem Pull Request.

    Die Auswahl ist nicht willkürlich: Jede dieser Prüfungen fängt einen
    Fehler ab, der beim Aufbau dieses Repositories tatsächlich passiert ist.
    Eine allgemeine Markdown-Linter-Konfiguration hätte keinen davon gefunden.

.PARAMETER RepoRoot
    Wurzelverzeichnis. Standard: das übergeordnete Verzeichnis dieses Skripts.

.EXAMPLE
    .\scripts\check-docs.ps1
#>
[CmdletBinding()]
param(
    [string] $RepoRoot = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'
$failures = @()

function Write-Check {
    param([string] $Name, [bool] $Ok, [string[]] $Details)
    $mark = if ($Ok) { 'OK  ' } else { 'FEHL' }
    Write-Host ("{0}  {1}" -f $mark, $Name)
    foreach ($d in $Details) { Write-Host "        $d" }
}

$scripts = Get-ChildItem (Join-Path $RepoRoot 'scripts') -Filter '*.ps1'
$markdown = @(Get-ChildItem $RepoRoot -Filter '*.md') +
            @(Get-ChildItem (Join-Path $RepoRoot 'docs') -Filter '*.md' -ErrorAction SilentlyContinue)

# 1. Skripte müssen fehlerfrei parsen.
$bad = @()
foreach ($s in $scripts) {
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($s.FullName, [ref]$null, [ref]$errors) | Out-Null
    if ($errors) { $bad += "$($s.Name): $($errors[0].Message)" }
}
Write-Check 'PowerShell-Syntax' ($bad.Count -eq 0) $bad
if ($bad) { $failures += 'Syntax' }

# 2. Skripte brauchen ein UTF-8-BOM.
#    Ohne BOM liest Windows PowerShell 5.1 die Datei in der ANSI-Codepage.
#    Ein Geviertstrich wird dabei zu einem typografischen Anführungszeichen,
#    das einen String vorzeitig beendet - die Datei parst dann nicht mehr.
$bad = @()
foreach ($s in $scripts) {
    $b = [System.IO.File]::ReadAllBytes($s.FullName)
    if ($b.Length -lt 3 -or $b[0] -ne 0xEF -or $b[1] -ne 0xBB -or $b[2] -ne 0xBF) {
        $bad += "$($s.Name): BOM fehlt"
    }
}
Write-Check 'UTF-8-BOM in .ps1' ($bad.Count -eq 0) $bad
if ($bad) { $failures += 'BOM' }

# 3. Markdown darf umgekehrt kein BOM tragen.
$bad = @()
foreach ($m in $markdown) {
    $b = [System.IO.File]::ReadAllBytes($m.FullName)
    if ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF) {
        $bad += "$($m.Name): BOM vorhanden"
    }
}
Write-Check 'Kein BOM in .md' ($bad.Count -eq 0) $bad
if ($bad) { $failures += 'MD-BOM' }

# 4. Kein doppelt kodiertes UTF-8.
#    Entsteht, sobald ein PowerShell-Skript Text ersetzt, den es selbst als
#    ANSI eingelesen hat: aus einem Umlaut werden zwei Zeichen.
#
#    Zeilen, die eine solche Folge absichtlich zeigen - etwa um genau diesen
#    Fehler zu erklaeren - tragen den Marker 'mojibake-ok' und werden
#    uebersprungen. In Markdown geht das als HTML-Kommentar am Zeilenende.
$bad = @()
foreach ($f in ($scripts + $markdown)) {
    $lineNo = 0
    foreach ($line in [System.IO.File]::ReadAllLines($f.FullName, [System.Text.Encoding]::UTF8)) {
        $lineNo++
        if ($line -match 'mojibake-ok') { continue }
        if ($line -match [char]0x00C3) { $bad += "$($f.Name):$lineNo" }
    }
}
Write-Check 'Keine Mojibake' ($bad.Count -eq 0) $bad
if ($bad) { $failures += 'Mojibake' }

# 5. Anker im Inhaltsverzeichnis müssen auf echte Überschriften zeigen.
$bad = @()
foreach ($m in $markdown) {
    $raw = [System.IO.File]::ReadAllText($m.FullName, [System.Text.Encoding]::UTF8)
    $heads = [regex]::Matches($raw, '(?m)^#{1,6}\s+(.+?)\s*$') | ForEach-Object {
        ($_.Groups[1].Value.ToLower() -replace '[^\p{L}\p{N}\s-]', '' -replace '\s+', '-')
    }
    foreach ($a in [regex]::Matches($raw, '\]\(#([^)]+)\)')) {
        if ($heads -notcontains $a.Groups[1].Value) { $bad += "$($m.Name): #$($a.Groups[1].Value)" }
    }
}
Write-Check 'Anker im Dokument' ($bad.Count -eq 0) $bad
if ($bad) { $failures += 'Anker' }

# 6. Relative Verweise müssen existieren.
$bad = @()
foreach ($m in $markdown) {
    $raw = [System.IO.File]::ReadAllText($m.FullName, [System.Text.Encoding]::UTF8)
    foreach ($link in [regex]::Matches($raw, '\]\((?!https?://|#)([^)]+)\)')) {
        $target = ($link.Groups[1].Value -split '#')[0]
        if (-not $target) { continue }
        $resolved = Join-Path $m.DirectoryName $target
        if (-not (Test-Path $resolved)) { $bad += "$($m.Name) -> $target" }
    }
}
Write-Check 'Relative Verweise' ($bad.Count -eq 0) $bad
if ($bad) { $failures += 'Verweise' }

Write-Host ''
if ($failures.Count -gt 0) {
    Write-Host ("Fehlgeschlagen: {0}" -f ($failures -join ', ')) -ForegroundColor Red
    exit 1
}
Write-Host 'Alle Prüfungen bestanden.' -ForegroundColor Green
