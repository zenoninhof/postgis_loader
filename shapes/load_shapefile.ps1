param (
    [Parameter(Mandatory = $true)]
    [string]$Shapefile,

    [Parameter(Mandatory = $true)]
    [string]$Table,

    [string]$Schema = "public",
    [string]$Srid = ""
)

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
& "C:\Program Files\QGIS 3.40.1\bin\ogr2ogr.exe" `
    -f "PostgreSQL" `
    $pgConn `
    $Shapefile `
    -nln "$Schema.$Table" `
# -----------------------------
# As vezes o ogr buga e identifica multipolygon como polygon ai não sobe a planilha
# se isso acontecer só forçar como multipolygon  usanto a linha de baixo.
# -----------------------------

 #   -nlt MULTIPOLYGON `
    -lco SPATIAL_INDEX=GIST `
    -overwrite `
    -progress `
    @sridArg


