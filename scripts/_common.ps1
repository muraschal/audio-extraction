<#
    Gemeinsame Hilfsfunktionen. Wird von den uebrigen Skripten per Dot-Sourcing
    eingebunden und ist nicht zum direkten Aufruf gedacht.
#>

function Invoke-Native {
    <#
    .SYNOPSIS
        Ruft ein externes Programm auf und wertet ausschliesslich den Exit-Code aus.

    .DESCRIPTION
        In Windows PowerShell 5.1 verpackt jede stderr-Zeile eines nativen
        Programms einen ErrorRecord, sobald der Ausgabestrom umgeleitet wird.
        Unter $ErrorActionPreference = 'Stop' bricht das Skript dadurch ab -
        auch dann, wenn das Programm sauber mit Exit-Code 0 endet.

        Das ist keine Randerscheinung, sondern der Normalfall: ffmpeg schreibt
        saemtliche Messwerte nach stderr, pymss die Fortschrittsanzeige,
        yt-dlp gelegentlich Warnungen. Alle drei wuerden das Skript ohne diese
        Behandlung mitten im Lauf abbrechen.

        Massgeblich fuer Erfolg oder Misserfolg ist deshalb allein
        $LASTEXITCODE.

    .PARAMETER FilePath
        Pfad zum aufzurufenden Programm.

    .PARAMETER Arguments
        Argumentliste.

    .PARAMETER Capture
        Gibt die zusammengefuehrte Ausgabe als Zeichenkettenfeld zurueck,
        statt sie auf die Konsole durchzureichen.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]   $FilePath,
        [string[]] $Arguments = @(),
        [switch]   $Capture
    )

    # Nur innerhalb dieser Funktion wirksam.
    $ErrorActionPreference = 'Continue'

    $output = $null
    if ($Capture) {
        $output = & $FilePath @Arguments 2>&1 | ForEach-Object { $_.ToString() }
    }
    else {
        # stderr wird bewusst in den Ausgabestrom umgeleitet und zu Text
        # gewandelt. Ohne diese Umwandlung reicht PowerShell die ErrorRecords
        # weiter, und beim Aufrufer erscheint gewoehnliche Fortschrittsausgabe
        # als 'NativeCommandError' - obwohl nichts fehlgeschlagen ist.
        & $FilePath @Arguments 2>&1 | ForEach-Object {
            if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.ToString() } else { $_ }
        }
    }

    if ($LASTEXITCODE -ne 0) {
        $name = [System.IO.Path]::GetFileName($FilePath)
        if ($Capture -and $output) {
            Write-Host ($output | Select-Object -Last 20 | Out-String) -ForegroundColor DarkGray
        }
        throw "$name endete mit Exit-Code $LASTEXITCODE."
    }

    return $output
}

function Assert-Tool {
    <#
    .SYNOPSIS
        Stellt sicher, dass ein Programm im PATH erreichbar ist.
    #>
    param(
        [Parameter(Mandatory)] [string] $Name,
        [string] $Hint
    )

    $found = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $found) {
        $message = "'$Name' wurde nicht gefunden."
        if ($Hint) { $message += " $Hint" }
        throw $message
    }
    return $found.Source
}
