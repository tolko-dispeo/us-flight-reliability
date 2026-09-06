CREATE TABLE flight_delay (
    flight_id INTEGER NOT NULL,
    delay_reason_id INTEGER NOT NULL,
    delay_minutes INTEGER NOT NULL,

    PRIMARY KEY (flight_id, delay_reason_id),

    FOREIGN KEY (flight_id)
        REFERENCES flight(flight_id),

    FOREIGN KEY (delay_reason_id)
        REFERENCES delay_reason(delay_reason_id),

    CHECK (delay_minutes > 0)
);