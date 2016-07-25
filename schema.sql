DROP DATABASE pokemap;

CREATE DATABASE pokemap;
\connect pokemap;

CREATE TABLE pokemons (
  id BIGSERIAL NOT NULL,
  number INT NOT NULL,
  name TEXT,
  thumbnail_url TEXT
);
CREATE UNIQUE INDEX pokemons_pk ON pokemons (id);
ALTER TABLE pokemons ADD PRIMARY KEY USING INDEX pokemons_pk;
CREATE UNIQUE INDEX unique_pokemons ON pokemons (number);

CREATE TABLE pokemon_occurences (
  id BIGSERIAL NOT NULL,
  api_id BIGINT NOT NULL,
  expiration_time TIMESTAMP NOT NULL,
  pokemon_id BIGINT NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL
);
CREATE UNIQUE INDEX pokemon_occurencess_pk ON pokemon_occurences (id);
ALTER TABLE pokemon_occurences ADD PRIMARY KEY USING INDEX pokemon_occurencess_pk;
ALTER TABLE pokemon_occurences ADD CONSTRAINT pokemon_occurences_pokemons FOREIGN KEY (pokemon_id) REFERENCES pokemons(id);
CREATE UNIQUE INDEX unique_occurences ON pokemon_occurences (api_id, expiration_time);

