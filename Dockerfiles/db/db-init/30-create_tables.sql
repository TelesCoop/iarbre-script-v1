-- ------------------------
--        POSTGIS
-- ------------------------

CREATE EXTENSION IF NOT EXISTS postgis;

-- ------------------------
--        POSTGIS
-- ------------------------

CREATE ROLE adm;

-- ------------------------
--         SCHEMA 
-- ------------------------

DROP SCHEMA IF EXISTS base CASCADE;

CREATE SCHEMA base AUTHORIZATION adm;
-- AUTHORIZATION adm;

-- ------------------------
--         TABLES 
-- ------------------------

CREATE TABLE base.tiles (
	id serial PRIMARY KEY,
	geom_poly geometry(POLYGON) NOT NULL,
	insee int NULL,
	indice real NULL DEFAULT 0
);

CREATE TABLE base.factors (
	id serial PRIMARY KEY,
	"name" character varying(100) NULL,
	ponderation smallint NULL
);

CREATE TABLE base.metadatas (
	id serial PRIMARY KEY,
	"name" character varying(100) NOT NULL,
	date_produceur timestamp without time zone NULL,
	date_integration timestamp without time zone NULL,
	"version" character varying(100) NULL,
	"type" character varying(100) NULL,
	quality character varying(100) NULL,
	source_url character varying(255) NULL,
	source_name character varying(255) NULL,
	temp_file_path character varying(255) NULL,
	script_path character varying(255)[] NULL,
	factors_list int[] NULL
);

CREATE TABLE base.datas (
	id serial PRIMARY KEY,
	geom_poly geometry(POLYGON) NOT NULL,
	custom_field1 character varying(100) NULL,
	custom_field2 character varying(100) NULL,
	id_metadata INT NOT NULL,
	id_factor INT NOT NULL,
	FOREIGN KEY (id_metadata)
		REFERENCES base.metadatas (id) MATCH SIMPLE
		ON UPDATE NO ACTION
		ON DELETE NO ACTION,
	FOREIGN KEY (id_factor)
		REFERENCES base.factors (id) MATCH SIMPLE
		ON UPDATE NO ACTION
		ON DELETE NO ACTION
);

CREATE TABLE base.communes (
	id serial PRIMARY KEY,
	libelle character varying(255) NULL,
	insee int NULL,
	geom_poly geometry(POLYGON) NOT NULL
);

CREATE TABLE base.users (
	id serial PRIMARY KEY,
	firstname character varying(255) NULL,
	lastname character varying(255) NULL,
	email character varying(255) NOT NULL,
	passwd character varying(255) NOT NULL,
	user_role character varying(50) NOT NULL
);

CREATE TABLE base.history (
	id serial PRIMARY KEY,
	search_name character varying(255) NOT NULL,
	search_location character varying(255) NULL,
	id_user INT NOT NULL,
	FOREIGN KEY (id_user)
		REFERENCES base.users (id) MATCH SIMPLE
		ON UPDATE NO ACTION
		ON DELETE NO ACTION
);

-- ------------------------
--     TABLES LIAISON
-- ------------------------

CREATE TABLE base.tiles_factors (
	id serial PRIMARY KEY,
	id_tile INT NOT NULL,
	id_factor INT NOT NULL,
	area smallint NULL,
	FOREIGN KEY (id_tile)
		REFERENCES base.tiles (id) MATCH SIMPLE
		ON UPDATE NO ACTION
		ON DELETE NO ACTION,
	FOREIGN KEY (id_factor)
		REFERENCES base.factors (id) MATCH SIMPLE
		ON UPDATE NO ACTION
		ON DELETE NO ACTION
);

-- --------------------------------
--     TABLES AVANCEMENT CALCUL
-- --------------------------------
CREATE TABLE base.tiles_progress (
	insee int4 NOT NULL,
	CONSTRAINT tiles_progress_pk PRIMARY KEY (insee)
);

CREATE TABLE base.factors_progress (
	insee int4 NOT NULL,
	id_factor int4 NOT NULL,
	CONSTRAINT factors_progress_pk PRIMARY KEY (insee,id_factor)
);

-- ------------------------
--         INDEX
-- ------------------------

CREATE INDEX CONCURRENTLY tiles_geom_index ON base.tiles USING GIST (geom_poly);
CREATE INDEX CONCURRENTLY datas_geom_index ON base.datas USING GIST (geom_poly);

CREATE INDEX tiles_insee ON base.tiles USING btree (insee);
CREATE INDEX tiles_factors_id_factor ON base.tiles_factors USING btree (id_factor);
CREATE INDEX tiles_factors_id_tiles ON base.tiles_factors USING btree (id_tile);