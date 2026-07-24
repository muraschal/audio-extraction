# audio-extraction

Lokale Stem-Trennung auf der eigenen GPU: Gesang aus einem Song entfernen, in
messbarer Qualitaet, ohne Upload und ohne laufende Kosten.

Vier PowerShell-Skripte bilden die Kette ab — Umgebung einrichten, Quelle
holen, trennen, Ergebnisse objektiv vergleichen. Der Vergleichsschritt ist
Absicht: bei Trennungsmodellen entscheidet nicht der hoechste Benchmark-Wert,
sondern was auf dem konkreten Stueck herauskommt.

## Warum lokal

Ein 2:33 langer Track ist auf einer RTX 5080 in **4 Sekunden** getrennt. Damit
kippt die uebliche Abwaegung: Wenn ein Durchgang praktisch nichts kostet, ist
das Durchprobieren mehrerer Modelle schneller als jede Vorabrecherche darueber,
welches das beste sein soll.

Dazu kommen 32-Bit-Float-Ausgabe statt der 16 Bit, die Gratiskonten von
Onlinediensten ueblicherweise liefern, keine Warteschlange, keine Laengen- oder
Mengenbegrenzung, und das Material verlaesst den eigenen Rechner nicht.

Ehrlich dagegengehalten: Das derzeit staerkste Modell auf MVSep,
`BS Roformer 124 bands (ver. 2026.07)`, ist dort exklusiv und lokal nicht
verfuegbar. Die offenen Checkpoints liegen einige SDR-Zehntel darunter. Wer das
letzte Zehntel braucht und den Upload nicht scheut, faehrt dort besser.

## Voraussetzungen

| | |
|---|---|
| Python | 3.10 oder neuer, ueber den `py`-Launcher erreichbar |
| ffmpeg | im PATH (`winget install Gyan.FFmpeg`) |
| GPU | NVIDIA mit 8 GB VRAM oder mehr empfohlen; CPU-Betrieb geht, dauert aber ein Vielfaches |
| Platz | rund 3 GB fuer PyTorch, dazu 0,3 bis 0,7 GB je Modell |

Fuer RTX-50xx-Karten (Blackwell, `sm_120`) ist der PyTorch-Build entscheidend:
Es braucht `cu128` oder neuer. Die Standard-Wheels von PyPI kennen diese
Architektur nicht und fallen still auf die CPU zurueck — die Trennung laeuft
dann, nur eben zehn- bis fuenfzigmal langsamer. `setup.ps1` waehlt den
passenden Index selbst.

## Schnellstart

```powershell
git clone https://github.com/muraschal/audio-extraction.git
cd audio-extraction
.\scripts\setup.ps1
```

Danach die Quelle holen und trennen:

```powershell
.\scripts\fetch.ps1 -Url "https://youtu.be/XXXXXXXXXXX" -Name "song"
.\scripts\separate.ps1 -Path ".\input\song.wav"
```

Die Stems liegen anschliessend in `output\bs_roformer_voc_hyperacev2\`.

Ein zweites Modell zum Gegenvergleich, danach die Messung:

```powershell
.\scripts\separate.ps1 -Path ".\input\song.wav" -Model model_bs_roformer_ep_317_sdr_12.9755

.\scripts\compare.ps1 -Files @(
    ".\output\bs_roformer_voc_hyperacev2\song_instrument.wav",
    ".\output\model_bs_roformer_ep_317_sdr_12.9755\song_Instrumental.wav"
) -WriteDiff ".\output\diagnose"
```

## Die Skripte

### `setup.ps1`

Legt die venv an und installiert yt-dlp, PyTorch und pymss. Erkennt die GPU und
waehlt den passenden PyTorch-Index; ohne NVIDIA-Karte den CPU-Build. Prueft zum
Schluss, ob CUDA tatsaechlich greift — diese Ausgabe lohnt einen Blick, denn
eine stille CPU-Rueckfallebene faellt sonst erst an der Laufzeit auf.

### `fetch.ps1`

Laedt die hoechstbitratige Tonspur und erzeugt daraus eine 24-Bit-WAV. Mit
`-ListFormats` siehst du vorher, was zur Auswahl steht.

Zur Quelle: Die Umwandlung nach WAV stellt nichts wieder her, sie verhindert
nur weitere Verluste in der Kette. Wo eine gekaufte WAV oder FLAC existiert,
ist sie der bessere Ausgangspunkt — und zwar mit deutlichem Abstand. Der
Unterschied zwischen 140-kbps-Opus und einer verlustfreien Quelle wiegt im
Endergebnis schwerer als der zwischen zwei Trennungsmodellen.

### `separate.ps1`

Ruft pymss auf und legt die Stems in einem nach Modell benannten Unterordner
ab, sodass sich mehrere Modelle nebeneinander vergleichen lassen.

Ausgabe ist 32-Bit-Float-WAV. Das ist kein Selbstzweck: Getrennte Stems
ueberschreiten regelmaessig 0 dBFS, weil ihre Summe lauter sein kann als das
Original. Float haelt diese Werte fest, 16 oder 24 Bit wuerden clippen.

### `compare.ps1`

Misst Format, Lautheit und RMS jeder Datei und bildet fuer jedes Paar das
Differenzsignal.

Der Differenz-RMS ist die eigentlich nuetzliche Zahl. Er beantwortet, wie weit
sich zwei Versionen ueberhaupt unterscheiden. Liegt die Differenz 40 dB oder
mehr unter dem Signalpegel, ist der Unterschied nicht hoerbar und die
aufwendigere Variante verschenkte Rechenzeit. Bei 25 bis 30 dB darunter lohnt
das Gegenhoeren.

Mit `-WriteDiff` landet das Differenzsignal um 20 dB angehoben als FLAC auf der
Platte. Was darin zu hoeren ist, ist exakt das, worueber die beiden Modelle
uneins sind — meist Hallfahnen und Zischlaute. Das ist der schnellste Weg zur
Entscheidung, viel schneller als den ganzen Song zweimal durchzuhoeren.

### `_common.ps1`

Kein eigenstaendiges Skript, sondern gemeinsame Hilfsfunktionen. Enthaelt vor
allem `Invoke-Native`, das die Aufrufe externer Programme kapselt — siehe
[Stolpersteine](#stolpersteine).

## Modellwahl

`pymss list` zeigt ueber 200 Modelle. Fuer Gesangsentfernung sind diese der
sinnvolle Einstieg:

| Modell | Groesse | Anmerkung |
|---|---|---|
| `bs_roformer_voc_hyperacev2` | 289 MB | guter Standard, schnell |
| `model_bs_roformer_ep_317_sdr_12.9755` | 639 MB | bekannter starker Checkpoint |
| `model_bs_roformer_ep_368_sdr_12.9628` | — | Alternative zum Gegenhoeren |

Vier, fuenf oder sechs Stems zu erzeugen bringt fuer diesen Zweck nichts. Mehr
Stems bedeuten nicht automatisch ein saubereres Instrumental — sie bedeuten nur
mehr Dateien.

## Ergebnisse

Gemessen, nicht uebernommen — Einzelheiten in [docs/messungen.md](docs/messungen.md):

- **TTA lohnte sich nicht.** Mit und ohne Test-Time-Augmentation unterschieden
  sich die Ergebnisse um 47 dB unter Signalpegel, also unhoerbar, bei
  dreifacher Rechenzeit.
- **Die Modellwahl wog schwerer, blieb aber ueberschaubar.** Zwei
  BS-RoFormer-Modelle divergierten um 26 dB unter Signalpegel. Hoerbar beim
  konzentrierten Vergleich, kein Unterschied zwischen brauchbar und unbrauchbar.
- **Alle Modelle rechnen intern mit 44,1 kHz.** Eine 48-kHz-Quelle wird also
  neu abgetastet. Das ist modellbedingt und liesse sich auch auf MVSep nicht
  umgehen.

## Wenn Hallreste bleiben

Trockener Hauptgesang laesst sich sehr gut entfernen. Schwieriger sind
Vocal-Hall und Delay, weil sie klanglich bereits Teil des Instrumentals
geworden sind.

Der uebliche Rat lautet, dafuer SpectraLayers oder iZotope RX zu kaufen. Das
ist oft nicht noetig: pymss bringt eigene Dereverb-Modelle mit, die auf dem
fertigen Instrumental in denselben Sekunden laufen.

```powershell
.\scripts\separate.ps1 `
    -Path ".\output\bs_roformer_voc_hyperacev2\song_instrument.wav" `
    -Model dereverb_bs_roformer_anvuew_sdr_22.5050
```

Erst wenn danach noch einzelne Silben stoeren, lohnt ein spektraler Editor —
und dann fuer die betroffenen Sekunden, nicht fuer den ganzen Song. Den
gesamten Titel aggressiver zu trennen kostet Becken, Synthesizer und Snare.

## Stolpersteine

Fuenf Dinge, die beim Aufbau Zeit gekostet haben und in den Skripten bereits
beruecksichtigt sind:

**stderr ist in PowerShell 5.1 kein Fehler, wird aber als solcher behandelt.**
Der groesste Fallstrick. Sobald der Ausgabestrom eines nativen Programms
umgeleitet wird, verpackt PowerShell jede stderr-Zeile in einen ErrorRecord und
setzt `$?` auf false. Unter `$ErrorActionPreference = 'Stop'` bricht das Skript
dadurch ab, obwohl das Programm mit Exit-Code 0 endet. Das trifft hier alle
drei Werkzeuge: ffmpeg schreibt saemtliche Messwerte nach stderr, pymss die
Fortschrittsanzeige, yt-dlp gelegentliche Warnungen. `Invoke-Native` in
`_common.ps1` kapselt das an einer Stelle und wertet allein `$LASTEXITCODE` aus.

**`--print` schaltet yt-dlp in den Simulationsmodus.** Metadaten abfragen und
herunterladen in einem Aufruf zu kombinieren fuehrt dazu, dass gar nichts
geschrieben wird — ohne Fehlermeldung. Deshalb sind es in `fetch.ps1` zwei
getrennte Aufrufe.

**Die Stems heissen je nach Modell anders.** `hyperacev2` schreibt
`_instrument`, `ep317` dagegen `_Instrumental`. Fest verdrahtete Dateinamen
laufen ins Leere.

**`Diff` ist in PowerShell ein Alias fuer `Compare-Object`.** Eine eigene
Funktion dieses Namens greift nicht, der Aufruf landet stattdessen bei
`Compare-Object`.

**`Select-String` liefert ein `MatchInfo`-Objekt, keinen String.** Ohne `.Line`
scheitert jede Zeichenkettenoperation darauf.

## Was bewusst nicht im Repository liegt

Der `.gitignore` folgt dem Allowlist-Prinzip: erst wird alles ignoriert, dann
werden gezielt Skripte, Dokumentation und Lizenz wieder zugelassen. Bei einer
gewoehnlichen Deny-Liste waere jede neu entstehende Datei standardmaessig
committet — hier ist es umgekehrt.

Draussen bleiben damit Audiodateien und Stems, die venv mit rund 3 GB, sowie
die Modell-Checkpoints, die ohnehin beim ersten Lauf automatisch geladen
werden. Bei einem oeffentlichen Repository ist die Allowlist die richtige
Richtung.

## Rechtliches

Das Schweizer Urheberrecht erlaubt Privatgebrauch im persoenlichen Kreis,
einschliesslich Familie und engen Freunden. Eine bearbeitete Instrumentalfassung
zu veroeffentlichen, weiterzuverbreiten, oeffentlich auffuehren oder kommerziell
zu nutzen erfordert dagegen in aller Regel die Erlaubnis der Rechteinhaber.

Dieses Repository enthaelt Werkzeuge, kein Audiomaterial. Keine Rechtsberatung.

## Lizenz

MIT — siehe [LICENSE](LICENSE).

Die verwendeten Modelle und Bibliotheken stehen unter eigenen Lizenzen.
Insbesondere ist [pymss](https://pypi.org/project/pymss/) davon unabhaengig
lizenziert; die Modell-Checkpoints stammen aus der
Music-Source-Separation-Community und haben jeweils eigene Nutzungsbedingungen.
