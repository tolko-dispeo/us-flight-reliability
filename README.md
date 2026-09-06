# US Flight Reliability Analytics

Учебный проект по проектированию аналитической базы данных
для анализа внутренних авиарейсов США.

## Стек

- Python
- PostgreSQL
- Docker
- Apache Superset
- GitLab CI
- Git

Данные взяты отсюда: Bureau of Transportation Statistics — Reporting Carrier On-Time Performance.
Официальная страница:
https://www.transtats.bts.gov/DL_SelectFields.aspx?QO_fu146_anzr=&gnoyr_VQ=FGJ

Исходная выгрузка находится в:
data/raw/T_ONTIME_REPORTING_20260904_140925.zip

### Используемые поля исходного набора данных
- OP_CARRIER_AIRLINE_ID
- TAIL_NUM
- FL_DATE
- OP_CARRIER_FL_NUM
- ORIGIN_AIRPORT_ID
- ORIGIN_CITY_NAME
- ORIGIN_STATE_ABR
- DEST_AIRPORT_ID
- DEST_CITY_NAME
- DEST_STATE_ABR
- CANCELLED
- CANCELLATION_CODE
- DIVERTED
- AIR_TIME
- DISTANCE
- CRS_DEP_TIME
- DEP_TIME
- DEP_DELAY
- TAXI_OUT
- TAXI_IN
- CRS_ARR_TIME
- ARR_TIME
- ARR_DELAY
- CARRIER_DELAY
- WEATHER_DELAY
- NAS_DELAY
- SECURITY_DELAY
- LATE_AIRCRAFT_DELAY


Структура
docs/                  модели и пояснения
notebooks/             исследование данных
scripts/ddl/            создание таблиц
scripts/indexes/        индексы
scripts/procedures/     процедуры
scripts/queries/        SQL-запросы
scripts/views/          представления
src/flight_etl/         ETL

--- Запуск ---
Создать `.env` на основе `.env.example`.

если у вас Windows:
    powershell
    python -m venv .venv
    .\.venv\Scripts\Activate.ps1
    pip install -r requirements.txt
    .\scripts\init_project.ps1

если macOS / Linux:
    python3 -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt
    chmod +x scripts/init_project.sh
    ./scripts/init_project.sh