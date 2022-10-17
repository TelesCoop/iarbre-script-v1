select * from (
SELECT id, ROW_NUMBER() OVER(PARTITION BY geom_poly ORDER BY id asc) AS Row,
geom_poly, insee FROM ONLY base.tiles
) dups where dups.Row > 1