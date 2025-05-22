# Verifica se si sta eseguendo come amministratore.
$taskName = "SpegnimentoAutomatico"
$scriptPath = $MyInvocation.MyCommand.Path
Write-Host $scriptPath

$adminCheck = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $adminCheck) {
    Write-Host "Riavvio lo script come amministratore."
    
    # Ottiene il percorso dello script corrente.
	Write-Host $scriptPath
	
    # Rilancia lo script con privilegi di amministratore.
    Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
    exit
}

# Sezione eseguita con privilegi di amministratore.
Write-Host "Esecuzione con privilegi di amministratore."

# Importa l'attività pianificata dal file XML.
try {
	$xml = [xml](Get-Content $scriptPath -Raw)
	Register-ScheduledTask -TaskName $taskName -Xml $xml.OuterXml -Force
    Write-Host "Attività '$taskName' importata con successo."
} catch {
    Write-Error "Errore durante l'importazione: $_"
}

Start-Sleep -Seconds 10