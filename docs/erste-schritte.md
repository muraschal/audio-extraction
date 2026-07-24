# Erste Schritte

Diese Anleitung führt dich vom leeren Rechner bis zum fertigen Instrumental.
Sie setzt keine Vorkenntnisse voraus. Wenn du noch nie ein schwarzes Fenster
mit Text darin benutzt hast, ist das in Ordnung — du tippst hier ein paar
Zeilen ab, mehr nicht.

## Was du am Ende hast

Aus einem Song werden zwei Dateien:

- **das Instrumental** — der Song ohne Gesang, zum Mitsingen oder Üben
- **die Gesangsspur** — nur die Stimme, ohne Instrumente

Du kannst beides einzeln anhören.

## Was du dafür brauchst

> [!IMPORTANT]
> Du brauchst einen **Windows-PC mit einer NVIDIA-Grafikkarte**. Ohne diese
> Karte funktioniert alles trotzdem, dauert aber statt Sekunden viele Minuten
> pro Song.
>
> Wenn du keinen solchen PC hast oder dir das hier zu umständlich ist: Auf
> [mvsep.com](https://mvsep.com) lädst du deinen Song hoch und bekommst das
> Gleiche ohne Installation. Das Ergebnis ist minim besser, dafür musst du die
> Datei aus der Hand geben und wartest in einer Warteschlange.

Rechne für die einmalige Einrichtung mit **30 bis 45 Minuten**, davon ist das
meiste Wartezeit beim Herunterladen. Jeder weitere Song dauert danach unter
einer Minute.

## Schritt 1: Die Kommandozeile öffnen

Alles Folgende passiert in einem Programm namens PowerShell. Das ist das
schwarze oder blaue Fenster, in das du Befehle tippst.

1. Drücke die **Windows-Taste**.
2. Tippe `PowerShell`.
3. Klicke auf **Windows PowerShell**.

Es öffnet sich ein Fenster mit einem blinkenden Cursor. Hier hinein kommen
alle Befehle dieser Anleitung.

> [!TIP]
> Du musst nichts abtippen. Kopiere jeden Befehl aus dieser Anleitung mit
> `Strg`+`C` und füge ihn im PowerShell-Fenster mit einem **Rechtsklick** ein.
> Dann `Enter` drücken. Rechtsklick statt `Strg`+`V` ist hier normal.

## Schritt 2: Drei Programme installieren

Kopiere diesen Befehl ins Fenster und drücke `Enter`:

```powershell
winget install Python.Python.3.13 Gyan.FFmpeg Git.Git
```

Das lädt drei Hilfsprogramme aus dem Microsoft-Store-Katalog:

- **Python** — die Sprache, in der die Trennungssoftware geschrieben ist
- **ffmpeg** — wandelt Tonformate ineinander um
- **Git** — holt dieses Projekt aus dem Internet

Das dauert ein paar Minuten. Es rauscht dabei viel Text durch — das ist normal.

Wenn es fertig ist: **Schliesse das PowerShell-Fenster und öffne es neu.**
Sonst findet Windows die frisch installierten Programme noch nicht. Dieser
Schritt wird oft vergessen und ist die häufigste Ursache für Fehler danach.

## Schritt 3: Das Projekt herunterladen

```powershell
cd $HOME
git clone https://github.com/muraschal/audio-extraction.git
cd audio-extraction
```

Drei Befehle, einer nach dem anderen. Sie bedeuten der Reihe nach: geh in
deinen Benutzerordner, hole das Projekt, geh hinein.

Ab jetzt gilt: **Das PowerShell-Fenster muss in diesem Ordner stehen.** Links
vor dem Cursor sollte `audio-extraction` zu sehen sein. Wenn du das Fenster
zwischendurch schliesst, tippe beim nächsten Mal zuerst wieder
`cd $HOME\audio-extraction`.

## Schritt 4: Die Einrichtung starten

```powershell
.\scripts\setup.ps1
```

Das ist der lange Teil. Es lädt rund 3 Gigabyte herunter — hauptsächlich die
Software, die deine Grafikkarte zum Rechnen bringt. Je nach Internetverbindung
dauert das 10 bis 30 Minuten. Lass das Fenster offen und mach etwas anderes.

Am Ende steht dort so etwas:

```
== Prüfung ==
  torch      2.11.0+cu128
  CUDA       ja - NVIDIA GeForce RTX 5080
  capability (12, 0)
```

> [!IMPORTANT]
> Achte auf die Zeile **CUDA**. Steht dort `ja`, rechnet deine Grafikkarte mit
> und ein Song dauert Sekunden. Steht dort `nein (CPU-Betrieb)`, funktioniert
> alles trotzdem — nur eben viel langsamer. Das ist kein Fehler, nur langsam.

Diesen Schritt machst du **einmal**. Nie wieder.

## Schritt 5: Einen Song holen

Such dir den Song auf YouTube und kopiere die Adresse aus der Adresszeile des
Browsers. Dann:

```powershell
.\scripts\fetch.ps1 -Url "HIER-DIE-ADRESSE-EINFÜGEN" -Name "song"
```

Die Anführungszeichen müssen stehen bleiben, die Adresse kommt dazwischen. Also
zum Beispiel:

```powershell
.\scripts\fetch.ps1 -Url "https://youtu.be/dQw4w9WgXcQ" -Name "song"
```

Du siehst danach den Titel, die Länge und die Tonqualität. Die Datei liegt
jetzt als `song.wav` im Unterordner `input`.

> [!NOTE]
> Wenn du den Song als gekaufte Datei besitzt — etwa von Bandcamp oder als CD —
> ist die **deutlich besser** als YouTube. Kopiere sie einfach in den Ordner
> `input` und überspring diesen Schritt. YouTube-Ton ist zusammengepresst, und
> was dabei verloren ging, holt keine Software zurück.

## Schritt 6: Den Gesang entfernen

```powershell
.\scripts\separate.ps1 -Path ".\input\song.wav"
```

Beim allerersten Mal lädt es noch ein Modell herunter, rund 300 Megabyte. Danach
geht es sofort los.

Am Ende siehst du zwei Dateien aufgelistet:

```
Name                   MB
----                   --
song_instrument.wav 51.59
song_vocals.wav     51.59
```

- `song_instrument.wav` — **das ist dein Instrumental**
- `song_vocals.wav` — nur der Gesang

## Schritt 7: Anhören

```powershell
explorer .\output\bs_roformer_voc_hyperacev2
```

Das öffnet den Ordner im normalen Windows-Explorer. Doppelklick auf die Datei,
und sie spielt ab.

Fertig. Ab hier brauchst du für jeden weiteren Song nur noch Schritt 5 und 6.

## Wenn etwas nicht klappt

### „Die Benennung ... wurde nicht als Name eines Cmdlet erkannt"

Windows findet das Programm nicht. Zwei Ursachen:

- **Du hast das Fenster nach der Installation nicht neu geöffnet.** Schliess es
  und öffne PowerShell neu.
- **Du stehst im falschen Ordner.** Tippe `cd $HOME\audio-extraction` und
  versuch es nochmal.

### „Die Datei kann nicht geladen werden, da das Ausführen von Skripts auf diesem System deaktiviert ist"

Windows blockiert selbstgeschriebene Skripte standardmässig. Einmalig
erlauben:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

Bestätige mit `J`. Das gilt nur für dein Benutzerkonto und ist die von
Microsoft vorgesehene Einstellung für genau diesen Fall.

### Bei CUDA steht „nein"

Das ist kein Fehler. Die Trennung läuft dann auf dem Hauptprozessor statt auf
der Grafikkarte — statt Sekunden dauert ein Song einige Minuten. Wenn du eine
NVIDIA-Karte hast und trotzdem `nein` dort steht, hilft meist ein aktueller
Grafiktreiber von nvidia.com.

### Im Instrumental hört man die Stimme noch leise

Das kommt vor, besonders bei Hall und langen Endsilben. Probier ein anderes
Modell:

```powershell
.\scripts\separate.ps1 -Path ".\input\song.wav" -Model model_bs_roformer_ep_317_sdr_12.9755
```

Das Ergebnis landet in einem eigenen Ordner, das erste bleibt erhalten. Hör
beide an und behalte das bessere.

Hilft das nicht, liegt es oft am Hall. Dagegen gibt es ein eigenes Modell —
siehe [Wenn Hallreste bleiben](../README.md#wenn-hallreste-bleiben).

### Die Musik klingt dünn oder blechern

Dann hat die Trennung zu viel weggenommen. Meist liegt es an der Quelle:
YouTube-Ton ist bereits zusammengepresst, und die Software verstärkt diese
Schwäche. Eine gekaufte Datei als Ausgangspunkt bringt hier mehr als jedes
andere Modell.

### Der Download bricht ab

YouTube ändert regelmässig etwas, was das Download-Werkzeug aus dem Tritt
bringt. Meist hilft eine neuere Fassung:

```powershell
.\.venv\Scripts\python.exe -m pip install --upgrade yt-dlp
```

## Ein paar Begriffe

**Stem** — eine einzelne Spur aus einem Song, etwa nur der Gesang oder nur das
Schlagzeug. Der Song wird also in seine Bestandteile zerlegt.

**Instrumental** — der Song ohne Gesang.

**Modell** — die trainierte Software, die entscheidet, was Gesang ist und was
nicht. Es gibt viele davon, und sie sind unterschiedlich gut. Deshalb lohnt
sich das Ausprobieren.

**WAV und FLAC** — Tonformate ohne Qualitätsverlust. Grosse Dateien, dafür
verlustfrei.

**MP3, AAC und Opus** — zusammengepresste Tonformate. Kleine Dateien, dafür
geht Klanginformation verloren. YouTube liefert Opus.

**CUDA** — die Technik, mit der NVIDIA-Grafikkarten rechnen statt nur Bilder
anzuzeigen. Sie macht die Trennung ungefähr fünfzigmal schneller.

**PowerShell** — das Fenster, in das du die Befehle tippst.

## Darfst du das?

Für dich privat, zum Üben oder zum Anhören im Familien- und Freundeskreis: ja,
das erlaubt das Schweizer Urheberrecht.

Was du **nicht** ohne Erlaubnis darfst: die bearbeitete Fassung ins Internet
stellen, weitergeben, öffentlich aufführen oder damit Geld verdienen. Das
gehört den Rechteinhabern des Originals.
