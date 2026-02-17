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
uv pip install dbt-mysql
```

Verify dbt:
```sh
dbt --version
 ```

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

## Run the dbt models

```sh
dbt debug
```
Conn tests whould work ok.

Run the seeds to create the sample_data table:
```sh
dbt seed
```

Run the models:
```sh
dbt run
```

Update the seed:
```sh
dbt seed --full-refresh --target dev
```

Recreate the model based on the seed:
```sh
dbt run --models seed_model
```
(drops and re-creates the model)

Or, just dbt run.


## Check data in MySQL

Connect to db:
```sh
docker exec -it dbt-mysql mysql -u root -p
```
Use password: mysecretpassword


```sql
USE dbt_example;

SHOW TABLES;

DESCRIBE example_model;

SHOW FULL TABLES WHERE table_type = 'VIEW';

SELECT * FROM information_schema.tables WHERE table_schema = 'dbt_example';
```

## Debugging

Check docker logs:

```sh
docker logs dbt-mysql
```
