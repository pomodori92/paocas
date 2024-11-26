param (
	[string]$basePath = "C:\Users",
	[string]$lastModifiedDate = "01/09/2024",
	[int]$Depth = 5
)

function Log-Message {
	param (
		[string]$Message,
		[string]$Level = "Info",
		[string]$Color = "White"
	)
	Write-Host "[$Level] $Message" -ForegroundColor $Color
}

function Validate-Date {
	param ([string]$DateString)
	try {
		return [datetime]::ParseExact($DateString, "dd/MM/yyyy", $null)
	} catch {
		Log-Message "Formato data non valido: $DateString" "Error" "Red"
		exit
	}
}

function Filter-Folders {
	param (
		[string]$Path,
		[datetime]$Date,
		[int]$Depth
	)
	Get-ChildItem -Path $Path -Directory -Recurse -Depth $Depth |
		Where-Object { $_.Name -match '^[^\.]+\.[^\.]+$' -and $_.LastWriteTime -lt $Date }
}

function Process-Folders {
	param (
		[array]$Folders,
		[bool]$DryRun
	)

	$totalFolders = 0
	$removedFolders = 0

	foreach ($folder in $Folders) {
		$totalFolders++
		if ($DryRun) {
			Log-Message "Cartella trovata (dry-run): $($folder.FullName)" "Info" "Cyan"
		} else {
			try {
				Remove-Item -Path $folder.FullName -Recurse -Force
				Log-Message "Cartella rimossa: $($folder.FullName)" "Info" "Green"
				$removedFolders++
			} catch {
				Log-Message "Errore nella rimozione: $($folder.FullName)" "Error" "Red"
			}
		}
	}

	return @{
		TotalFolders = $totalFolders
		RemovedFolders = $removedFolders
	}
}

# Main script
$DryRun = $false
while ($true) {
	Write-Host "Seleziona la modalità di esecuzione:"
	Write-Host "1 - Dry-run (simula senza rimuovere le cartelle)" -ForegroundColor Cyan
	Write-Host "2 - Normale (rimuove effettivamente le cartelle)" -ForegroundColor Green
	$choice = Read-Host "Inserisci 1 o 2"

	if ($choice -eq "1") {
		$DryRun = $true
		break
	} elseif ($choice -eq "2") {
		$DryRun = $false
		break
	} else {
		Log-Message "Errore: Opzione non valida. Riprova." "Error" "Red"
	}
}

if (-Not (Test-Path $basePath)) {
	Log-Message "Percorso non valido: $basePath" "Error" "Red"
	exit
}

$parsedLastModifiedDate = Validate-Date -DateString $lastModifiedDate
$folders = Filter-Folders -Path $basePath -Date $parsedLastModifiedDate -Depth $Depth

if ($folders.Count -eq 0) {
	Log-Message "Nessuna cartella trovata da elaborare." "Info" "Yellow"
	exit
}

$result = Process-Folders -Folders $folders -DryRun $DryRun
Log-Message "Totale cartelle trovate: $($result.TotalFolders)" "Info" "White"
if (-Not $DryRun) {
	Log-Message "Totale cartelle rimosse: $($result.RemovedFolders)" "Info" "Green"
}
