CREATE TABLE flight (
    flight_id INTEGER PRIMARY KEY,

    airline_id INTEGER NOT NULL,
    aircraft_id INTEGER,

    fl_date DATE NOT NULL,
    op_carrier_fl_num INTEGER NOT NULL,

    origin_airport_id BIGINT NOT NULL,
    dest_airport_id BIGINT NOT NULL,

    cancelled BOOLEAN NOT NULL,
    cancellation_code CHAR(1),

    diverted BOOLEAN NOT NULL,

    air_time INTEGER,
    distance INTEGER NOT NULL,

    crs_dep_time TIME NOT NULL,
    dep_time TIME,
    dep_delay INTEGER,
    taxi_out INTEGER,
    taxi_in INTEGER,

    crs_arr_time TIME NOT NULL,
    arr_time TIME,
    arr_delay INTEGER,

    FOREIGN KEY (airline_id)
        REFERENCES airline(airline_id),

    FOREIGN KEY (aircraft_id)
        REFERENCES aircraft(aircraft_id),

    FOREIGN KEY (origin_airport_id)
        REFERENCES airport(airport_id),

    FOREIGN KEY (dest_airport_id)
        REFERENCES airport(airport_id),

    UNIQUE (
        fl_date,
        airline_id,
        op_carrier_fl_num,
        origin_airport_id
    ),

    CHECK (op_carrier_fl_num > 0),
    CHECK (distance > 0),
    CHECK (air_time >= 0),
    CHECK (taxi_out >= 0),
    CHECK (taxi_in >= 0),

    CHECK (
        cancellation_code IS NULL
        OR cancellation_code IN ('A', 'B', 'C', 'D')
    ),

    CHECK (
        (cancelled = TRUE AND cancellation_code IS NOT NULL)
        OR
        (cancelled = FALSE AND cancellation_code IS NULL)
    )
);