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

**1. Die Prüfroutine laufen lassen.** Ein Befehl deckt sechs Prüfungen ab:

```powershell
.\scripts\check-docs.ps1
```

Geprüft werden die Syntax aller Skripte, das UTF-8-BOM in den `.ps1`-Dateien
und dessen Abwesenheit in Markdown, doppelt kodierte Umlaute, die Anker der
Inhaltsverzeichnisse und alle relativen Verweise.

Die Auswahl ist nicht willkürlich: Jede dieser Prüfungen fängt einen Fehler ab,
der in diesem Repository tatsächlich vorkam. Dieselbe Routine läuft in der CI,
du siehst das Ergebnis also vorab.

Zeigt eine Datei absichtlich eine doppelt kodierte Zeichenfolge — etwa um
genau diesen Fehler zu erklären —, trägt die Zeile den Marker `mojibake-ok`.
In Markdown geht das als HTML-Kommentar am Zeilenende.

**2. Einen echten Durchlauf machen.** Skripte, die nur parsen, sind nicht
getestet, und das kann die CI nicht für dich erledigen:

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
