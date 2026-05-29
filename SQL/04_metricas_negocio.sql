-- ============================================================
-- CRIAÇÃO DAS MÉTRICAS DE NEGÓCIO
-- ============================================================

CREATE OR REPLACE TABLE BaseFinal_Analise AS

SELECT

    *,

    -- =====================================================
    -- MÉTRICAS SPOTIFY
    -- =====================================================

    CASE
        WHEN streams_tratado IS NULL THEN NULL
        ELSE LOG(streams_tratado)
    END AS log_streams,

    CASE
        WHEN streams_tratado IS NULL THEN 'Sem dados'
        WHEN streams_tratado < 100000000 THEN 'Baixo (até 100M)'
        WHEN streams_tratado < 300000000 THEN 'Médio (100M–300M)'
        WHEN streams_tratado < 700000000 THEN 'Alto (300M–700M)'
        ELSE 'Hit (700M+)'
    END AS faixa_streams,

    SAFE_DIVIDE(
        streams_tratado,
        in_spotify_playlists
    ) AS streams_por_playlist,

    SAFE_DIVIDE(
        in_spotify_charts,
        in_spotify_playlists
    ) AS taxa_charts,

    (
        in_spotify_playlists +
        in_spotify_charts
    ) AS presenca_spotify,

    -- =====================================================
    -- MÉTRICAS MULTIPLATAFORMA
    -- =====================================================

    (
        in_apple_playlists +
        in_deezer_playlists
    ) AS playlists_total_outros,

    (
        in_apple_charts +
        in_deezer_charts +
        in_shazam_charts
    ) AS charts_total_outros,

    (
        in_apple_playlists +
        in_deezer_playlists +
        in_apple_charts +
        in_deezer_charts +
        in_shazam_charts
    ) AS presenca_total_outros,

    -- =====================================================
    -- MÉTRICAS GLOBAIS
    -- =====================================================

    (
        (
            in_spotify_playlists +
            in_spotify_charts
        ) +

        IFNULL(
            (
                in_apple_playlists +
                in_deezer_playlists +
                in_apple_charts +
                in_deezer_charts +
                in_shazam_charts
            ),
            0
        )
    ) AS presenca_total_global,

    (
        IFNULL(in_spotify_playlists,0) +
        IFNULL(in_apple_playlists,0) +
        IFNULL(in_deezer_playlists,0)
    ) AS total_playlists,

    (
        IFNULL(in_spotify_charts,0) +
        IFNULL(in_apple_charts,0) +
        IFNULL(in_deezer_charts,0) +
        IFNULL(in_shazam_charts,0)
    ) AS total_charts

FROM Base_Final;
