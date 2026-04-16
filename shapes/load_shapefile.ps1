param (
    [Parameter(Mandatory = $true)]
    [string]$Shapefile,

    [Parameter(Mandatory = $true)]
    [string]$Table,

    [string]$Schema,

    [string]$Srid = ""
)

# -----------------------------
# Input manual do schema (Opção 2)
# -----------------------------
if (-not $Schema) {
    $Schema = Read-Host "Informe o schema de destino"
}

Write-Host "Destino: $Schema.$Table"

# -----------------------------
# Carregar variáveis do .env
# -----------------------------
$envPath = "C:\Users\zeno.filho\projetos\python_secrets_lib\.env"

if (-Not (Test-Path $envPath)) {
    Write-Error ".env não encontrado em $envPath"
    exit 1
}

Get-Content $envPath | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
        [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
    }
}

# -----------------------------
# Montar string de conexão
# -----------------------------
$pgConn = "PG:host=$Env:DB_HOST port=$Env:DB_PORT dbname=$Env:DB_NAME user=$Env:DB_USER password=$Env:DB_PASSWORD"

# -----------------------------
# SRID (opcional)
# -----------------------------
$sridArg = @()
if ($Srid -ne "") {
    $sridArg = @("-a_srs", "EPSG:$Srid")
}

# -----------------------------
# Executar ogr2ogr
# -----------------------------
$ogrArgs = @(
    "-f", "PostgreSQL",
    "-nlt", "PROMOTE_TO_MULTI",
    "-lco", "SPATIAL_INDEX=GIST",
    "-lco", "GEOMETRY_NAME=geom",
    "-overwrite",
    "-progress",
    "-nln", "$Schema.$Table",
    $pgConn,
    $Shapefile
) + $sridArg

& "C:\Program Files\QGIS 3.44.6\bin\ogr2ogr.exe" @ogrArgs