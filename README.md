# dbt Assignment: AirStats Capstone Project

Build a dbt project analyzing global airport data on Snowflake.

---

## Getting Started

1. Copy this repository by clicking the "Use Template" button
2. Explore the dataset: [DATASETS.md](DATASETS.md)
4. Get your repo running by going through one of these options:
   - **Use as a Codespace**: Click "Code" > "Codespaces" > "Create codespace on main"
   - **Clone locally**: Clone your fork, then run:
     ```bash
     uv sync
     source .venv/bin/activate # (or equivalent on your platform, see the README of the course)
     ```

---

## Part 1: Project Setup

### Step 1: Initialize the dbt Project

* Create a new dbt project called `airstats`. You only need to do the `dbt init ...` step, your uv/virtualenv is already up and running

### Step 2: Configure the Connection

Copy the `profiles.yml` from the `airbnb` project to the `airstats` folder:

Now edit `airstats/profiles.yml` and change the profile name to `airstats` and database name to `AIRSTATS`:

**Before (airbnb configuration):**
```yaml
airbnb:
  outputs:
    dev:
      type: snowflake
      account: "..."
      user: dbt
      role: TRANSFORM
      private_key: "..."
      private_key_passphrase: q
      database: AIRBNB
      schema: DEV
      threads: 1
      warehouse: COMPUTE_WH
  target: dev
```

**After (airstats configuration):**
```yaml
airstats:  # <-- CHANGED
  outputs:
    dev:
      type: snowflake
      account:  "..."
      user: dbt
      role: TRANSFORM
      private_key: "..."
      private_key_passphrase: q
      database: AIRSTATS # <-- CHANGED
      schema: DEV
      threads: 1
      warehouse: COMPUTE_WH
  target: dev
```

### Step 3: Verify the Connection

```sh
cd airstats
dbt debug
```

You should see "All checks passed!" if the connection is configured correctly.

Once done **Add `airstats` to git**, ensure that your `profiles.yml` is added too (this is OK as it's an assignment in a private repository; never add credentials to git in a real-world project)

### Step 4: Clean Up Example Files

Remove the example models that dbt created by default:

```sh
rm -rf models/example
```

Also remove the example model configuration from `dbt_project.yml`. Delete these lines at the end of the file:

```yaml
models:
  airstats:
    example:
      +materialized: view
```

_If you receive deprecation warnings when you execute dbt once you removed the example configuration, ignore these; it's a reported bug in dbt._

---

## Part 2: Data Exploration (Optional)

Before building models, explore the data in Snowflake. Here are a few SQL queries to get you started:

Data source: https://ourairports.com/data/

```sql
USE AIRSTATS.RAW;

-- Check the airports table
SELECT * FROM airports LIMIT 10;

-- Count airports by type
SELECT type, COUNT(*) as count
FROM airports
GROUP BY type
ORDER BY count DESC;

-- Check the runways table
SELECT * FROM runways LIMIT 10;

-- Check the comments table
SELECT * FROM airport_comments LIMIT 10;
```

---

## Part 3: General considerations

* In your SQL files, always use CTEs for "importing" refs/sources, even if it only adds boilerplate - this is dbt convention.
* Keep your warehouse clean. If you changed the name or materialization of a model, check if the one with the old name/materialization is still around and drop it in Snowflake (use `DROP VIEW` or `DROP TABLE` as appropriate). 

## Part 4: Define Sources

The AIRSTATS database has been set up in Snowflake with the following tables in the `RAW` schema:

| Table | Description | Key Columns |
|-------|-------------|-------------|
| `airports` | Global airport data (~72K rows) | `id`, `ident`, `type`, `name`, `iso_country` |
| `airport_comments` | User comments about airports | `id`, `airport_ref`, `airport_ident`, `date` |
| `runways` | Runway information (~44K rows) | `id`, `airport_ref`, `airport_ident`, `closed` |

### Exercise 1: Create the Sources File

Create a new file `models/sources.yml` that defines these three source tables. The `airport_comments` table must have the source name `comments`.

### Verify Your Sources

After creating the sources file, you can check for syntax errors by running:

```sh
dbt compile
```

---

## Part 5: Staging Models (bronze layer)

The staging layer (bronze) is responsible for:
- Selecting only the columns we need from source tables
- Renaming columns to follow consistent naming conventions
- Referencing sources using the dbt `source()` function

Create a folder `models/bronze/` for these models.

### Exercise 2: src_airports

Create `models/bronze/src_airports.sql`

**Requirements:**
1. Use a CTE to reference the `airports` source
2. Select and rename the following columns:

| Source Column Name | Target Column Name |
|---------------|---------------|
| `ident` | `airport_ident` |
| `type` | `airport_type` |
| `name` | `airport_name` |
| `latitude_deg` | `airport_lat` |
| `longitude_deg` | `airport_long` |
| `continent` | `continent` (no rename) |
| `iso_country` | `iso_country` (no rename) |
| `iso_region` | `iso_region` (no rename) |

### Exercise 3: src_airport_comments

Create `models/bronze/src_airport_comments.sql`

**Requirements:**
1. Use a CTE to reference the `airport_comments` source
2. Select and rename the following columns:

| Source Column Name | Target Column Name |
|---------------|---------------|
| `id` | `comment_id` |
| `airport_ident` | `airport_ident` (no rename) |
| `date` | `comment_timestamp` (it's actually a timestamp column, not a date column) |
| `member_nickname` | `member_nickname` (no rename) |
| `subject` | `comment_subject` |
| `body` | `comment_body` |

### Exercise 4: src_runways

Create `models/bronze/src_runways.sql`

**Requirements:**
1. Use a CTE to reference the `runways` source
2. Select and rename the following columns:

| Source Column Name | Target Column Name |
|---------------|---------------|
| `id` | `runway_id` |
| `airport_ident` | `airport_ident` (no rename) |
| `length_ft` | `runway_length_ft` |
| `width_ft` | `runway_width_ft` |
| `surface` | `runway_surface` |
| `lighted` | `runway_lighted` |
| `closed` | `runway_closed` |

### Verify Your Models

Run dbt to build the staging models:

```sh
dbt run
```

All three models should complete successfully.

## Part 6: Base Silver Tables

### Exercise 5: silver_airports
Create a `silver_airports` model: Just a copy (`SELECT *`) from src_airports, no transformations needed.

### Exercise 6: silver_runways
Create a `silver_runways` model:
* Source model: `src_runways`
* If the _surface_ is null or empty, change it to `__UNKNOWN__`; keep this column's name as `runway_surface`
* The columns of this model must be exactly the same (and in the same order) as those of `src_runways`

### Exercise 7: silver_airport_comments
Create a `silver_airport_comments` model:
* Source model: `src_airport_comments`
* Filter out records with null / empty values for the comment body
* If the member's nickname is null, change it to `__UNKNOWN__`
* Make this an incremental model that uses `comment_id` to identify new records (hint: compare against the maximum existing `comment_id` in the target table)
* Add a new column: `loaded_at`, which should be the `current_timestamp()` by default
* The columns of this model must be exactly the same (and in the same order) as those of `src_airport_comments`, plus the extra `loaded_at` as the last column

### Exercise 8: Update record
Add a new record to `RAW.airport_comments`. Then materialize the incremental model again (but only that model).

Add your solution in the next lines:
* Adding a new record:
  ```sql
  insert into airstats.raw.airport_comments
      (id, airport_ident, date, member_nickname, subject, body)
  values
      (602622, 'CA-0178', current_timestamp(), 'tu_nickname', 'Prueba incremental', 'Comentario de prueba para el ejercicio 8');

  insert into airstats.raw.airport_comments
      (id, airport_ident, date, member_nickname, subject, body)
  values
      (602623, 'CA-0179', current_timestamp(), 'esteban_lopez', 'Prueba incremental 2', 'Segundo comentario de prueba para el ejercicio 8');
  ```
* Command to execute to update this model (but only this model, not all the models):
  ```bash
  dbt run --select silver_airport_comments
  ```
  Result: `OK created sql incremental model DEV.silver_airport_comments [SUCCESS 2 in 3.73s]`
* Execute an SQL on the Snowflake UI to ensure the new record has been added:
  ```sql
  select comment_id, member_nickname, comment_body, loaded_at
  from airstats.dev.silver_airport_comments
  where comment_id > 602621
  order by comment_id;
  ```
  Result (2 rows):

  | COMMENT_ID | MEMBER_NICKNAME | COMMENT_BODY | LOADED_AT |
  |---|---|---|---|
  | 602622 | tu_nickname | Comentario de prueba para el ejercicio 8 | 2026-11-09 15:47:36.154 -0800 |
  | 602623 | esteban_lopez | Segundo comentario de prueba para el ejercicio 8 | 2026-11-09 15:47:36.154 -0800 |

**Requirements** 
* Every table in the silver layer must be materialized as a table by default through instructions in `dbt_project.yml`
* `silver_airport_comments` will be overridden to use an `incremental` materialization
* Also change every src table to ephemeral materialization - not in `dbt_project.yml`, but in the corresponding sql files individually

## Part 7: Snapshots

### Exercise 9: Snapshot on silver_airports
* Create a snapshot on `silver_airports`, call it `scd_silver_airports`. Research, understand and use the [check snapshot strategy](https://docs.getdbt.com/reference/resource-configs/check_cols) on all columns as this model doesn't have a timestamp column we can work with.
* Execute the snapshot

The airport `Los Angeles County Sheriff's Department Heliport` (airport_ident: `01CN`) must be closed. Simulate this change by updating the `type` column of this heliport to `closed` in `RAW.AIRPORTS`, then run `dbt run --select silver_airports` followed by `dbt snapshot`.

* Updating the record to "closed":
  ```sql
  update airstats.raw.airports
  set type = 'closed'
  where ident = '01CN';
  ```
* Command to execute and snapshot update:
  ```bash
  dbt run --select silver_airports
  dbt snapshot
  ```

#### Analyses
* Create `analyses/la_heliport_closed.sql` where you validate if the snapshot went through - select every line corresponding to this airport in the snapshot table.
* Execute the analysis and print the values to screen

### Exercise 10: Snapshot on silver_runways
* Create a snapshot for `silver_runways`, call it `scd_silver_runways`. Use the same check strategy as for `scd_silver_airports`.
* Execute the snapshot

## Part 8: Tests
Implement the following:
* Test every silver table: Figure out which values are unique and should not be null (use your educated guess for not null) and add these tests
* Find a column where an `accepted_values` test makes sense and use it
* Make relations between the three silver tables explicit by implementing `relationships` tests. Set the severity of all relationship tests to "warn" (since referential integrity may not hold across all source data).
* Use at least three dbt-expectations tests (in total) on these three models
* Implement two singular tests
* Add configuration to store test failures into a database table


## Part 9: Documentation
* Add descriptions to the silver tables and their columns
* Use a '{{ doc("...") }}'-based documentation at least once
* Create an overview.md where you discuss in a few sentences how the silver tables interconnect
