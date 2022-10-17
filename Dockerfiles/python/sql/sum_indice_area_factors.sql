SELECT id_tile, ROUND(SUM(area * f.ponderation)/100::numeric,1) AS sum_indice
FROM base.tiles_factors tf
JOIN base.factors f ON tf.id_factor = f.id
GROUP BY id_tile
LIMIT 100;