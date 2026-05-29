-- ============================================================
-- LIMPEZA E TRATAMENTO DA BASE CONCORRENTE
-- ============================================================

CREATE OR REPLACE TABLE Base_Concorrente_Limpa AS

WITH base_Ctratada AS (

SELECT *
FROM (

SELECT

    SAFE_CAST(track_id AS INT64) AS track_id,

    -- Apple
    IFNULL(SAFE_CAST(in_apple_playlists AS INT64), 0)
        AS in_apple_playlists,

    IFNULL(SAFE_CAST(in_apple_charts AS INT64), 0)
        AS in_apple_charts,

    -- Deezer
    IFNULL(SAFE_CAST(in_deezer_playlists AS INT64), 0)
        AS in_deezer_playlists,

    IFNULL(SAFE_CAST(in_deezer_charts AS INT64), 0)
        AS in_deezer_charts,

    -- Shazam
    IFNULL(SAFE_CAST(in_shazam_charts AS INT64), 0)
        AS in_shazam_charts,

    -- Deduplicação
    ROW_NUMBER() OVER (
        PARTITION BY SAFE_CAST(track_id AS INT64)

        ORDER BY

        SAFE_CAST(in_apple_playlists AS INT64) DESC,
        SAFE_CAST(in_deezer_playlists AS INT64) DESC

    ) AS rn

FROM `Base_Concorrente`

WHERE SAFE_CAST(track_id AS INT64) IS NOT NULL

)

WHERE rn = 1

)

SELECT *
FROM base_Ctratada;
