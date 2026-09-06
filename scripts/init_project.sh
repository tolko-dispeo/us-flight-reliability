#!/usr/bin/env bash

set -e

RESET=false

if [ "$1" = "--reset" ]; then
    RESET=true
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"


apply_sql_folder() {
    folder="$1"

    for file in "$folder"/*.sql; do
        [ -e "$file" ] || continue

        echo "Applying $(basename "$file")..."

        docker compose exec -T postgres sh -c \
            'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"' \
            < "$file"
    done
}


if [ "$RESET" = true ]; then
    echo "Removing old database volume..."

    docker compose down -v
fi


echo "Starting PostgreSQL..."

docker compose up -d postgres


echo "Waiting for PostgreSQL..."

database_ready=false

for i in $(seq 1 30); do
    if docker compose exec -T postgres sh -c \
        'pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"' \
        > /dev/null 2>&1; then

        database_ready=true
        break
    fi

    sleep 2
done


if [ "$database_ready" = false ]; then
    echo "PostgreSQL did not become ready"
    exit 1
fi


echo "Applying procedures..."

apply_sql_folder "$PROJECT_ROOT/scripts/procedures"


echo "Running ETL..."

if [ -x "$PROJECT_ROOT/.venv/bin/python" ]; then
    "$PROJECT_ROOT/.venv/bin/python" \
        "$PROJECT_ROOT/src/flight_etl/data_load_script.py"
else
    python3 "$PROJECT_ROOT/src/flight_etl/data_load_script.py"
fi


echo "Applying indexes..."

apply_sql_folder "$PROJECT_ROOT/scripts/indexes"


echo "Applying views..."

apply_sql_folder "$PROJECT_ROOT/scripts/views"


echo "Database initialization completed successfully."