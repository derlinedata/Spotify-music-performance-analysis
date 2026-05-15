-- =========================================
-- LIMPEZA E TRATAMENTO DA BASE EMPRESA
-- =========================================
CREATE OR REPLACE TABLE `projeto-1-modulo-dados.Projeto_1Rota_B.Base_Empresa_Limpa` AS

-- =========================================
-- 1️⃣ Limpar, padronizar e tratar a base da empresa
-- =========================================
WITH base_tratada AS (
  SELECT *
  FROM (
    SELECT
      track_id,
      track_name,

      -- Limpeza do nome
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

      --Segmentação por número de artistas que participam da música (para análise e visualização)
      CASE
        WHEN artist_count = 1 THEN 'Solo'
        WHEN artist_count = 2 THEN 'Dupla'
        ELSE 'Colaboração (3+)'
      END AS tipo_colaboracao,

      -- Tratamento de gênero (padronização + missing)
      CASE
        WHEN main_music_genre IS NULL OR TRIM(main_music_genre) = '' THEN 'Unknown'
        WHEN LOWER(TRIM(main_music_genre)) IN ('disco pop', 'disco-pop') THEN 'Disco pop'
        ELSE TRIM(main_music_genre)
      END AS main_music_genre_tratado,

      -- Tratamento de país (padronização)
      CASE
        WHEN main_country IS NULL OR TRIM(main_country) = '' THEN 'Unknown'
        WHEN LOWER(TRIM(main_country)) = 'mx' THEN 'Mexico'
        WHEN LOWER(TRIM(main_country)) = 'pr' THEN 'Puerto Rico'
        WHEN LOWER(TRIM(main_country)) = 'usa' THEN 'United States'
        ELSE TRIM(main_country)
      END AS main_country_tratado,

      released_year,
      released_month,
      released_day,

      -- Segmentação por período de lançamento (para análise e visualização)
      CASE
        WHEN released_year <= 1999 THEN 'Até 1999'
        WHEN released_year <= 2009 THEN '2000–2009'
        WHEN released_year <= 2015 THEN '2010–2015'
        WHEN released_year <= 2019 THEN '2016–2019'
        ELSE '2020 em diante'
      END AS faixa_lancamento,

      -- Corrige valores inválidos (texto → número)
      IFNULL(SAFE_CAST(in_spotify_playlists AS INT64), 0) AS in_spotify_playlists,
      IFNULL(in_spotify_charts, 0) AS in_spotify_charts,

      -- Remove valores inválidos (0 ou valores negativos) de streams
      CASE 
        WHEN streams IS NULL OR streams <= 0 THEN NULL
        ELSE streams
      END AS streams_tratado,

      -- Deduplicação (mantém a versão com mais streams)
      ROW_NUMBER() OVER (
        PARTITION BY track_id
        ORDER BY 
      CASE 
       WHEN streams IS NULL OR streams <= 0 THEN NULL
       ELSE streams
     END DESC,
     in_spotify_playlists DESC
      ) AS rn

    FROM `projeto-1-modulo-dados.Projeto_1Rota_B.Base_Empresa_`
  )
  WHERE rn = 1
),

-- =========================================
-- 2️⃣ MÉTRICAS DO NEGOCIO
-- =========================================
Base_ComMetrica AS (
  SELECT
    *,

    -- Log
    CASE 
      WHEN streams_tratado IS NULL THEN NULL
      ELSE LOG(streams_tratado)
    END AS log_streams,

    -- Faixa de performance (streams)
    CASE
      WHEN streams_tratado IS NULL THEN 'Sem dados'
      WHEN streams_tratado < 100000000 THEN 'Baixo (até 100M)'
      WHEN streams_tratado < 300000000 THEN 'Médio (100M–300M)'
      WHEN streams_tratado < 700000000 THEN 'Alto (300M–700M)'
      ELSE 'Hit (700M+)'
    END AS faixa_streams,

    -- Métricas de negócio
    SAFE_DIVIDE(streams_tratado, in_spotify_playlists) AS streams_por_playlist,
    SAFE_DIVIDE(in_spotify_charts, in_spotify_playlists) AS taxa_charts,
    (in_spotify_playlists + in_spotify_charts) AS presenca_spotify

  FROM base_tratada
)

-- =========================================
-- RESULTADO FINAL
-- =========================================
SELECT * FROM Base_ComMetrica;       
-- =========================================
-- LIMPEZA E TRATAMENTO DA BASE CONCORRENTE
-- =========================================
CREATE OR REPLACE TABLE `projeto-1-modulo-dados.Projeto_1Rota_B.Base_Conconrrente_Limpa` AS

-- =========================================
-- 1️⃣ Limpeza + padronização
-- =========================================
WITH base_Ctratada AS (
  SELECT *
  FROM (
    SELECT
      SAFE_CAST(track_id AS INT64) AS track_id,

      -- Apple
      IFNULL(SAFE_CAST(in_apple_playlists AS INT64), 0) AS in_apple_playlists,
      IFNULL(SAFE_CAST(in_apple_charts AS INT64), 0) AS in_apple_charts,

      -- Deezer
      IFNULL(SAFE_CAST(in_deezer_playlists AS INT64), 0) AS in_deezer_playlists,
      IFNULL(SAFE_CAST(in_deezer_charts AS INT64), 0) AS in_deezer_charts,

      -- Shazam
      IFNULL(SAFE_CAST(in_shazam_charts AS INT64), 0) AS in_shazam_charts,

      -- Deduplicação
      ROW_NUMBER() OVER (
        PARTITION BY SAFE_CAST(track_id AS INT64)
        ORDER BY 
          SAFE_CAST(in_apple_playlists AS INT64) DESC,
          SAFE_CAST(in_deezer_playlists AS INT64) DESC
      ) AS rn

    FROM `projeto-1-modulo-dados.Projeto_1Rota_B.Base_Conconrrente_`
    WHERE SAFE_CAST(track_id AS INT64) IS NOT NULL
  )
  WHERE rn = 1
),

-- =========================================
-- 2️⃣ Métricas de negócio (multi-plataforma)
-- =========================================
base_Cfinal AS (
  SELECT
    *,

    -- Presença total fora do Spotify
    (in_apple_playlists + in_deezer_playlists) AS playlists_total_outros,

    -- Força em charts
    (in_apple_charts + in_deezer_charts + in_shazam_charts) AS charts_total_outros,

    -- Score geral de presença
    (
      in_apple_playlists +
      in_deezer_playlists +
      in_apple_charts +
      in_deezer_charts +
      in_shazam_charts
    ) AS presenca_total_outros

  FROM base_Ctratada
)

SELECT * FROM base_Cfinal;
-- =========================================
-- JUNÇÃO DAS DUAS BASES
-- =========================================
--Juntando as duas tabelas
CREATE OR REPLACE TABLE `projeto-1-modulo-dados.Projeto_1Rota_B.Base_Final` AS

SELECT
  e.*,

  -- Dados concorrentes
  c.in_apple_playlists,
  c.in_apple_charts,
  c.in_deezer_playlists,
  c.in_deezer_charts,
  c.in_shazam_charts,

  -- Métricas agregadas concorrentes
  c.playlists_total_outros,
  c.charts_total_outros,
  c.presenca_total_outros,

  -- 🔥 MÉTRICA MASTER (com proteção contra NULL)
  (e.presenca_spotify + IFNULL(c.presenca_total_outros, 0)) AS presenca_total_global

FROM `projeto-1-modulo-dados.Projeto_1Rota_B.Base_Empresa_Limpa` e

LEFT JOIN `projeto-1-modulo-dados.Projeto_1Rota_B.Base_Conconrrente_Limpa` c
ON e.track_id = c.track_id;

-- =========================================
-- MODELAGEM FINAL PARA ANÁLISE
-- =========================================
CREATE OR REPLACE TABLE `projeto-1-modulo-dados.Projeto_1Rota_B.BaseFinal_Analise` AS

SELECT
  *,

  -- 🎯 Total de playlists (todas plataformas)
  (
    IFNULL(in_spotify_playlists, 0) +
    IFNULL(in_apple_playlists, 0) +
    IFNULL(in_deezer_playlists, 0)
  ) AS total_playlists,

  -- 📊 Total de charts (todas plataformas)
  (
    IFNULL(in_spotify_charts, 0) +
    IFNULL(in_apple_charts, 0) +
    IFNULL(in_deezer_charts, 0) +
    IFNULL(in_shazam_charts, 0)
  ) AS total_charts

FROM `projeto-1-modulo-dados.Projeto_1Rota_B.BaseFinal`;
