CREATE TABLE aircraft (
    aircraft_id INTEGER PRIMARY KEY,
    tail_num VARCHAR(10) NOT NULL UNIQUE,

    CHECK (aircraft_id > 0)
);