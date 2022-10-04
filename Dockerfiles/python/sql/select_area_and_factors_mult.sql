SELECT id_tile, area, f.ponderation, (area * f.ponderation) as area_multiply
FROM base.tiles_factors tf
JOIN base.factors f ON tf.id_factor = f.id
ORDER BY id_tile;