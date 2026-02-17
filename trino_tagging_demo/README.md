# trino_tagging_demo

## Status

WIP

## TODO


## Setup

### Set up Python

Set Python ver and create venv:
```sh
uv python pin 3.13.5
```

Create and activate venv:
```sh
uv venv
source .venv/bin/activate
```

### Set up dbt project

Install dbt in venv:
```sh
uv pip install dbt-core dbt-trino
```

Verify dbt:
```sh
dbt --version
 ```

Create dbt project:
```sh
dbt init --profiles-dir .
```
Enter:
- dbt project: trino_tagging_demo
- db: trino

This will:
- create trino_tagging_demo project
- create/update ~/.dbt/profiles.yml and add trino_tagging_demo section with dev & prod targets

Project structure:

```sh
trino_tagging_demo/
├── dbt_project.yml
├── profiles.yml
├── models/
│   ├── schema.yml
│   └── customers.sql
├── seeds/
│   └── sample_customers.csv
├── docker-compose.yml
└── catalog/
    └── iceberg.properties
```

 ~/.dbt/profiles.yml or wherever (e.g. dbt project dir)

```yaml
trino_tagging_demo:
  target: dev
  outputs:
    dev:
      type: trino
      user: myminioadmin
      password: SuperSecureMinioPass2025!
      catalog: iceberg
      schema: demo
      host: localhost
      port: 8080
      method: none
      session_properties:
        query_max_run_time: 100m
```

## Start up MinIO and TrinoDB

TrinoDB: distributed SQL query engine
Minio: Object Store

```sh
# 1. Start MinIO
docker compose up -d
# or
docker compose down -v && docker compose up -d --force-recreate

# 2. Wait for it to be ready
sleep 20

# 3. Configure the MinIO client alias "local"
docker run --rm --network host \
  -v mc-config:/root/.mc \
  minio/mc alias set local http://localhost:9000 myminioadmin SuperSecureMinioPass2025!

# 4. Using the client alias "local", create the warehouse bucket "warehouse"
docker run --rm --network host \
  -v mc-config:/root/.mc \
  minio/mc mb local/warehouse --ignore-existing
```
It should give:
```sh
Bucket created successfully `local/warehouse`.
```

"alias set local" saves the alias called "local" inside the minio/mc image for re-use by the next command.
Actually, it's stored in a volume this container creates: docker volume ls | grep minio
It contains 1 file: /root/.mc/config.json

```sh
# Any time you want to poke at MinIO (list buckets, copy files, etc.)
docker run --rm --network host -v mc-config:/root/.mc minio/mc ls local
docker run --rm --network host -v mc-config:/root/.mc minio/mc du local
# etc.
```

Access minio dashboard:

http://localhost:9009

Access trino console:

http://localhost:8080/ui/
(login with admin)


### Cleanup

Remove everythign including ALL unused volumes, including any hidden MinIO junk.
```sh
docker compose down -v --remove-orphans
docker ps -a | grep minio | awk '{print $1}' | xargs -r docker rm -f
docker volume prune -f
```

## Run the dbt models

CD into the dbt project:
```sh
cd trino_tagging_demo
```

```sh
dbt debug
```
Conn tests whould work ok.

```sh
dbt deps
```

Run the seeds to create the sample_data table:
```sh
dbt seed
```

Run the models:
```sh
dbt run
```

```sh
dbt docs generate && dbt docs serve
```

## Connecto to Trino and Run Queries

See the tagging in action:
```sql
-- Connect to Trino at http://localhost:8080
-- These queries work exactly like Snowflake's tagging views

-- Table-level tags (set by our post-hook)
SELECT * FROM iceberg.system.table_properties
WHERE schema_name = 'demo' AND table_name = 'customers';

-- Column-level properties (set by our macro)
SELECT column_name, property_key, property_value
FROM iceberg.information_schema.column_properties
WHERE table_schema = 'demo' AND table_name = 'customers';
```

## Debugging

Check docker logs:

```sh
docker logs <container name>>
```
