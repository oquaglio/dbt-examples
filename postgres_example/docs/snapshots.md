# Snapshots (`dbt snapshot`)

A snapshot keeps a history of how rows in a source table change over time. The source itself only ever holds the current version of each row. This pattern is called **SCD Type 2** (slowly changing dimension).

In this project, `orders_snapshot` tracks changes to `raw_orders`.

## The pieces involved

```
data/seeds/raw_orders.csv  ──dbt seed──▶  raw_orders table  ──dbt snapshot──▶  orders_snapshot
                                          (source 'raw')                        (keeps the history)
```

| File | Purpose |
|---|---|
| `data/snapshots/orders_snapshot.sql` | The snapshot definition |
| `data/snapshots/schema.yml` | Descriptions and tests for the snapshot (shown in `dbt docs serve`) |
| `data/models/staging/sources.yml` | Declares `raw_orders` as source `raw` |
| `data/seeds/raw_orders.csv` | The data loaded into `raw_orders` |

## Configuration

```sql
{% snapshot orders_snapshot %}
{{
    config(
        target_schema=target.schema,
        unique_key='order_id',
        strategy='timestamp',
        updated_at='updated_at'
    )
}}
select * from {{ source('raw', 'raw_orders') }}
{% endsnapshot %}
```

| Config | Meaning here |
|---|---|
| `unique_key='order_id'` | Each order is tracked by its `order_id`. |
| `strategy='timestamp'` | A row counts as changed when its timestamp column changes. |
| `updated_at='updated_at'` | That timestamp column is `updated_at` from the CSV. |
| `target_schema=target.schema` | The output goes into the same schema as the seeds and models: the `schema` set in `profiles.yml` (`dev`, inside the `postgres_example` database). |

## What happens when it runs

**First run:** dbt creates `orders_snapshot` as a copy of every row in `raw_orders` and adds 4 columns:

| Column | Meaning |
|---|---|
| `dbt_scd_id` | A hash that uniquely identifies each version of a row |
| `dbt_updated_at` | The `updated_at` value of that version |
| `dbt_valid_from` | When this version became current |
| `dbt_valid_to` | When this version was replaced. `NULL` means it's the current version |

**Later runs:** dbt compares each order's `updated_at` with the version it has stored:

- **New order:** it's inserted as a current row.
- **`updated_at` changed:** the old version is closed (`dbt_valid_to` is set) and the new version is inserted.
- **`updated_at` unchanged:** nothing happens.

### Example

Say Bob's order (id 2) goes from `pending` to `completed`. You change its line in the CSV to:

```
2,Bob,completed,3500,2024-01-02 11:00:00,2024-01-06 12:00:00
```

and run `dbt seed` followed by `dbt snapshot`. The snapshot now has two rows for order 2:

| order_id | status | dbt_valid_from | dbt_valid_to |
|---|---|---|---|
| 2 | pending | 2024-01-02 11:00 | 2024-01-06 12:00 |
| 2 | completed | 2024-01-06 12:00 | NULL |

dbt never deletes the old version. It closes it and inserts the new one.

## Why it matters

`dbt seed` reloads `raw_orders` from the CSV each time, so earlier values are overwritten. The snapshot table is the only place that remembers them.

### Useful queries

Run `SET search_path TO dev;` first (the schema set in `profiles.yml`), or prefix the table as `dev.orders_snapshot`.

Current version of each order:

```sql
select * from orders_snapshot
where dbt_valid_to is null;
```

What was true at a point in time (here, Jan 4):

```sql
select * from orders_snapshot
where '2024-01-04' >= dbt_valid_from
  and ('2024-01-04' < dbt_valid_to or dbt_valid_to is null);
```

Full history:

```sql
select * from orders_snapshot
order by order_id, dbt_valid_from;
```

## Gotchas

- **History is only captured when you run it.** If a row changes twice between two runs, only the second change is recorded. In a real pipeline, snapshots run on a schedule.
- **`updated_at` must change.** With the `timestamp` strategy, a row whose `status` changes while `updated_at` stays the same is ignored. To compare column values instead, use:
  ```sql
  strategy='check',
  check_cols=['status', 'amount_cents']
  ```
- **Deleted rows are not tracked by default.** If you remove a row from the CSV, its last version stays open (`dbt_valid_to` stays `NULL`). Adding `hard_deletes='invalidate'` to the config makes dbt close those rows. `hard_deletes='new_record'` also inserts a row marking the deletion, with `dbt_is_deleted = True`. (This replaced the older `invalidate_hard_deletes=True` in dbt 1.9.)
- **`dbt run` does not run snapshots.** Use `dbt snapshot` on its own, or `dbt build`, which runs seeds, models, snapshots and tests in dependency order.
- **Don't drop the snapshot table casually.** Unlike models, it can't be rebuilt from the source, because the history only exists in the snapshot. `docker compose down -v` (see "Nuke" in the README) wipes it.

## Try it

```sh
dbt seed
dbt snapshot        # first run: one row per order, all current
# change a row's status and updated_at in data/seeds/raw_orders.csv
dbt seed
dbt snapshot        # the changed order now has 2 versions
dbt test --select orders_snapshot
```

Then look at the result:

```sql
select * from orders_snapshot order by order_id, dbt_valid_from;
```
