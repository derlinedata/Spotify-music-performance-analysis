-- ============================================================
-- LIMPEZA E TRATAMENTO DA BASE EMPRESA
-- ============================================================

CREATE OR REPLACE TABLE Base_Empresa_Limpa AS

WITH base_tratada AS (

SELECT *
FROM (

SELECT

    track_id,
    track_name,

    -- Limpeza do nome da música
    TRIM(
        REGEXP_REPLACE(
            REGEXP_REPLACE(
                REGEXP_REPLACE(track_name, r"\(.*?\)", ""),
                r"\[.*?\]", ""
            ),
            r"-.*", ""
        )
    ) AS track_name_limpo,

    artists_name,
    artist_count,

    -- Segmentação por quantidade de artistas
    CASE
        WHEN artist_count = 1 THEN 'Solo'
        WHEN artist_count = 2 THEN 'Dupla'
        ELSE 'Colaboração (3+)'
    END AS tipo_colaboracao,

    -- Tratamento de gênero musical
    CASE
        WHEN main_music_genre IS NULL
             OR TRIM(main_music_genre) = ''
        THEN 'Unknown'

        WHEN LOWER(TRIM(main_music_genre))
             IN ('disco pop','disco-pop')
        THEN 'Disco pop'

        ELSE TRIM(main_music_genre)
    END AS main_music_genre_tratado,

    -- Tratamento de país
    CASE
        WHEN main_country IS NULL
             OR TRIM(main_country) = ''
        THEN 'Unknown'

        WHEN LOWER(TRIM(main_country)) = 'mx'
        THEN 'Mexico'

        WHEN LOWER(TRIM(main_country)) = 'pr'
        THEN 'Puerto Rico'

        WHEN LOWER(TRIM(main_country)) = 'usa'
        THEN 'United States'

        ELSE TRIM(main_country)
    END AS main_country_tratado,

    released_year,
    released_month,
    released_day,

    -- Faixa de lançamento
    CASE
        WHEN released_year <= 1999 THEN 'Até 1999'
        WHEN released_year <= 2009 THEN '2000–2009'
        WHEN released_year <= 2015 THEN '2010–2015'
        WHEN released_year <= 2019 THEN '2016–2019'
        ELSE '2020 em diante'
    END AS faixa_lancamento,

    -- Conversão de valores
    IFNULL(
        SAFE_CAST(in_spotify_playlists AS INT64),
        0
    ) AS in_spotify_playlists,

    IFNULL(in_spotify_charts, 0)
        AS in_spotify_charts,

    -- Tratamento de streams inválidos
    CASE
        WHEN streams IS NULL
             OR streams <= 0
        THEN NULL

        ELSE streams
    END AS streams_tratado,

    -- Deduplicação por track_id
    ROW_NUMBER() OVER (
        PARTITION BY track_id
        ORDER BY

        CASE
            WHEN streams IS NULL
                 OR streams <= 0
            THEN NULL
            ELSE streams
        END DESC,

        in_spotify_playlists DESC

    ) AS rn,

    -- Deduplicação adicional:
    -- Identificados registros repetidos para a mesma música e artista.
    -- Mantida apenas a observação com maior volume de streams.

    ROW_NUMBER() OVER (
        PARTITION BY
            LOWER(TRIM(track_name)),
            LOWER(TRIM(artists_name)),
            released_year
        ORDER BY streams DESC
    ) AS rn_musica
FROM `Base_Empresa`
  
)
  
WHERE rn = 1
AND rn_musica = 1

)
SELECT *
FROM base_tratada;  
