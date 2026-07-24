# Mitwirken

Danke für dein Interesse. Dieses Projekt ist bewusst klein gehalten: vier
Skripte, die eine Aufgabe erledigen. Beiträge sind willkommen, sollten diesen
Zuschnitt aber nicht sprengen.

## Umgebung einrichten

```powershell
git clone https://github.com/muraschal/audio-extraction.git
cd audio-extraction
.\scripts\setup.ps1
```

Weitere Werkzeuge braucht es nicht. Die venv unter `.venv` bleibt
unversioniert.

## Vor jedem Pull Request

Es gibt keine CI, die dir das abnimmt. Diese drei Schritte laufen von Hand:

**1. Syntax prüfen.** Alle Skripte müssen fehlerfrei parsen:

```powershell
Get-ChildItem scripts\*.ps1 | ForEach-Object {
    $e = $null
    [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$e) | Out-Null
    if ($e) { "FEHLER $($_.Name): $($e[0].Message)" } else { "OK $($_.Name)" }
}
```

**2. Kodierung prüfen.** Jede `.ps1`-Datei braucht ein UTF-8-BOM
(`EF BB BF`). Ohne BOM liest Windows PowerShell 5.1 sie in der ANSI-Codepage,
und Umlaute kommen falsch an — im schlimmsten Fall parst die Datei nicht mehr:

```powershell
Get-ChildItem scripts\*.ps1 | ForEach-Object {
    $b = [System.IO.File]::ReadAllBytes($_.FullName)[0..2]
    "{0,-20} {1}" -f $_.Name, (($b | ForEach-Object { $_.ToString('X2') }) -join ' ')
}
```

Markdown-Dateien tragen dagegen kein BOM.

**3. Einen echten Durchlauf machen.** Skripte, die nur parsen, sind nicht
getestet:

```powershell
.\scripts\fetch.ps1 -Url "<eine-url>" -Name "test"
.\scripts\separate.ps1 -Path ".\input\test.wav"
.\scripts\compare.ps1 -Files @(".\output\bs_roformer_voc_hyperacev2\test_instrument.wav")
```

## Konventionen

**Externe Programme über `Invoke-Native` aufrufen.** ffmpeg, pymss und yt-dlp
schreiben nach stderr, was PowerShell unter `$ErrorActionPreference = 'Stop'`
als Fehler behandelt. `Invoke-Native` in `_common.ps1` wertet allein
`$LASTEXITCODE` aus. Ein direkter Aufruf bricht früher oder später ab.

**Keine Dateinamen erraten.** Jedes Modell benennt seine Stems anders. Listet
den Ausgabeordner auf, statt einen Namen fest zu verdrahten.

**Messwerte belegen.** Zahlen in `docs/messungen.md` stammen aus tatsächlichen
Läufen, nicht aus Herstellerangaben. Wer einen Wert ändert, nennt die Hardware
und den Befehl, mit dem er entstanden ist.

**Sprache.** Dokumentation und Kommentare auf Deutsch, in Schweizer
Schreibweise (`ss` statt `ß`). Parameter- und Funktionsnamen auf Englisch,
nach dem PowerShell-Schema Verb-Nomen.

**Kommentare begründen, statt zu beschreiben.** Was der Code tut, steht im
Code. In den Kommentar gehört, warum er es so tut — besonders dort, wo eine
naheliegende Alternative nicht funktioniert.

## Was nicht ins Repository gehört

Der `.gitignore` arbeitet als Allowlist: Alles ist ignoriert, bis es
ausdrücklich zugelassen wird. Das ist Absicht, weil das Arbeitsverzeichnis
zugleich Audiomaterial, die venv und Modell-Checkpoints enthält.

Wer eine neue Datei versionieren will, ergänzt eine `!`-Zeile. Bitte die
Allowlist nicht in eine Deny-Liste umbauen — bei einem öffentlichen Repository
ist die Richtung entscheidend.

Audiodateien gehören nie ins Repository, auch nicht als Beispiel.

## Fehler melden

Ein brauchbarer Bericht nennt die PowerShell-Version (`$PSVersionTable`), die
GPU, das verwendete Modell und den vollständigen Aufruf. Bei Trennungsproblemen
hilft die Ausgabe von `compare.ps1` mehr als eine Beschreibung des Klangs.
