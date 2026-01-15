# postgis_loader

Ferramenta pessoal para carga rápida de dados geoespaciais (Shapefile) em banco PostgreSQL com PostGIS.

O objetivo deste projeto é facilitar o upload de shapefiles para o banco de dados, reutilizando um único comando, sem precisar escrever SQL ou configurar conexão manualmente toda vez.

---

## O que essa ferramenta faz

- Carrega Shapefiles diretamente para o PostGIS
- Usa GDAL (`ogr2ogr`) para máxima performance
- Lê credenciais de banco a partir de um `.env` central
- Permite definir schema e nome da tabela no comando
- Cria índice espacial automaticamente (GiST)
- Funciona com banco remoto (nuvem)
- Não versiona dados (apenas código)

---

## Requisitos

- PostgreSQL com PostGIS
- GDAL / ogr2ogr (instalado via QGIS)
- PowerShell (Windows)
- Acesso ao banco de dados (local ou nuvem)