# Messungen

Alle Werte stammen aus einem realen Durchgang vom 24. Juli 2026 auf der unten
genannten Hardware. Es sind keine uebernommenen Herstellerangaben.

## Testaufbau

| | |
|---|---|
| GPU | NVIDIA GeForce RTX 5080, 16 GB, Compute Capability 12.0 (Blackwell) |
| Treiber | 610.62 |
| PyTorch | 2.11.0+cu128 |
| pymss | 2.0.14 |
| Quelle | Opus 48 kHz Stereo, 139,5 kbps, 2:33 — die beste Tonspur, die YouTube fuer dieses Video anbot |
| Zwischenformat | 24-Bit-WAV, 48 kHz, unveraendert abgetastet |

## Geschwindigkeit

Zwei Zahlen sind zu unterscheiden: die reine Verarbeitung und die Gesamtdauer
eines Aufrufs, in der das Laden des Modells in den Speicher steckt.

| Durchgang | Verarbeitung | RTF | gesamter Aufruf |
|---|---|---|---|
| `bs_roformer_voc_hyperacev2`, ohne TTA | 3,8 s | 0,02 | 8,8 s |
| `bs_roformer_voc_hyperacev2`, mit TTA | rund 12 s | 0,08 | — |
| `model_bs_roformer_ep_317_sdr_12.9755`, ohne TTA | — | — | 11,5 s |

RTF steht fuer Real Time Factor: 0,02 bedeutet, dass die Verarbeitung etwa den
fuenfzigsten Teil der Spieldauer benoetigt. Der Unterschied zwischen den beiden
Modellen in der Gesamtdauer geht ueberwiegend auf die Groesse zurueck — 289 MB
gegenueber 639 MB, die jedes Mal geladen werden wollen.

So oder so ist ein Modellwechsel praktisch kostenlos. Ausprobieren schlaegt
hier jede Vorabrecherche darueber, welches Modell das beste sein soll.

Nicht enthalten ist der einmalige Download der Modelle. Danach liegen sie unter
`~\.cache\pymss\models` und werden wiederverwendet.

## Pegel

| Signal | LUFS | RMS dB |
|---|---|---|
| Original | −9,8 | — |
| Instrumental (hyperacev2 +TTA) | −10,5 | −10,7 |
| Instrumental (hyperacev2, ohne TTA) | −10,5 | — |
| Instrumental (ep317 +TTA) | −10,5 | — |
| Gesangs-Stem (hyperacev2 +TTA) | — | −20,8 |

Dass alle drei Instrumentalversionen auf demselben Lautheitswert landen, ist
ein gutes Zeichen: kein Modell entfernt pauschal zu viel Signal.

## Die entscheidende Messung: Differenz-RMS

Zwei Versionen werden voneinander subtrahiert. Was uebrig bleibt, ist genau
das, worin sie sich unterscheiden.

| Vergleich | Differenz-RMS | unter Signalpegel |
|---|---|---|
| hyperacev2 mit vs. ohne TTA | −57,9 dB | rund 47 dB |
| hyperacev2 +TTA vs. ep317 +TTA | −37,0 dB | rund 26 dB |

### Was daraus folgt

**TTA lohnt sich auf diesem Material nicht.** Ein Unterschied 47 dB unter
Signalpegel ist beim Hoeren nicht auffindbar. Die dreifache Rechenzeit kauft
hier nichts. Das ist ein Messwert fuer dieses Stueck und diese Modelle, keine
allgemeine Aussage — bei sehr dichten Mischungen kann TTA mehr bewirken. Der
Test kostet zwoelf Sekunden, also miss lieber nach, statt es anzunehmen.

**Die Modellwahl wiegt schwerer, bleibt aber ueberschaubar.** 26 dB unter
Signalpegel ist beim konzentrierten Vergleich hoerbar, typischerweise an
Hallfahnen und Zischlauten. Deshalb schreibt `compare.ps1 -WriteDiff` das
Differenzsignal um 20 dB angehoben als Datei: darin hoerst du in wenigen
Sekunden, worueber die beiden Modelle uneins sind, statt den ganzen Song
zweimal durchzuhoeren.

## Einordnung gegenueber MVSep

MVSep weist auf seiner Algorithmen-Seite fuer den eigenen Multisong-Benchmark
folgende Werte aus (abgerufen am 24. Juli 2026):

| Modell | SDR Vocals | SDR Instrumental |
|---|---:|---:|
| BS Roformer 124 bands (ver. 2026.07) | 12,33 | 18,64 |
| Ensemble (2025.06) | 11,93 | 18,23 |
| BS Roformer (ver. 2025.07) | 11,89 | 18,20 |
| BS Roformer (ver. 2024.08) | 11,31 | 17,62 |

Zwei Einschraenkungen dazu. Erstens sind das MVSep-eigene Messungen auf einem
MVSep-eigenen Testsatz, kein unabhaengiger Vergleich. Zweitens ist das
124-Band-Modell auf dem Dienst exklusiv und steht lokal nicht zur Verfuegung;
die hier verwendeten offenen Checkpoints liegen einige Zehntel darunter.

Bemerkenswert ist, dass das einzelne aktuelle Modell das aeltere Ensemble
schlaegt. Ein Ensemble ist nicht automatisch die bessere Wahl, nur die
langsamere.

## Was die Messungen nicht abdecken

Bei einer verlustbehafteten Quelle wie hier ist die Materialqualitaet der
groessere Hebel als die Modellwahl. Der Abstand zwischen 140-kbps-Opus und
einer gekauften WAV faellt im Ergebnis staerker ins Gewicht als die 26 dB
zwischen zwei Modellen. Wer das Optimum will, faengt bei der Quelle an, nicht
beim Modell.
