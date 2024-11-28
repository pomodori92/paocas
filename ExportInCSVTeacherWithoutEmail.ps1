param (
    [string[]]$OUNames = @('Docenti'),
    [string]$OutputPath = $PSScriptRoot,
    [int]$RetentionDays = 30
)

# Funzione: Scrivere nel log con livelli di severità
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    $logMessage | Out-File -FilePath $logPath -Append
}

# Funzione: Verificare la directory di output
function Ensure-Directory {
    param ([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -ItemType Directory | Out-Null
    }
}

# Funzione: Pulizia dei file obsoleti
function Clean-OldFiles {
    param ([string]$Path, [int]$Days)
    Get-ChildItem -Path $Path -Recurse | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$Days) } | Remove-Item -Force -ErrorAction SilentlyContinue
}

# Funzione: Report finale
function Generate-Report {
    param ([int]$TotalUsers, [string]$CsvPath)
    Write-Log "Utenti trovati: $TotalUsers" -Level "INFO"
    Write-Log "Report salvato in: $CsvPath" -Level "INFO"
}

# Script principale
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logPath = Join-Path -Path $OutputPath -ChildPath "script_log_$timestamp.txt"
Ensure-Directory -Path $OutputPath
Clean-OldFiles -Path $OutputPath -Days $RetentionDays
Write-Log "Inizio script"

foreach ($OUName in $OUNames) {
    try {
        $ou = (Get-ADOrganizationalUnit -Filter {Name -eq $OUName} -Properties DistinguishedName).DistinguishedName
        if (-not $ou) {
            Write-Log "L'OU '$OUName' non è stata trovata." -Level "WARNING"
            continue
        }

        $csvPath = Join-Path -Path $OutputPath -ChildPath "utenti_senza_email_${OUName}_$timestamp.csv"
        $utentiSenzaEmail = Get-ADUser -Filter {EmailAddress -eq $null} -SearchBase $ou -Properties SamAccountName, Name, LastLogonDate |
            Select-Object SamAccountName, Name, @{Name='UltimoLogin';Expression={if ($_.LastLogonDate) { [DateTime]::FromFileTime($_.LastLogonDate) } else { 'Mai' }}}

        $utentiSenzaEmail | Export-Csv -Path $csvPath -NoTypeInformation
        Generate-Report -TotalUsers $utentiSenzaEmail.Count -CsvPath $csvPath
    } catch {
        Write-Log "Errore durante l'esecuzione per OU '$OUName': $_" -Level "ERROR"
    }
}

Write-Log "Fine script"
