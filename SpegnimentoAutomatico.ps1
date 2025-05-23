$taskName = "SpegnimentoAutomatico"

# Ottiene il percorso dello script corrente.
$scriptPath = $MyInvocation.MyCommand.Path

# Se il percorso dello script non è stato trovato, prova a ottenerlo da un altro metodo.
if (-not (Test-Path $scriptPath)) {
	$scriptPath = (Get-Item -Path ".\SpegnimentoAutomatico.ps1").FullName

	# Se ancora non è stato trovato, mostra un errore e termina lo script.
	if (-not $scriptPath) {
		Write-Error "Impossibile determinare il percorso dello script."
		Start-Sleep -Seconds 5
		exit
	}
}

$adminCheck = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

# Se non si è amministratori, rilancia lo script con privilegi elevati.
if (-not $adminCheck) {
	Write-Host "Riavvio lo script come amministratore."
	
	# Rilancia lo script con privilegi di amministratore.
	Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
	exit
}

# Sezione eseguita con privilegi di amministratore.
Write-Host "Esecuzione con privilegi di amministratore."

# Controlla se l'attività esiste già.
$taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($taskExists) {
	$overwrite = Read-Host "L'attività '$taskName' esiste già. Vuoi sovrascriverla? (S/N)"
	if ($overwrite -ne 'S' -and $overwrite -ne 's') {
		Write-Host "Operazione annullata."
		Start-Sleep -Seconds 5
		exit
	}
}

Write-Host "L'attività '$taskName' non esiste. Procedo con la creazione."

# Verifica se il file XML esiste.
$xmlPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "SpegnimentoAutomatico.xml"
if (-not (Test-Path $xmlPath)) {
	Write-Error "Il file XML non esiste: $xmlPath"
	Write-Host "Assicurati che il file XML sia presente nella stessa cartella dello script. Operazione annullata."
	Start-Sleep -Seconds 5
	exit
}

# Carica il file XML.
Write-Host "Percorso XML: $xmlPath"
$xml = [xml](Get-Content $xmlPath -Raw)
if (-not $xml) {
	Write-Error "Impossibile caricare il file XML: $xmlPath"
	Write-Host "Operazione annullata."
	Start-Sleep -Seconds 5
	exit
}

Write-Host "File XML caricato"
try {
	# Importa l'attività pianificata dal file XML.
	Register-ScheduledTask -TaskName $taskName -Xml $xml.OuterXml -Force

	# Verifica se l'attività è stata importata correttamente.
	if (-not $? -or $null -eq $xml.OuterXml -or $null -eq (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) -or $xml.OuterXml -eq "" -or $xml.OuterXml -eq "<ScheduledTask />" -or $xml.OuterXml -eq "<ScheduledTask></ScheduledTask>") {
		Raise-Event -MessageData "Errore durante l'importazione dell'attività '$taskName'." -ErrorAction Stop
		Start-Sleep -Seconds 5
	}
	Write-Host "Attività '$taskName' importata correttamente."
}
catch {
	Write-Error "Errore durante l'importazione: $_"
	Start-Sleep -Seconds 5
	exit
}
