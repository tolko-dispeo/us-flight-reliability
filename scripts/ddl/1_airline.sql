CREATE TABLE airline (
    airline_id INTEGER PRIMARY KEY,
    op_carrier_airline_id INTEGER NOT NULL UNIQUE,

    CHECK (op_carrier_airline_id > 0)
);