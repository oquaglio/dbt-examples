# postgres_example

A dbt example project running on PostgreSQL. It demonstrates sources, ephemeral and incremental models, snapshots, macros, packages, hooks, docs, tests, exposures, tags and analyses.

## Origin

This project is a port of [`../mysql_example`](../mysql_example) to PostgreSQL.

- **Copied from:** `mysql_example/` in this repo
- **Based on commit:** `6e76958e5344350810c6c4dc38f923803f89dd7f` (2026-11-11, "update")
- **Why:** the MySQL adapter (`dbt-mysql`) stopped at dbt 1.7, which is deprecated. `dbt-postgres` supports current dbt (1.12).

To see what has changed in `mysql_example` since the port:
```sh
git log 6e76958..HEAD -- mysql_example
```

### What changed in the port

| Area | mysql_example | postgres_example |
|---|---|---|
| Python packages (`pyproject.toml`) | `dbt-core~=1.7.0`, `dbt-mysql==1.7.0` | `dbt-core>=1.12.6`, `dbt-postgres>=1.11.0` |
| Database (`docker-compose.yml`) | MySQL 8.0 on 3306 + phpMyAdmin on 8080 | Postgres 17 on 5432 + pgAdmin on 5050 |
| Connection (`profiles.yml`) | `schema: mysql_example_dev` (in MySQL, schema = database) | `dbname: postgres_example`, `schema: dev` |
| Project name (`dbt_project.yml`) | `mysql_example` | `postgres_example` |
| `on-run-start` hook | `CREATE DATABASE IF NOT EXISTS {{ target.schema }}` | `CREATE SCHEMA IF NOT EXISTS {{ target.schema }}` |
| `order_key` in `orders_incremental` | `md5(cast(order_id as char))`, because `dbt_utils.generate_surrogate_key` fails on MySQL | `dbt_utils.generate_surrogate_key(['order_id'])`. The MySQL expression would be wrong here: Postgres treats `char` as `char(1)`, so it would hash only the first digit. |
| Property files (`schema.yml`) | `tests:` | `data_tests:` (renamed in dbt 1.8), with generic test arguments under `arguments:` (dbt 1.10+) |
| `dbt_utils` (`package-lock.yml`) | 1.3.3 | 1.4.1 |
| `dbt docs serve` | `--port 8081`, because phpMyAdmin uses 8080 | default port 8080 |

The models, seeds, snapshot, macros, tests, analyses and exposures are otherwise unchanged.

## Setup

### Set up Python

Set Python ver (once off):
```sh
uv python pin 3.13.5
```

### Install dbt

The dependencies are recorded in `pyproject.toml` and `uv.lock`:
```sh
uv sync
```

Then use `uv run dbt <cmd>`, or activate the environment with `source .venv/bin/activate` and use `dbt <cmd>`. The commands below assume the environment is activated.

This project was set up with:
```sh
uv init --bare
uv add dbt-core dbt-postgres
```

Verify dbt:
```sh
dbt --version
```

### Set up Postgres

Start Postgres and pgAdmin using Docker Compose:
```sh
docker compose up -d --wait
```

This starts:
- **Postgres 17** on `localhost:5432`, user `postgres` / `mysecretpassword`, with database `postgres_example`
- **pgAdmin** on [http://localhost:5050](http://localhost:5050). Login is disabled (desktop mode). To add the server, use host `postgres`, port `5432`, user `postgres` / `mysecretpassword`.

These ports don't clash with `mysql_example`, so both projects can run at the same time.

Stop the services:
```sh
docker compose down
```

To also remove the persisted data volume:
```sh
docker compose down -v --remove-orphans
```

## Run the project

The profile is in this directory, so either pass `--profiles-dir .` to every command or set it once:
```sh
export DBT_PROFILES_DIR=.
```

Verify connection:
```sh
dbt debug
```

Install packages (dbt_utils):
```sh
dbt deps
```

Load seed data:
```sh
dbt seed
```

Run all models:
```sh
dbt run
```

Run snapshots (SCD Type 2):
```sh
dbt snapshot
```

Run tests:
```sh
dbt test
```

Generate and serve docs:
```sh
dbt docs generate
dbt docs serve
```
If `mysql_example`'s phpMyAdmin is running, it uses port 8080. In that case add `--port 8081`.

Re-seed after CSV changes:
```sh
dbt seed --full-refresh
```

Run a specific model:
```sh
dbt run --select seed_model
```

Run everything (seeds, models, snapshots and tests, in dependency order):
```sh
dbt build
```

Check source freshness:
```sh
dbt source freshness
```
This reports `raw.raw_orders` as stale. That's expected: the seed data is from 2024 and the source errors after 48 hours.

## dbt Features Demonstrated

### Sources (`data/models/staging/sources.yml`)
Declares raw tables as sources with `{{ source('raw', 'raw_orders') }}`. Includes freshness checks (`dbt source freshness`).

### Ephemeral Models (`data/models/staging/stg_orders.sql`)
`materialized='ephemeral'` — compiled as a CTE, no database object created. Used for lightweight staging transformations.

### Incremental Models (`data/models/marts/orders_incremental.sql`)
`materialized='incremental'` — only processes new/updated rows on subsequent runs using `{% if is_incremental() %}`.

### Snapshots (`data/snapshots/orders_snapshot.sql`)
SCD Type 2 tracking on `raw_orders` using `strategy='timestamp'`. Records historical changes with `dbt_valid_from` / `dbt_valid_to` columns. When an order's `updated_at` changes, the old version is closed and a new one is inserted. Current rows have `dbt_valid_to = NULL`. Not run by `dbt run`: use `dbt snapshot` or `dbt build`. Descriptions and tests are in `data/snapshots/schema.yml`.

See [docs/snapshots.md](docs/snapshots.md) for a walkthrough, example queries and gotchas.

### Custom Macros (`data/macros/cents_to_dollars.sql`)
Reusable Jinja macro that converts cents to dollars: `{{ cents_to_dollars('amount_cents') }}`.

### Packages (`packages.yml`)
Uses `dbt-labs/dbt_utils` for `generate_surrogate_key` in the incremental model. Install with `dbt deps`.

### Hooks (`dbt_project.yml`)
`on-run-start` hook runs `CREATE SCHEMA IF NOT EXISTS {{ target.schema }}` (`dev` in `profiles.yml`) before models are built.

### Docs (`data/docs/docs.md`)
Reusable `{% docs %}` blocks referenced in schema files with `{{ doc("order_status") }}`. View with `dbt docs serve`.

### Custom Generic Test (`data/macros/test_is_positive.sql`)
Reusable test macro applied in schema.yml like built-in tests. Validates that column values are > 0. Applied to `total_orders` and `total_spent`.

### Singular Test (`data/tests/assert_no_orphan_orders.sql`)
A standalone SQL query that fails if it returns rows. Checks that every customer in `orders_incremental` has a matching entry in `customer_orders`.

### Exposures (`data/models/marts/exposures.yml`)
Declares downstream consumers (dashboards, reports). Shows up in the `dbt docs` lineage graph so you can see what depends on your models.

### Tags (`dbt_project.yml`)
Models are tagged by directory (`staging`, `daily`, `marts`). Run subsets with:
```sh
dbt run --select tag:daily
dbt run --select tag:staging
```

### Analyses (`data/analyses/order_analysis.sql`)
SQL that compiles but doesn't create a database object. Run `dbt compile` and check `target/compiled/` for the rendered SQL. Useful for ad-hoc queries.

### Directory-level Materialization (`dbt_project.yml`)
Different subdirectories have different default materializations:
- `staging/` → ephemeral
- `marts/` → incremental

A `{{ config(materialized=...) }}` in a model overrides the directory default. All three mart models do this, so only `orders_incremental` ends up incremental:

| Model | Materialization | Where it comes from |
|---|---|---|
| `stg_orders` | ephemeral | model config (same as the `staging/` default) |
| `customer_orders` | table | model config, overrides the `marts/` default |
| `completed_orders` | view | model config, overrides the `marts/` default |
| `orders_incremental` | incremental | model config (same as the `marts/` default) |


## Check data in Postgres

Connect to db:
```sh
docker exec -it dbt-postgres psql -U postgres -d postgres_example
```

```sql
SET search_path TO dev;  -- the schema set in profiles.yml

\dt                      -- list tables
\dv                      -- list views

\d example_model         -- describe a table

SELECT table_name, table_type FROM information_schema.tables WHERE table_schema = 'dev';

-- Check incremental model
SELECT * FROM orders_incremental;

-- Check snapshot history
SELECT * FROM orders_snapshot ORDER BY order_id, dbt_valid_from;
```

Quit with `\q`.

## Debugging

Check docker logs:
```sh
docker logs dbt-postgres
```


## Nuke

```sh
docker compose down -v && docker compose up -d --wait && dbt seed && dbt run
```
