# Changelog

Alle nennenswerten Änderungen an diesem Projekt. Das Format folgt
[Keep a Changelog](https://keepachangelog.com/de/1.1.0/), die Versionierung
[Semantic Versioning](https://semver.org/lang/de/).

## [1.2.0] — 2026-07-24

### Hinzugefügt

- `docs/erste-schritte.md`: Anleitung ohne Vorkenntnisse, vom leeren Rechner
  bis zum fertigen Instrumental, mit Abschnitt zu häufigen Problemen und einer
  kurzen Begriffserklärung. Nach Diátaxis war der Typ „Tutorial" bisher nicht
  abgedeckt; das README setzt PowerShell- und git-Kenntnisse voraus.
- `scripts/check-docs.ps1`: prüft Syntax, BOM-Regeln, doppelt kodierte
  Umlaute, Anker und relative Verweise. Jede Prüfung fängt einen Fehler ab,
  der in diesem Repository tatsächlich vorkam.
- GitHub Actions unter `.github/workflows/docs.yml` mit `check-docs.ps1`,
  PSScriptAnalyzer und einer Verweisprüfung. Externe Verweise melden nur und
  blockieren keinen Pull Request, weil Dienste zeitweise mit 403 oder
  Ratenbegrenzung antworten.
- Issue-Formular und Pull-Request-Vorlage unter `.github/`.

### Geändert

- `CONTRIBUTING.md` ersetzt die drei manuellen Prüfschritte durch den Aufruf
  von `check-docs.ps1`.

## [1.1.0] — 2026-07-24

### Hinzugefügt

- Parameterreferenz im README mit allen Schaltern je Skript und dem Hinweis auf
  `Get-Help <skript> -Full`.
- Mermaid-Diagramm der Verarbeitungskette, Badge-Zeile, Management Summary und
  Inhaltsverzeichnis im README.
- `CONTRIBUTING.md` und diese Datei.
- Abschnitt „Reproduzieren" in `docs/messungen.md`.
- Laufzeit des Dereverb-Modells in der Messtabelle.

### Geändert

- Alle Dokumente und Skripte verwenden echte Umlaute statt der bisherigen
  ASCII-Ersatzschreibweise (`ae`, `oe`, `ue`).
- Die `.ps1`-Dateien tragen jetzt ein UTF-8-BOM. Ohne BOM liest Windows
  PowerShell 5.1 sie in der ANSI-Codepage; `setup.ps1` liess sich dadurch nicht
  mehr parsen, und `Get-Help` gab beschädigte Zeichen aus.
- Zeitangabe im README auf 3,8 s Verarbeitung und rund 9 s Gesamtdauer
  präzisiert. Die frühere Angabe von 4 Sekunden nannte nur die Verarbeitung.

### Behoben

- Der dokumentierte Aufruf `pymss list` schlug fehl, weil `pymss` nicht im PATH
  liegt. Korrekt ist `.\.venv\Scripts\pymss.exe list`.
- Das Dereverb-Beispiel erwähnte nicht, dass zwei Stems entstehen
  (`_noreverb` und `_reverb`) und welcher davon weiterverwendet wird.
- Die Regel zur Stem-Benennung nannte nur zwei Konventionen; die
  Dereverb-Modelle bringen eine dritte mit.

## [1.0.0] — 2026-07-24

### Hinzugefügt

- `setup.ps1`, `fetch.ps1`, `separate.ps1`, `compare.ps1` und `_common.ps1`.
- `README.md` und `docs/messungen.md` mit auf einer RTX 5080 gemessenen Werten.
- `.gitignore` nach dem Allowlist-Prinzip.

[1.2.0]: https://github.com/muraschal/audio-extraction/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/muraschal/audio-extraction/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/muraschal/audio-extraction/releases/tag/v1.0.0
