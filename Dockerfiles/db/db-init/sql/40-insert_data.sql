-- ------------------------
--     METROPOLE DATA
-- ------------------------

INSERT INTO base.factors
("name", ponderation)
VALUES
('Souches ou emplacements libres', 3),
('Arbres', 1),
('Parkings', -2),
('Signalisation tricolore et lumineuse matériel', -2),
('Station velov', -1),
('Arrêts transport en commun', -2),
('Proximité façade', -2),
('Bâtiments', -5),
('Friches', 2),
('Assainissement', -1),
('Parcs et jardins publics', 2),
('Giratoires', 2),
('Espaces jeux et pietonnier', 1),
('Friche naturelle', 3),
('Réseau Fibre', 2),
('Marchés forains', 1),
('Pistes cyclable', -1),
('Plan eau', -3),
('Ponts', -3),
('Réseau de chaleur urbain', -3),
('Voies ferrées', -2),
('Strate arborée', 1),
('Strate basse et pelouse', 3),
('Espaces agricoles', 1),
('Forêts', 1),
('Espaces artificialisés', -2),
('Tracé de métro', -2),
('Tracé de tramway', -2),
('Tracé de bus', -1),
('Rsx gaz', -3),
('Rsx souterrains ERDF', -1),
('Rsx aériens ERDF', -2);


INSERT INTO base.metadatas
("name", "version", "type", quality, source_url, source_name, temp_file_path, script_path, factors_list)
VALUES
('Arbres alignements Métropole', 'v1', 'POINT', 'Bonne', 'https://data.grandlyon.com/geoserver/metropole-de-lyon/ows', 'metropole-de-lyon:abr_arbres_alignement.abrarbre', NULL, '{arbre_souche.py, arbre.py}', '{1,2}'),
('Parkings surfacique', 'v1', 'POLYGON', 'Bonne', NULL, NULL, 'parkingsurfacique.geojson', NULL, '{3}'),
('SLT', 'v1', 'POINT', 'Bonne', NULL, NULL, 'sltmateriel.geojson', '{slt.py}', '{4}'),
('Stations velov', 'v1', 'POINT', 'Bonne', NULL, NULL, 'station_velov.geojson', '{velov.py}', '{5}'),
('Arrêts transport en commun', 'v1', 'POINT', 'Bonne', NULL, NULL, 'pt_arret_tcl.geojson', '{transport.py}', '{6}'),
('Batiments', 'v1', 'POLYGON', 'Bonne', NULL, NULL, 'batiments_geom.shp', '{batiment.py, facade.py}', '{8,7}'),
('Friches', 'v1', 'POLYGON', 'Bonne', NULL, NULL, 'cartofriches.geojson', NULL, '{9}'),
('Assainissement', 'v1', 'MULTILINESTRING', 'Bonne', NULL, NULL, 'assainissement.geojson', '{assainissement.py}', '{10}'),
('Espaces publics', 'v1', 'POLYGON', 'Bonne', NULL, NULL, 'espacepublic.geojson', '{parc.py, giratoire.py, jeux.py, friche_nat.py}', '{11,12,13,14}'),
('Réseau Fibre', 'v1', 'LINESTRING', 'Bonne', NULL, NULL, 'fibre.geojson', '{fibre.py}', '{15}'),
('Marchés forains', 'v1', 'POLYGON', 'Bonne', 'https://download.data.grandlyon.com/wfs/grandlyon', 'gin_nettoiement.ginmarche', NULL, NULL, '{16}'),
('Pistes cyclables', 'v1', 'LINESTRING', 'Bonne', NULL, NULL, 'pistes_cyclables.geojson', '{piste_cyclable.py}', '{17}'),
('Plan eau', 'v1', 'POLYGON', 'Bonne', NULL, NULL, 'plan_deau.geojson', '{plan_eau.py}', '{18}'),
('Ponts', 'v1', 'POLYGON', 'Bonne', NULL, NULL, 'pont.geojson', '{pont.py}', '{19}'),
('Réseau chaleur urbain', 'v1', 'LINESTRING', 'Bonne', NULL, NULL, 'rsx_chaleur.geojson', '{rsx_chaleur.py}', '{20}'),
('Voies ferrées', 'v1', 'LINESTRING', 'Bonne', 'https://download.data.grandlyon.com/wfs/grandlyon', 'fpc_fond_plan_communaut.fpcvoieferree', NULL, '{voie_ferree.py}', '{21}'),
('EVA 2015', 'v1', 'POLYGON', 'Bonne', NULL, NULL, 'new_all_eva.shp', '{strate_arboree.py, strate_basse.py, agricole.py, foret.py, arti.py}', '{22,23,24,25,26}'),
('Tracé de métro funiculaire', 'v1', 'LINESTRING', 'Bonne', NULL, NULL, 'lignemetro_funiculaire.geojson', '{metro_funiculaire.py}', '{27}'),
('Tracé de tramway', 'v1', 'LINESTRING', 'Bonne', NULL, NULL, 'lignetram.geojson', '{tram.py}', '{28}'),
('Tracé de bus', 'v1', 'LINESTRING', 'Bonne', NULL, NULL, 'lignebus.geojson', '{bus.py}', '{29}'),
('Réseaux gaz', 'v1', 'LINESTRING', 'Bonne', NULL, NULL, 'rsx_gaz.geojson', '{gaz.py}', '{30}'),
('Réseaux souterrains Enedis', 'v1', 'LINESTRING', 'Bonne', NULL, NULL, 'rsx_souterrain_enedis.geojson', '{souterrain_enedis.py}', '{31}'),
('Réseaux aériens Enedis', 'v1', 'LINESTRING', 'Bonne', NULL, NULL, 'rsx_aerien_enedis.geojson', '{aerien_enedis.py}', '{32}');

-- ------------------------
--    LOCAL USERS DATA
-- ------------------------

INSERT INTO base.users
(firstname, lastname, email, passwd, user_role)
VALUES
('Romain', 'MATIAS', 'r.matias@exo-dev.fr', '!PlAnT4-Gl!', 'ADMIN'),
('Natacha', 'SALMERON', 'n.salmeron@exo-dev.fr', '!PlAnT4-Gl!', 'ADMIN'),
('Younes', 'MHARRECH', 'younes.mharrech@cgi.com', '!PlAnT4-Gl!', 'ADMIN'),
('Pascal', 'GOUBIER', 'pgoubier@grandlyon.com', '!PlAnT4-Gl!', 'ADMIN'),
('Déborah', 'BESSON', 'debesson@grandlyon.com', '!PlAnT4-Gl!', 'ADMIN'),
('Hind', 'NAIT-BARKA', 'hnaitbarka@grandlyon.com', '!PlAnT4-Gl!', 'ADMIN'),
('Anaïs', 'HENRY', 'anhenry@grandlyon.com', '!PlAnT4-Gl!', 'ADMIN');

