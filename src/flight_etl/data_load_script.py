import os

from datetime import time
from io import StringIO
from pathlib import Path
from zipfile import ZipFile

import pandas as pd
import psycopg
from dotenv import load_dotenv


PROJECT_ROOT = Path(__file__).resolve().parents[2]
RAW_DIR = PROJECT_ROOT / "data" / "raw"

zip_files = list(RAW_DIR.glob("*.zip"))

if len(zip_files) != 1:
    raise RuntimeError(
        f"Expected exactly one ZIP file in {RAW_DIR}, found {len(zip_files)}"
    )

zip_path = zip_files[0]

with ZipFile(zip_path) as archive:
    csv_files = [
        name
        for name in archive.namelist()
        if name.lower().endswith(".csv")
    ]

    if len(csv_files) != 1:
        raise RuntimeError(
            f"Expected exactly one CSV file in ZIP, found {len(csv_files)}"
        )

    with archive.open(csv_files[0]) as csv_file:
        df = pd.read_csv(csv_file)


airlines_df = (
    df[["OP_CARRIER_AIRLINE_ID"]]
    .drop_duplicates()
    .sort_values("OP_CARRIER_AIRLINE_ID")
    .reset_index(drop=True)
)

airlines_df.insert(
    0,
    "airline_id",
    range(1, len(airlines_df) + 1)
)

airlines_df = airlines_df.rename(
    columns={
        "OP_CARRIER_AIRLINE_ID": "op_carrier_airline_id"
    }
)


origin_airports_df = df[
    [
        "ORIGIN_AIRPORT_ID",
        "ORIGIN_CITY_NAME",
        "ORIGIN_STATE_ABR"
    ]
].rename(
    columns={
        "ORIGIN_AIRPORT_ID": "airport_id",
        "ORIGIN_CITY_NAME": "city_name",
        "ORIGIN_STATE_ABR": "state_abr"
    }
)

dest_airports_df = df[
    [
        "DEST_AIRPORT_ID",
        "DEST_CITY_NAME",
        "DEST_STATE_ABR"
    ]
].rename(
    columns={
        "DEST_AIRPORT_ID": "airport_id",
        "DEST_CITY_NAME": "city_name",
        "DEST_STATE_ABR": "state_abr"
    }
)

airports_df = (
    pd.concat(
        [origin_airports_df, dest_airports_df],
        ignore_index=True
    )
    .drop_duplicates()
    .sort_values("airport_id")
    .reset_index(drop=True)
)

airports_df["city_name"] = (
    airports_df["city_name"]
    .str.replace(r", [A-Z]{2}$", "", regex=True)
)


aircraft_df = (
    df[["TAIL_NUM"]]
    .dropna()
    .drop_duplicates()
    .sort_values("TAIL_NUM")
    .reset_index(drop=True)
)

aircraft_df.insert(
    0,
    "aircraft_id",
    range(1, len(aircraft_df) + 1)
)

aircraft_df = aircraft_df.rename(
    columns={
        "TAIL_NUM": "tail_num"
    }
)


delay_reasons_df = pd.DataFrame(
    {
        "delay_reason_id": [1, 2, 3, 4, 5],
        "code": [
            "CARRIER",
            "WEATHER",
            "NAS",
            "SECURITY",
            "LATE_AIRCRAFT",
        ],
    }
)


flight_columns = [
    "OP_CARRIER_AIRLINE_ID",
    "TAIL_NUM",
    "FL_DATE",
    "OP_CARRIER_FL_NUM",
    "ORIGIN_AIRPORT_ID",
    "DEST_AIRPORT_ID",
    "CANCELLED",
    "CANCELLATION_CODE",
    "DIVERTED",
    "AIR_TIME",
    "DISTANCE",
    "CRS_DEP_TIME",
    "DEP_TIME",
    "DEP_DELAY",
    "TAXI_OUT",
    "TAXI_IN",
    "CRS_ARR_TIME",
    "ARR_TIME",
    "ARR_DELAY",
]

flights_df = df[flight_columns].copy()

flights_df.insert(
    0,
    "flight_id",
    range(1, len(flights_df) + 1)
)

flights_df = flights_df.merge(
    airlines_df,
    left_on="OP_CARRIER_AIRLINE_ID",
    right_on="op_carrier_airline_id",
    how="left",
    validate="many_to_one",
    sort=False,
)

flights_df = flights_df.merge(
    aircraft_df,
    left_on="TAIL_NUM",
    right_on="tail_num",
    how="left",
    validate="many_to_one",
    sort=False,
)

flights_df = flights_df.rename(
    columns={
        "FL_DATE": "fl_date",
        "OP_CARRIER_FL_NUM": "op_carrier_fl_num",
        "ORIGIN_AIRPORT_ID": "origin_airport_id",
        "DEST_AIRPORT_ID": "dest_airport_id",
        "CANCELLED": "cancelled",
        "CANCELLATION_CODE": "cancellation_code",
        "DIVERTED": "diverted",
        "AIR_TIME": "air_time",
        "DISTANCE": "distance",
        "CRS_DEP_TIME": "crs_dep_time",
        "DEP_TIME": "dep_time",
        "DEP_DELAY": "dep_delay",
        "TAXI_OUT": "taxi_out",
        "TAXI_IN": "taxi_in",
        "CRS_ARR_TIME": "crs_arr_time",
        "ARR_TIME": "arr_time",
        "ARR_DELAY": "arr_delay",
    }
)

flights_df = flights_df[
    [
        "flight_id",
        "airline_id",
        "aircraft_id",
        "fl_date",
        "op_carrier_fl_num",
        "origin_airport_id",
        "dest_airport_id",
        "cancelled",
        "cancellation_code",
        "diverted",
        "air_time",
        "distance",
        "crs_dep_time",
        "dep_time",
        "dep_delay",
        "taxi_out",
        "taxi_in",
        "crs_arr_time",
        "arr_time",
        "arr_delay",
    ]
]

flights_df["fl_date"] = pd.to_datetime(
    flights_df["fl_date"],
    format="%m/%d/%Y %I:%M:%S %p",
).dt.date

flights_df["cancelled"] = flights_df["cancelled"].astype(bool)
flights_df["diverted"] = flights_df["diverted"].astype(bool)

nullable_int_cols = [
    "aircraft_id",
    "air_time",
    "dep_delay",
    "taxi_out",
    "taxi_in",
    "arr_delay",
]

for col in nullable_int_cols:
    flights_df[col] = flights_df[col].astype("Int64")

required_int_cols = [
    "flight_id",
    "airline_id",
    "op_carrier_fl_num",
    "origin_airport_id",
    "dest_airport_id",
    "distance",
]

for col in required_int_cols:
    flights_df[col] = flights_df[col].astype("int64")


def hhmm_to_time(value):
    if pd.isna(value):
        return None

    value = int(value)

    if value == 2400:
        value = 0

    hours = value // 100
    minutes = value % 100

    return time(hours, minutes)


time_cols = [
    "crs_dep_time",
    "dep_time",
    "crs_arr_time",
    "arr_time",
]

for col in time_cols:
    flights_df[col] = flights_df[col].apply(hhmm_to_time)


delay_cols = [
    "CARRIER_DELAY",
    "WEATHER_DELAY",
    "NAS_DELAY",
    "SECURITY_DELAY",
    "LATE_AIRCRAFT_DELAY",
]

flight_delay_df = df[delay_cols].copy()

flight_delay_df.insert(
    0,
    "flight_id",
    flights_df["flight_id"].to_numpy()
)

flight_delay_df = flight_delay_df.melt(
    id_vars="flight_id",
    var_name="delay_type",
    value_name="delay_minutes",
)

flight_delay_df = flight_delay_df[
    flight_delay_df["delay_minutes"].notna()
    & (flight_delay_df["delay_minutes"] > 0)
].copy()

reason_map = {
    "CARRIER_DELAY": 1,
    "WEATHER_DELAY": 2,
    "NAS_DELAY": 3,
    "SECURITY_DELAY": 4,
    "LATE_AIRCRAFT_DELAY": 5,
}

flight_delay_df["delay_reason_id"] = (
    flight_delay_df["delay_type"]
    .map(reason_map)
    .astype("int64")
)

flight_delay_df["delay_minutes"] = (
    flight_delay_df["delay_minutes"]
    .astype("int64")
)

flight_delay_df = flight_delay_df[
    [
        "flight_id",
        "delay_reason_id",
        "delay_minutes",
    ]
]


def copy_dataframe(cur, dataframe, table_name):
    buffer = StringIO()

    dataframe.to_csv(
        buffer,
        index=False,
        header=False,
        na_rep=""
    )

    buffer.seek(0)

    columns = ", ".join(dataframe.columns)

    copy_query = (
        f"COPY {table_name} ({columns}) "
        "FROM STDIN WITH (FORMAT CSV, NULL '')"
    )

    with cur.copy(copy_query) as copy:
        copy.write(buffer.getvalue())


load_dotenv()

with psycopg.connect(
    dbname=os.getenv("POSTGRES_DB"),
    user=os.getenv("POSTGRES_USER"),
    password=os.getenv("POSTGRES_PASSWORD"),
    host="127.0.0.1",
    port=int(os.getenv("POSTGRES_PORT")),
) as conn:
    with conn.cursor() as cur:
        cur.execute("TRUNCATE TABLE airline CASCADE;")

        copy_dataframe(
            cur,
            airlines_df,
            "airline"
        )

        cur.execute("TRUNCATE TABLE airport CASCADE;")

        copy_dataframe(
            cur,
            airports_df,
            "airport"
        )

        cur.execute("TRUNCATE TABLE aircraft CASCADE;")

        copy_dataframe(
            cur,
            aircraft_df,
            "aircraft"
        )

        cur.execute("TRUNCATE TABLE delay_reason CASCADE;")

        copy_dataframe(
            cur,
            delay_reasons_df,
            "delay_reason"
        )

        cur.execute("TRUNCATE TABLE flight CASCADE;")

        copy_dataframe(
            cur,
            flights_df,
            "flight"
        )

        cur.execute("TRUNCATE TABLE flight_delay;")

        copy_dataframe(
            cur,
            flight_delay_df,
            "flight_delay"
        )
