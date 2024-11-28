# Funzione per recuperare l'OU che contiene "Docenti"
function Get-DocentiOU {
    try {
        $OU = Get-ADOrganizationalUnit -Filter {Name -like "*Docenti*"} | Select-Object -First 1
        if ($OU) {
            return $OU
        } else {
            Write-Host "OU 'Docenti' non trovata!"
            return $null
        }
    } catch {
        Write-Host "Errore durante la ricerca dell'OU: $_"
        return $null
    }
}

# Funzione per ottenere gli utenti senza email
function Get-UsersWithoutEmail {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DistinguishedName
    )
    
    try {
        # Ottieni gli utenti senza email, selezionando solo le proprietà necessarie
        $users = Get-ADUser -Filter * -SearchBase $DistinguishedName -Properties mail -ErrorAction Stop
        
        # Verifica se l'attributo mail è nullo o vuoto
        $usersWithoutEmail = $users | Where-Object { -not $_.mail -or $_.mail -eq "" }
        return $usersWithoutEmail
    } catch {
        Write-Host "Errore durante l'ottenimento degli utenti: $_"
        return @()
    }
}

# Funzione per esportare i dati in CSV
function Export-ToCSV {
    param (
        [Parameter(Mandatory=$true)]
        [array]$data,
        [Parameter(Mandatory=$true)]
        [string]$outputPath
    )
    
    try {
        $data | Export-Csv -Path $outputPath -NoTypeInformation -ErrorAction Stop
        Write-Host "I risultati sono stati esportati in: $outputPath"
    } catch {
        Write-Host "Errore durante l'esportazione dei dati: $_"
    }
}

# Verifica se il modulo ActiveDirectory è disponibile
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Host "Modulo ActiveDirectory non trovato. Assicurati che sia installato."
    exit
}

# Main
$OU = Get-DocentiOU
if ($OU) {
    # Determina il percorso in cui si trova il file PowerShell
    $scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

    # Crea il percorso completo per il file CSV
    $outputFile = Join-Path -Path $scriptDirectory -ChildPath "Docenti_Senza_Email.csv"

    # Ottieni gli utenti senza email
    $usersWithoutEmail = Get-UsersWithoutEmail -DistinguishedName $OU.DistinguishedName

    # Esporta i risultati in CSV
    if ($usersWithoutEmail.Count -gt 0) {
        Export-ToCSV -data $usersWithoutEmail -outputPath $outputFile
    } else {
        Write-Host "Nessun utente senza email trovato."
    }

    # Debug: esporta tutti gli utenti con email vuota o nulla in un file CSV per il debug
    $allUsers = Get-ADUser -Filter * -SearchBase $OU.DistinguishedName -Properties mail
    $allUsers | Select-Object SamAccountName, Name, mail | Export-Csv -Path "$scriptDirectory\All_Users_Debug.csv" -NoTypeInformation
    Write-Host "Esportati tutti gli utenti in 'All_Users_Debug.csv' per il debug."
}
