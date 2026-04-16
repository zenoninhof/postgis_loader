-- =====================================================
-- 1. GARANTIR GEOMETRIAS VÁLIDAS
-- =====================================================
UPDATE setores_ibge
SET geom = ST_MakeValid(geom)
WHERE NOT ST_IsValid(geom);

UPDATE zonas_modelo
SET geom = ST_MakeValid(geom)
WHERE NOT ST_IsValid(geom);

-- =====================================================
-- 2. CRIAR ÍNDICES ESPACIAIS (performance)
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_setores_geom
ON setores_ibge USING GIST (geom);

CREATE INDEX IF NOT EXISTS idx_zonas_geom
ON zonas_modelo USING GIST (geom);

-- =====================================================
-- 3. GARANTIR MESMO SRID
-- (ajuste conforme necessário)
-- =====================================================
-- Exemplo: transformar setores para SRID das zonas
-- (substitua 4674 se necessário)

UPDATE setores_ibge
SET geom = ST_Transform(geom, 4674)
WHERE ST_SRID(geom) <> 4674;

-- =====================================================
-- 4. CRIAR TABELA DE AGREGAÇÃO
-- =====================================================
DROP TABLE IF EXISTS zonas_agregadas;

CREATE TABLE zonas_agregadas AS
WITH intersec AS (
    SELECT
        z.id AS zona_id,
        s.id AS setor_id,
        s.populacao,

        -- área da interseção
        ST_Area(ST_Intersection(z.geom, s.geom)) AS area_intersec,

        -- área total do setor
        ST_Area(s.geom) AS area_setor

    FROM zonas_modelo z
    JOIN setores_ibge s
    ON ST_Intersects(z.geom, s.geom)
)

SELECT
    zona_id,

    -- agregação proporcional
    SUM(
        populacao * (area_intersec / NULLIF(area_setor, 0))
    ) AS populacao_ajustada

FROM intersec
GROUP BY zona_id;

-- =====================================================
-- 5. (OPCIONAL) ADICIONAR GEOMETRIA DAS ZONAS
-- =====================================================
ALTER TABLE zonas_agregadas ADD COLUMN geom geometry(MultiPolygon, 4674);

UPDATE zonas_agregadas za
SET geom = z.geom
FROM zonas_modelo z
WHERE za.zona_id = z.id;

-- =====================================================
-- 6. CRIAR ÍNDICE NA TABELA FINAL
-- =====================================================
CREATE INDEX idx_zonas_agregadas_geom
ON zonas_agregadas USING GIST (geom);

-- =====================================================
-- DESAGREGAÇÃO POR PESO (POPULAÇÃO)
-- =====================================================

DROP TABLE IF EXISTS setores_desagregados;

CREATE TABLE setores_desagregados AS
WITH base AS (
    SELECT
        s.id AS setor_id,
        m.id AS municipio_id,
        m.viagens_total,
        s.populacao,

        SUM(s.populacao) OVER (PARTITION BY m.id) AS pop_total_municipio

    FROM setores_ibge s
    JOIN municipios m
    ON ST_Intersects(s.geom, m.geom)
)

SELECT
    setor_id,
    municipio_id,

    SUM(
        viagens_total * (populacao / NULLIF(pop_total_municipio, 0))
    ) AS viagens_desagregadas

FROM base
GROUP BY setor_id, municipio_id;

-- =====================================================
-- 7. RESULTADO FINAL
-- =====================================================
SELECT * FROM zonas_agregadas;