## Was ändert sich

<!-- Ein bis drei Sätze. Was tut der Pull Request, und warum? -->

## Geprüft

<!--
Die CI prüft Syntax, Kodierung und Verweise. Was sie nicht prüfen kann, ist
ob die Skripte tatsächlich noch Audio trennen. Deshalb diese Liste.
-->

- [ ] `.\scripts\check-docs.ps1` läuft ohne Fehler durch
- [ ] Bei Änderungen an Skripten: einen echten Durchlauf gemacht
      (`fetch.ps1` → `separate.ps1` → `compare.ps1`)
- [ ] Bei geänderten Messwerten: Hardware und Befehl in `docs/messungen.md` genannt
- [ ] `CHANGELOG.md` ergänzt

## Anmerkungen

<!-- Offene Fragen, bewusste Auslassungen, alles was der Review kennen sollte. -->
