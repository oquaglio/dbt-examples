#

Welcome to your new dbt project!

### Using the starter project

Try running the following commands:
- dbt run
- dbt test


### Resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](https://community.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices


## Setup

### Set up Python

Set Python ver (once off):
```sh
uv python pin 3.13.5
```

### Set up Venv

Create and activate venv:
```sh
uv venv
source .venv/bin/activate
```

Install dbt in venv (DON'T DO THIS, see below):
```sh
uv pip install dbt-mysql
```
UPDATE: better to use:
```sh
uv init --bare                      # creates pyproject.toml only
uv add "dbt-core~=1.7.0" "dbt-mysql==1.7.0"
```
Then use uv run dbt <cmd>, or activate the environment with source .venv/bin/activate. This beats uv pip install because the versions are recorded in pyproject.toml and uv.lock, so the setup can be reproduced.

Verify dbt:
```sh
dbt --version
 ```

### Set up the dbt Project (Once off)

Create dbt project:
```sh
dbt init
dbt init --profiles-dir .
```
Select:
- dbt project: mysql_example
- db: mysql

This will:
- create mysql_example project
- create ~/.dbt/profiles.yml

### Set up MySQL

Start MySQL and phpMyAdmin using Docker Compose:
```sh
docker compose up -d
```

This starts:
- **MySQL 8.0** on `localhost:3306`
- **phpMyAdmin** on [http://localhost:8080](http://localhost:8080) (login with `root` / `mysecretpassword`)

Stop the services:
```sh
docker compose down
```

To also remove the persisted data volume:
```sh
docker compose down -v --remove-orphans
```

## Run the project

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
dbt docs serve --port 8081  # 8080 is taken by phpMyAdmin
```

Re-seed after CSV changes:
```sh
dbt seed --full-refresh
```

Run a specific model:
```sh
dbt run --models seed_model
```

Run all:
```sh
dbt seed && dbt run && dbt test && dbt compile
```

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
Installs `dbt-labs/dbt_utils` with `dbt deps`. No model uses it at the moment: `dbt_utils.generate_surrogate_key` generates `cast(... as TEXT)`, which MySQL rejects, so `orders_incremental` builds its `order_key` with plain `md5(cast(order_id as char))` instead.

### Hooks (`dbt_project.yml`)
`on-run-start` hook runs `CREATE DATABASE IF NOT EXISTS {{ target.schema }}` (`mysql_example_dev` in `profiles.yml`) before models are built.

### Docs (`data/docs/docs.md`)
Reusable `{% docs %}` blocks referenced in schema files with `{{ doc("order_status") }}`. View with `dbt docs serve --port 8081` (the default port, 8080, is taken by phpMyAdmin).

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


## Check data in MySQL

Connect to db:
```sh
docker exec -it dbt-mysql mysql -u root -p
```
Use password: mysecretpassword

```sql
USE mysql_example_dev;  -- the schema set in profiles.yml

SHOW TABLES;

DESCRIBE example_model;

SHOW FULL TABLES WHERE table_type = 'VIEW';

SELECT * FROM information_schema.tables WHERE table_schema = 'mysql_example_dev';

-- Check incremental model
SELECT * FROM orders_incremental;

-- Check snapshot history
SELECT * FROM orders_snapshot ORDER BY order_id, dbt_valid_from;
```

## Debugging

Check docker logs:
```sh
docker logs dbt-mysql
```


## Nuke

```sh
docker compose down -v && docker compose up -d && sleep 5 && dbt seed && dbt run
```
