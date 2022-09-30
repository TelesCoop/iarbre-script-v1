SELECT count(*)
FROM base.tiles_factors tf
INNER JOIN base.tiles t ON tf.id_tile = t.id AND t.insee = '69387' 
WHERE id_factor = 1;