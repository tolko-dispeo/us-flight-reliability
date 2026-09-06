CREATE TABLE delay_reason (
    delay_reason_id INTEGER PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,

    CHECK (delay_reason_id > 0)
);