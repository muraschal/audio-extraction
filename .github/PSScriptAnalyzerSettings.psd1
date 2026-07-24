@{
    Severity = @('Error', 'Warning')

    ExcludeRules = @(
        # Die Skripte hier sind interaktive Kommandozeilenwerkzeuge, keine
        # Bausteine fuer eine Pipeline. Ihre Konsolenausgabe ist das Ergebnis
        # und nicht ein Nebenprodukt: farbige Abschnitte, Fortschritt und
        # Messtabellen sollen auf dem Bildschirm landen und nicht im
        # Ausgabestrom, wo sie eine Weiterverarbeitung stoeren wuerden.
        # Write-Output waere hier die falsche Wahl, nicht die richtige.
        'PSAvoidUsingWriteHost'
    )
}
