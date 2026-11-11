{% docs __overview__ %}
# AirStats

Analytics project over the OurAirports dataset, built with dbt on Snowflake. Raw tables (`airports`, `runways`, `airport_comments`) are renamed in the bronze layer and cleaned in the silver layer.

## How the silver tables relate

`silver_airports` is the central table: one row per airport, identified by `airport_ident`.

- `silver_runways` has one row per runway and points to its airport through `airport_ident`. A relationship test confirms that every runway belongs to an existing airport.
- `silver_airport_comments` has one row per user comment and also points to its airport through `airport_ident`. The same test reports a warning because some comments refer to airports that are not in `silver_airports`.

An airport can therefore have many runways and many comments, but each runway and each comment belongs to a single airport.
{% enddocs %}
