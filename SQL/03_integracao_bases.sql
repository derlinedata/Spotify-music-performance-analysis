
-- ============================================================
-- INTEGRAÇÃO DAS BASES
-- ============================================================

CREATE OR REPLACE TABLE Base_Final AS

SELECT

    e.*,

    -- Dados das plataformas concorrentes

    c.in_apple_playlists,
    c.in_apple_charts,

    c.in_deezer_playlists,
    c.in_deezer_charts,

    c.in_shazam_charts

FROM Base_Empresa_Limpa e

LEFT JOIN Base_Concorrente_Limpa c

ON e.track_id = c.track_id;
