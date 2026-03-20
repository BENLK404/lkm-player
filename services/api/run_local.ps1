# Charge token.env et lance le bot en local (Windows PowerShell)
$envFile = Join-Path $PSScriptRoot "token.env"
if (-not (Test-Path $envFile)) {
    Write-Host "Erreur: token.env introuvable. Créez-le à partir de token.env.example" -ForegroundColor Red
    exit 1
}
Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#") -and $line -match "^([^=]+)=(.*)$") {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        [Environment]::SetEnvironmentVariable($name, $value, "Process")
    }
}
Set-Location $PSScriptRoot
python main.py
