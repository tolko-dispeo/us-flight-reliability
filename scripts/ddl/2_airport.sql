CREATE TABLE airport (
    airport_id BIGINT PRIMARY KEY,
    city_name VARCHAR(64) NOT NULL,
    state_abr CHAR(2) NOT NULL,

    CHECK (airport_id > 0)
);