## Naming fields and tables
- The primary key of a model should be named `<object>_id`, for example, `account_id`. This makes it easier to know what `id` is being referenced in downstream joined models.
- Consistency is key! Use the same field names across models where possible. For example, a key to the `customers` table should be named `customer_id` rather than `user_id` or `id`.
- Do not use abbreviations when naming fields. Emphasize readability over brevity. For example, do not use `cust` for `customer` or `o` for `orders`.
- Avoid reserved words as column names.
- Booleans should be prefixed with `is_` or `has_`.
- Timestamp columns should be named `<event>_at`(for example, `created_at`).
- Dates should be named `<event>_date`. For example, `created_date.`
- Table, CTE, and column names should be written in `snake_case`.

## Style dbt models
- 👥 Models should be pluralized, for example, customers, orders, products.
- 🔑 Each model should have a primary key.
- 🔑 The primary key of a model should be named <object>_id, for example, account_id. This makes it easier to know what id is being referenced in downstream joined models.
Use underscores for naming dbt models; avoid dots.
  - ✅ models_without_dots
  - ❌ models.with.dots
  - Most data platforms use dots to separate database.schema.object, so using underscores instead of dots reduces your need for quoting as well as the risk of issues in certain parts of dbt. For more background, refer to this GitHub issue.
- 🔑 Keys should be string data types.
- 🔑 Consistency is key! Use the same field names across models where possible. For example, a key to the customers table should be named customer_id rather than user_id or 'id'.
- ❌ Do not use abbreviations or aliases. Emphasize readability over brevity. For example, do not use cust for customer or o for orders.
- ❌ Avoid reserved words as column names.
- ➕ Booleans should be prefixed with is_ or has_.
- 🕰️ Timestamp columns should be named <event>_at(for example, created_at) and should be in UTC. If a different timezone is used, this should be indicated with a suffix (created_at_pt).
- 📆 Dates should be named <event>_date. For example, created_date.
- 🔙 Events dates and times should be past tense — created, updated, or deleted.
- 💱 Price/revenue fields should be in decimal currency (19.99 for $19.99; many app databases store prices as integers in cents). If a non-decimal currency is used, indicate this with a suffix (price_in_cents).
- 🐍 Schema, table and column names should be in snake_case.
- 🏦 Use names based on the business terminology, rather than the source terminology. For example, if the source database uses user_id but the business calls them customer_id, use customer_id in the model.
- 🔢 Versions of models should use the suffix _v1, _v2, etc for consistency (customers_v1 and customers_v2).
- 🗄️ Use a consistent ordering of data types and consider grouping and labeling columns by type, as in the example below. This will minimize join errors and make it easier to read the model, as well as help downstream consumers of the data understand the data types and scan models for the columns they need. We prefer to use the following order: ids, strings, numerics, booleans, dates, and timestamps.

### Example model
```sql
with

source as (

    select * from {{ source('ecom', 'raw_orders') }}

),

renamed as (

    select

        ----------  ids
        id as order_id,
        store_id as location_id,
        customer as customer_id,

        ---------- strings
        status as order_status,

        ---------- numerics
        (order_total / 100.0)::float as order_total,
        (tax_paid / 100.0)::float as tax_paid,

        ---------- booleans
        is_fulfilled,

        ---------- dates
        date(order_date) as ordered_date,

        ---------- timestamps
        ordered_at

    from source

)

select * from renamed
```

## Styling SQL
- ☁️ Use SQLFluff to maintain these style rules automatically.
  - Customize .sqlfluff configuration files to your needs.
  - Refer to our SQLFluff config file for the rules we use in our own projects.
  - Exclude files and directories by using a standard .sqlfluffignore file. Learn more about the syntax in the .sqlfluffignore syntax docs.
    - Excluding unnecessary folders and files (such as target/, dbt_packages/, and macros/) can speed up linting, improve run times, and help you avoid irrelevant logs.
- 👻 Use Jinja comments ({# #}) for comments that should not be included in the compiled SQL.
- ⏭️ Use trailing commas.
- 4️⃣ Indents should be four spaces.
- 📏 Lines of SQL should be no longer than 80 characters.
- ⬇️ Field names, keywords, and function names should all be lowercase.
- 🫧 The as keyword should be used explicitly when aliasing a field or table.

### Fields, aggregations, and grouping
- 🔙 Fields should be stated before aggregates and window functions.
- 🤏🏻 Aggregations should be executed as early as possible (on the smallest data set possible) before joining to another table to improve performance.
- 🔢 Ordering and grouping by a number (eg. group by 1, 2) is preferred over listing the column names (see this classic rant for why). Note that if you are grouping by more than a few columns, it may be worth revisiting your model design.

### Joins
- 👭🏻 Prefer union all to union unless you explicitly want to remove duplicates.
- 👭🏻 If joining two or more tables, always prefix your column names with the table name. If only selecting from one table, prefixes are not needed.
- 👭🏻 Be explicit about your join type (i.e. write inner join instead of join).
- 🥸 Avoid table aliases in join conditions (especially initialisms) — it's harder to understand what the table called "c" is as compared to "customers".
- ➡️ Always move left to right to make joins easy to reason about - right joins often indicate that you should change which table you select from and which one you join to.

### 'Import' CTEs
- 🔝 All {{ ref('...') }} statements should be placed in CTEs at the top of the file.
- 📦 'Import' CTEs should be named after the table they are referencing.
- 🤏🏻 Limit the data scanned by CTEs as much as possible. Where possible, only select the columns you're actually using and use where clauses to filter out unneeded data.
- For example:
```sql
with

orders as (

    select
        order_id,
        customer_id,
        order_total,
        order_date

    from {{ ref('orders') }}

    where order_date >= '2020-01-01'

)
```

### Functional CTEs
- ☝🏻 Where performance permits, CTEs should perform a single, logical unit of work.
- 📖 CTE names should be as verbose as needed to convey what they do e.g. events_joined_to_users instead of user_events (this could be a good model name, but does not describe a specific function or transformation).
- 🌉 CTEs that are duplicated across models should be pulled out into their own intermediate models. Look out for chunks of repeated logic that should be refactored into their own model.
- 🔚 The last line of a model should be a select * from your final output CTE. This makes it easy to materialize and audit the output from different steps in the model as you're developing it. You just change the CTE referenced in the select statement to see the output from that step.

### Model Configuration
- 📝 Model-specific attributes (like sort/dist keys) should be specified in the model.
- 📂 If a particular configuration applies to all models in a directory, it should be specified in the dbt_project.yml file.
- 👓 In-model configurations should be specified like this for maximum readability:
```
{{
    config(
      materialized = 'table',
      sort = 'id',
      dist = 'id'
    )
}}
```

### Example SQL 1
```sql
with

events as (

    ...

),

{# CTE comments go here #}
filtered_events as (

    ...

)

select * from filtered_events
```

### Example SQL 2
```sql
with

my_data as (

    select
        field_1,
        field_2,
        field_3,
        cancellation_date,
        expiration_date,
        start_date

    from {{ ref('my_data') }}

),

some_cte as (

    select
        id,
        field_4,
        field_5

    from {{ ref('some_cte') }}

),

some_cte_agg as (

    select
        id,
        sum(field_4) as total_field_4,
        max(field_5) as max_field_5

    from some_cte

    group by 1

),

joined as (

    select
        my_data.field_1,
        my_data.field_2,
        my_data.field_3,

        -- use line breaks to visually separate calculations into blocks
        case
            when my_data.cancellation_date is null
                and my_data.expiration_date is not null
                then expiration_date
            when my_data.cancellation_date is null
                then my_data.start_date + 7
            else my_data.cancellation_date
        end as cancellation_date,

        some_cte_agg.total_field_4,
        some_cte_agg.max_field_5

    from my_data

    left join some_cte_agg
        on my_data.id = some_cte_agg.id

    where my_data.field_1 = 'abc' and
        (
            my_data.field_2 = 'def' or
            my_data.field_2 = 'ghi'
        )

    having count(*) > 1

)

select * from joined
```

## Styling Jinja
- 🫧 When using Jinja delimiters, use spaces on the inside of your delimiter, like {{ this }} instead of {{this}}
- 🆕 Use newlines to visually indicate logical blocks of Jinja.
- 4️⃣ Indent 4 spaces into a Jinja block to indicate visually that the code inside is wrapped by that block.
- ❌ Don't worry (too much) about Jinja whitespace control, focus on your project code being readable. The time you save by not worrying about whitespace control will far outweigh the time you spend in your compiled code where it might not be perfect.

### Examples of Jinja style
```
{% macro make_cool(uncool_id) %}

    do_cool_thing({{ uncool_id }})

{% endmacro %}
```
```
select
    entity_id,
    entity_type,
    {% if this %}

        {{ that }},

    {% else %}

        {{ the_other_thing }},

    {% endif %}
    {{ make_cool('uncool_id') }} as cool_id
```

## Styling YAML

- 2️⃣ Indents should be two spaces
- ➡️ List items should be indented
- 🔠 List items with a single entry can be a string. For example, 'select': 'other_user', but it's best practice to provide the argument as an explicit list. For example, 'select': ['other_user']
- 🆕 Use a new line to separate list items that are dictionaries where appropriate
- 📏 Lines of YAML should be no longer than 80 characters.
- 🛠️ Use the dbt JSON schema with any compatible Studio IDE and a YAML formatter (we recommend Prettier) to validate your YAML files and format them automatically.

### Example YAML
```yaml
models:
  - name: events
    columns:
      - name: event_id
        description: This is a unique identifier for the event
        data_tests:
          - unique
          - not_null

      - name: event_time
        description: "When the event occurred in UTC (eg. 2018-01-01 12:00:00)"
        data_tests:
          - not_null

      - name: user_id
        description: The ID of the user who recorded the event
        data_tests:
          - not_null
          - relationships:
              arguments: # available in v1.10.5 and higher. Older versions can set the <argument_name> as the top-level property.
                to: ref('users')
                field: id
```