#

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
```
Select:
- dbt project: mysql_example
- db: mysql

This will:
- create mysql_example project
- create ~/.dbt/profiles.yml

Set the following in the profiles.yml:
```sql
mysql_example:
  outputs:
    dev:
      type: mysql  # Use 'mysql' for MySQL 8.x (your container version); use 'mysql5' for 5.x or 'mariadb' for MariaDB
      server: localhost
      port: 3306
      schema: dbt_example  # This should be the name of the database you created in MySQL
      username: root
      password: mysecretpassword
      ssl_disabled: True  # Optional but recommended to disable TLS if not configured
  target: dev
```

### Set up MySQL

```sh
docker pull mysql:8.0
```

```sh
docker run --name dbt-mysql \
  -e MYSQL_ROOT_PASSWORD=mysecretpassword \
  -e MYSQL_DATABASE=dbt_example \
  -p 3306:3306 \
  -d mysql:8.0
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
dbt seed --full-refresh
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
