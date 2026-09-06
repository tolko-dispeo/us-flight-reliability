param(
    [switch]$Reset
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir

Set-Location $projectRoot


function Check-ExitCode {
    param(
        [string]$Message
    )

    if ($LASTEXITCODE -ne 0) {
        throw $Message
    }
}


function Apply-SqlFolder {
    param(
        [string]$Folder
    )

    $files = Get-ChildItem -Path $Folder -Filter "*.sql" |
        Sort-Object Name

    foreach ($file in $files) {
        Write-Host "Applying $($file.Name)..."

        Get-Content $file.FullName -Raw |
            docker compose exec -T postgres sh -c 'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"'

        Check-ExitCode "Failed to apply $($file.Name)"
    }
}


if ($Reset) {
    Write-Host "Removing old database volume..."

    docker compose down -v

    Check-ExitCode "Failed to reset Docker environment"
}


Write-Host "Starting PostgreSQL..."

docker compose up -d postgres

Check-ExitCode "Failed to start PostgreSQL"


Write-Host "Waiting for PostgreSQL..."

$databaseReady = $false

for ($i = 0; $i -lt 30; $i++) {

    docker compose exec -T postgres sh -c 'pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"' *> $null

    if ($LASTEXITCODE -eq 0) {
        $databaseReady = $true
        break
    }

    Start-Sleep -Seconds 2
}

if (-not $databaseReady) {
    throw "PostgreSQL did not become ready"
}


Write-Host "Applying procedures..."

Apply-SqlFolder "$projectRoot/scripts/procedures"


Write-Host "Running ETL..."

$venvPython = "$projectRoot/.venv/Scripts/python.exe"

if (Test-Path $venvPython) {
    & $venvPython "$projectRoot/src/flight_etl/data_load_script.py"
}
else {
    python "$projectRoot/src/flight_etl/data_load_script.py"
}

Check-ExitCode "ETL failed"


Write-Host "Applying indexes..."

Apply-SqlFolder "$projectRoot/scripts/indexes"


Write-Host "Applying views..."

Apply-SqlFolder "$projectRoot/scripts/views"


Write-Host "Database initialization completed successfully."