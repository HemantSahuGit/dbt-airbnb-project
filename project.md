# Project Notes: dbt Airbnb Project

This document contains detailed notes on questions, answers, diagrams, examples, and interview cross-questions related to the dbt Airbnb project.

## Overview
- **Project Type**: Data Engineering project using dbt (Data Build Tool)
- **Purpose**: Likely to analyze Airbnb data, build data models, transformations, etc.
- **Date Started**: April 29, 2026

## Questions and Detailed Notes

### Question 1: How to load data into Snowflake tables from S3 using storage integration?
- **Question**: How to load data into Snowflake tables from S3 using storage integration?
- **Context**: Data loading from cloud storage to Snowflake warehouse for data engineering projects like Airbnb data analysis.
- **Answer**: Loading data from S3 to Snowflake using storage integration involves creating a secure connection between Snowflake and AWS S3, then using stages and COPY commands. The process includes:
  1. **Create Storage Integration**: Establishes trust between Snowflake and AWS IAM roles.
  2. **Grant Permissions**: Assigns necessary privileges to roles.
  3. **Create External Stage**: References the S3 bucket via the integration.
  4. **Load Data**: Use COPY INTO command to ingest data into tables.
  
  This method is secure, scalable, and supports various file formats (CSV, JSON, Parquet, etc.).
- **Diagram**: 
  ```mermaid
  flowchart TD
      A[AWS S3 Bucket] --> B[Create Storage Integration in Snowflake]
      B --> C[Grant USAGE on Integration to Role]
      C --> D[Create External Stage using Integration]
      D --> E[COPY INTO table FROM @stage]
      E --> F[Data Loaded into Snowflake Table]
      
      style A fill:#e1f5fe
      style F fill:#c8e6c9
  ```
- **Examples**: 
  - **Create Storage Integration**:
    ```sql
    CREATE STORAGE INTEGRATION my_s3_integration
      TYPE = EXTERNAL_STAGE
      STORAGE_PROVIDER = 'S3'
      STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::123456789012:role/MySnowflakeRole'
      ENABLED = TRUE
      STORAGE_ALLOWED_LOCATIONS = ('s3://my-bucket/path/');
    ```
  - **Grant Permissions**:
    ```sql
    GRANT USAGE ON INTEGRATION my_s3_integration TO ROLE my_role;
    ```
  - **Create Stage**:
    ```sql
    CREATE STAGE my_s3_stage
      STORAGE_INTEGRATION = my_s3_integration
      URL = 's3://my-bucket/path/'
      FILE_FORMAT = (TYPE = CSV);
    ```
  - **Load Data**:
    ```sql
    COPY INTO my_table
    FROM @my_s3_stage
    FILE_FORMAT = (TYPE = CSV, SKIP_HEADER = 1)
    ON_ERROR = 'CONTINUE';
    ```
- **Interview Cross-Questions**: 
  - What are the security implications of using storage integration vs. direct credentials?
  - How do you handle different file formats (CSV, JSON, Parquet) in the loading process?
  - What performance optimizations can be applied for large data loads?
  - How do you monitor and troubleshoot failed loads?
  - What's the difference between internal and external stages?
  - How do you handle incremental loads vs. full refreshes?
  - What are the cost implications of data transfer between S3 and Snowflake?

### Question 2: How do you set up dbt sources for the raw Airbnb data loaded from S3?
- **Question**: How do you set up dbt sources for the raw Airbnb data loaded from S3?
- **Context**: After loading raw data into Snowflake (or any data warehouse), dbt needs to be aware of these tables to build transformations on top of them. This is achieved by declaring them as "sources".
- **Answer**: dbt sources allow you to name and describe the raw data tables in your warehouse. This provides a clear lineage, allows for data quality testing, and enables checking for data freshness. The process is:
  1. **Create a YAML file**: In your `models` directory (or a subdirectory like `models/sources`), create a `.yml` file (e.g., `sources.yml`).
  2. **Define the Source**: Inside the YAML file, define your source, including its `name`, `database`, and `schema`.
  3. **List Tables**: Under the source, list the tables you want to reference. You can add descriptions for clarity.
  4. **Add Tests & Freshness (Optional)**: You can add data quality tests (e.g., `unique`, `not_null`) to columns and configure `freshness` checks to monitor how recently your source data has been updated.
  5. **Reference in Models**: Use the `{{ source() }}` Jinja macro in your dbt models to select from these source tables.
- **Diagram**:
  ```mermaid
  flowchart TD
      A[Snowflake Raw Tables<br>(e.g., raw.airbnb.listings)] --> B{models/sources.yml};
      B -- "Defines source 'airbnb_raw'" --> C[dbt Source Declaration];
      C -- "Referenced via {{ source('airbnb_raw', 'listings') }}" --> D[dbt Staging Model<br>(e.g., stg_listings.sql)];
      D --> E[Transformed Data<br>(e.g., Staging Tables/Views)];

      style A fill:#c8e6c9
      style D fill:#e1f5fe
      style E fill:#fff9c4
  ```
- **Examples**:
  - **`models/sources/sources.yml`**:
    ```yaml
    version: 2

    sources:
      - name: airbnb_raw
        description: "Raw Airbnb data loaded from S3 into Snowflake."
        database: raw
        schema: airbnb
        # You can configure freshness checks to monitor data staleness
        loaded_at_field: created_at # Assumes you have a timestamp column in your source table
        freshness:
          warn_after: {count: 24, period: hour}
          error_after: {count: 48, period: hour}

        tables:
          - name: listings
            description: "Raw listings data containing one row per listing."
            columns:
              - name: id
                description: "Primary key for listings."
                tests:
                  - unique
                  - not_null
          - name: reviews
            description: "Raw reviews data."
    ```
  - **`models/staging/stg_listings.sql`**:
    ```sql
    SELECT * FROM {{ source('airbnb_raw', 'listings') }}
    ```
- **Interview Cross-Questions**:
  - Why use `dbt source` instead of directly referencing tables (e.g., `raw.airbnb.listings`)?
  - What is `dbt source freshness` and how do you configure it?
  - How can you test your source data? What are some common source tests?
  - What's the difference between a source and a seed in dbt?
  - How does the `source()` macro help with environment management (dev vs. prod)?

### Question 3: What is dbt (Data Build Tool)?
- **Question**: What is dbt and what is its role in a data stack?
- **Context**: Understanding the core purpose of dbt and where it fits in the ELT (Extract, Load, Transform) process.
- **Answer**: dbt (Data Build Tool) is an open-source transformation tool that enables data professionals to transform, test, and document data within a cloud data warehouse. It is the **"T"** (Transform) in the **ELT** paradigm. Instead of writing boilerplate DDL/DML, you write `SELECT` statements (called "models"), and dbt handles turning them into tables and views in the correct order.
  1.  **SQL + Jinja**: You write standard SQL enhanced with the Jinja templating language. This allows for reusable code snippets (macros), control structures (`if` statements, `for` loops), and environment variables, making your SQL dynamic and DRY (Don't Repeat Yourself).
  2.  **Dependency Management (DAG)**: dbt automatically builds a Directed Acyclic Graph (DAG) of your entire project by parsing the `{{ ref() }}` and `{{ source() }}` functions in your models. This ensures that models are run in the correct order of dependency.
  3.  **Automated Testing**: You can write tests to assert data quality (e.g., a column should be `unique`, `not_null`, or have `relationships` to another table). `dbt test` runs these assertions against your data and alerts you to failures.
  4.  **Documentation**: dbt auto-generates a complete project documentation website. This site displays model code, dependencies, column schemas, and descriptions, creating a searchable data catalog for all users.
  5.  **Version Control Integration**: Because a dbt project is just a collection of SQL and YAML files, it integrates perfectly with Git for version control, code reviews (pull requests), and CI/CD pipelines.
- **Diagram**:
  ```mermaid
  graph TD
      subgraph "ELT Process"
          A[Source Systems<br>(e.g., APIs, Databases)] -- E (Extract) --> B[Raw Data Storage<br>(e.g., S3)];
          B -- L (Load) --> C[Data Warehouse<br>(e.g., Snowflake RAW Schema)];
          subgraph "dbt's Role (Transform)"
              C --> D{dbt};
              D --> E_Staging[Staging Models<br>(Cleaned, Renamed)];
              E_Staging --> F_Intermediate[Intermediate Models<br>(Joined, Aggregated)];
              F_Intermediate --> G_Marts[Data Marts<br>(Business-Facing Tables)];
          end
          G_Marts --> H[BI Tools / Dashboards];
      end

      style D fill:#FF9900
  ```
- **Interview Cross-Questions**:
  - What is the difference between ELT and ETL, and where does dbt fit?
  - What is a dbt "model" and what are the common materializations? (view, table, incremental, ephemeral)
  - Explain the purpose of the `ref()` and `source()` functions and the difference between them.
  - How does dbt help with collaboration among team members?
  - Can you use languages other than SQL with dbt? (e.g., dbt-python models)

### Question 4: What are dbt Adapters?
- **Question**: What are dbt adapters and why are they necessary?
- **Context**: Understanding how dbt communicates with specific databases like Snowflake.
- **Answer**: A dbt adapter is a plugin that enables dbt Core to connect to and execute queries against a specific data warehouse, database, or query engine. Because dbt compiles code but relies on the database to compute the transformations, it needs a way to translate its operations into the specific SQL dialect of the target platform.
  1. **Connection Management**: Adapters handle opening, running queries, and closing connections to the database securely.
  2. **Dialect Translation**: Different databases have different SQL syntax for creating tables, views, and managing incremental logic. Adapters contain the specific macro implementations (the "how-to") for each platform.
  3. **Package Ecosystem**: `dbt-core` is the base framework, while adapters like `dbt-snowflake`, `dbt-bigquery`, or `dbt-postgres` are installed separately based on your stack. In this project, `dbt-snowflake` is used.
- **Diagram**:
  ```mermaid
  graph LR
      A[dbt Core] -- Compiles SQL --> B(dbt-snowflake Adapter)
      B -- Executes Platform-Specific SQL --> C[(Snowflake Data Warehouse)]
      
      style A fill:#f9f2f4
      style B fill:#e1f5fe
      style C fill:#c8e6c9
  ```
- **Examples**:
  - **Installation**: You typically install the adapter via pip: `pip install dbt-snowflake`. (This automatically installs `dbt-core` as a dependency).
  - **Configuration (`profiles.yml`)**: You specify the adapter type in your connection profile:
    ```yaml
    my_airbnb_profile:
      target: dev
      outputs:
        dev:
          type: snowflake # This tells dbt which adapter to use
          account: <your_account_id>
          user: <your_username>
          # ... other connection details
    ```
- **Interview Cross-Questions**:
  - How do you configure an adapter connection in dbt?
  - What is the difference between dbt Core and a dbt adapter?
  - Where are connection credentials stored when using a dbt adapter locally? (`profiles.yml`)

### Question 5: What is materialization in dbt?
- **Question**: What is materialization, and how does dbt use it?
- **Context**: Materialization controls how dbt models are created and stored in the target warehouse.
- **Answer**: Materialization is the strategy dbt uses to execute a model and persist its result. In dbt, each model is compiled into SQL and then materialized according to a chosen type such as `view`, `table`, `incremental`, or `ephemeral`.
  1. **Materialization determines the final form**:
     - `view`: creates a database view that runs the compiled SQL each time it is queried.
     - `table`: creates a physical table populated with the model’s result set.
     - `incremental`: updates an existing table by appending or merging only new or changed data.
     - `ephemeral`: does not create a database object; instead, the model is inlined into downstream SQL.
  2. **Why it matters**: Materialization affects performance, storage, refresh behavior, and how you manage dependencies.
  3. **Where to configure materialization**:
     - `dbt_project.yml`: set project-wide or folder-level defaults.
     - Model-specific config block: `{{ config(materialized='table') }}` at the top of a model file.
     - In `dbt_project.yml`, within the `models:` section, target folders or specific models.
  4. **Default behavior**: If not specified, dbt defaults to the model materialization defined in the project config (often `view`).
- **Diagram**:
  ```mermaid
  graph LR
      A[dbt model SQL] --> B[Materialization Type]
      B --> C[view]
      B --> D[table]
      B --> E[incremental]
      B --> F[ephemeral]
      C --> G[No stored data, query runs on demand]
      D --> H[Full table stored in warehouse]
      E --> I[Only changed/new rows processed]
      F --> J[Inlined in downstream queries]

      style A fill:#e0f7fa
      style B fill:#ffe082
      style G fill:#c8e6c9
      style H fill:#c8e6c9
      style I fill:#c8e6c9
      style J fill:#c8e6c9
  ```
- **Examples**:
  - Default model (if project materialization is `view`):
    ```sql
    SELECT id, name, price
    FROM {{ ref('stg_listings') }}
    ```
  - Explicit table materialization:
    ```sql
    {{ config(materialized='table') }}

    SELECT id, name, price
    FROM {{ ref('stg_listings') }}
    ```
  - Incremental model example:
    ```sql
    {{ config(materialized='incremental', unique_key='id') }}

    SELECT id, name, price, updated_at
    FROM {{ ref('raw_listings') }}
    {% if is_incremental() %}
      WHERE updated_at > (SELECT MAX(updated_at) FROM {{ this }})
    {% endif %}
    ```
  - Ephemeral model example:
    ```sql
    {{ config(materialized='ephemeral') }}

    SELECT id, host_id, price
    FROM {{ ref('stg_listings') }}
    ```
- **Interview Cross-Questions**:
  - What is the difference between `table` and `view` materializations?
  - When should you use `incremental` models?
  - Why would you choose `ephemeral` materialization for a model?
  - How does materialization affect dbt performance and warehouse costs?

### Question 6: What are the most used Git commands?
- **Question**: What are the most commonly used Git commands in a typical development workflow?
- **Context**: Since dbt projects are code-based, version control using Git is an essential skill for managing changes, collaborating with teammates, and deploying to production.
- **Answer**: The most common Git commands follow the standard lifecycle of creating branches, making changes, staging them, committing, and syncing with a remote repository.
  1. **Setup & Info**: `git clone` (copy a repo), `git status` (check current state), `git log` (view history).
  2. **Branching**: `git checkout -b <branch-name>` (create and switch to a new branch) or `git branch` (list branches).
  3. **Staging**: `git add <file>` or `git add .` (move changes from working directory to staging area).
  4. **Committing**: `git commit -m "message"` (save staged changes to local repository).
  5. **Syncing**: `git pull` (fetch and merge from remote) and `git push origin <branch-name>` (send local commits to remote).
- **Diagram**:
  ```mermaid
  graph LR
      A[Working Directory] -- "git add" --> B[Staging Area]
      B -- "git commit" --> C[Local Repository]
      C -- "git push" --> D[(Remote Repository)]
      D -- "git pull" --> A
      
      style A fill:#f9f2f4
      style B fill:#fff9c4
      style C fill:#e1f5fe
      style D fill:#c8e6c9
  ```
- **Examples**:
  - **Basic Workflow Example**:
    ```bash
    git checkout -b feature/add-stg-listings
    # ... make changes to models/staging/stg_listings.sql ...
    git status
    git add models/staging/stg_listings.sql
    git commit -m "feat: add staging model for listings"
    git push origin feature/add-stg-listings
    ```
- **Interview Cross-Questions**:
  - What is the difference between `git fetch` and `git pull`?
  - How do you resolve a merge conflict?
  - What is the difference between `git merge` and `git rebase`?
  - What is the purpose of `.gitignore` in a dbt project?
  - How do you undo a commit that hasn't been pushed yet?

### Question 6: What are 'threads' in dbt?
- **Question**: What does the 'threads' setting mean when you initialize a dbt project?
- **Context**: During the `dbt init` process, you are prompted to set a number for `threads`. This is a core performance configuration for dbt.
- **Answer**: The `threads` setting in your `profiles.yml` file determines the maximum number of concurrent operations (like running models) that dbt can execute at once. It controls the level of parallelism.
  1.  **Parallel Execution**: Each thread opens a separate connection to your data warehouse. If you set `threads: 4`, dbt can run up to four independent models simultaneously.
  2.  **Performance Boost**: This is one of the primary ways to speed up a dbt project. dbt analyzes your project's Directed Acyclic Graph (DAG) to find models that don't depend on each other and runs them in parallel across the available threads.
  3.  **Resource Management**: The optimal number of threads depends on your data warehouse's capacity to handle concurrent queries and the structure of your dbt project. For powerful cloud warehouses like Snowflake, a starting value of 4 or 8 is common.
- **Diagram**:
  ```mermaid
  graph TD
      subgraph "dbt Project DAG"
          A[stg_listings]
          B[stg_reviews]
          C[stg_hosts]
      end

      subgraph "Execution with 4 Threads"
          A & B & C -- "Run in Parallel" --> D[int_listings_joined]
      end

      subgraph "Execution with 1 Thread"
          A_seq[stg_listings] --> B_seq[stg_reviews] --> C_seq[stg_hosts] -- "Run Sequentially" --> D_seq[int_listings_joined]
      end
  ```
- **Examples**:
  - **Configuration (`profiles.yml`)**:
    ```yaml
    my_airbnb_profile:
      target: dev
      outputs:
        dev:
          type: snowflake
          threads: 4 # dbt will use up to 4 parallel connections
          # ... other connection details
    ```
  - **Command Line Override**: You can temporarily change the thread count for a specific run.
    `dbt run --threads 8`
- **Interview Cross-Questions**:
  - How would you determine the optimal number of threads for a project?
  - What are the potential downsides of setting the number of threads too high?
  - Does increasing threads always improve `dbt run` performance? Why or why not?
  - How does the structure of your dbt DAG (e.g., wide vs. deep) impact the effectiveness of multiple threads?
- What is the order of precedence for configurations (e.g., `dbt_project.yml` vs. in-model `config` block)?
- How would you configure all models in a `staging` subdirectory to be built in a different schema?
- What is the difference between the `profile` in `dbt_project.yml` and the `profiles.yml` file itself?
- Why would you want to change the `model-paths` configuration?
- What is the difference between a dbt model and a materialization?
- How does the `ref()` function build the project DAG?
- Why does dbt encourage writing `SELECT` statements rather than DML (e.g., `INSERT`/`UPDATE`)?


### Question 7: What is the `dbt_project.yml` file?
- **Question**: Can you explain the different sections in the `dbt_project.yml` file?
- **Context**: The `dbt_project.yml` file is the primary configuration file for a dbt project. Understanding its structure is crucial for managing and scaling the project.
- **Answer**: This YAML file defines the configuration for your entire dbt project. Here's a breakdown of its key sections:
  1.  **`name`**: The unique name for your dbt project. It should use lowercase letters and underscores. This name is used when your project is installed as a package in another dbt project.
  2.  **`version`**: The version of your dbt project, which is useful for package management.
  3.  **`profile`**: This crucial setting links your project to a specific connection profile defined in your `profiles.yml` file. It tells dbt which database credentials and settings to use.
  4.  **`...-paths`**: These keys (`model-paths`, `seed-paths`, `test-paths`, etc.) define the directory structure of your project. They tell dbt where to find specific file types. You typically don't need to change the defaults.
  5.  **`clean-targets`**: A list of directories that will be removed when you run the `dbt clean` command. This is used to delete compiled artifacts (`target/`) and installed packages (`dbt_packages/`).
  6.  **`models`**: A powerful section for configuring how your models are built. You can apply configurations to all models in your project or to specific subdirectories. This is where you can set default materializations (e.g., `view`, `table`), schemas, tags, and more. Configurations here can be overridden by a `config()` block within an individual model file.
- **Examples**:
  - **Basic `dbt_project.yml`**:
    ```yaml
    name: 'aws_dbt_snowflake_airbnb_project'
    version: '1.0.0'
    profile: 'aws_dbt_snowflake_airbnb_project'

    model-paths: ["models"]
    # ... other paths

    clean-targets:
      - "target"
      - "dbt_packages"
    ```
  - **Advanced Model Configuration**: This example configures all models in the `staging` directory to be created in a `staging` schema and materialized as views.
    ```yaml
    # in dbt_project.yml
    models:
      aws_dbt_snowflake_airbnb_project: # Project name
        staging: # Directory name under models/
          +schema: staging # Creates models in 'your_target_schema_staging'
          +materialized: view
        marts:
          +materialized: table
    ```
- **Interview Cross-Questions**:
  - What is the order of precedence for configurations (e.g., `dbt_project.yml` vs. in-model `config` block)?
  - How would you configure all models in a `staging` subdirectory to be built in a different schema?
  - What is the difference between the `profile` in `dbt_project.yml` and the `profiles.yml` file itself?
  - Why would you want to change the `model-paths` configuration?

### Template for Each Question
- **Question**: [The question asked]
- **Context**: [Any background or context provided]
- **Answer**: [Detailed explanation]
- **Diagram**: [Mermaid diagram if applicable]
- **Examples**: [Code examples, data examples, etc.]
- **Interview Cross-Questions**: [Related questions that could be asked in interviews]

## Key Concepts Covered
- Snowflake Storage Integration
- External Stages
- Git ignore behavior and secret protection
- Removing sensitive files from git history

### Question 8: Why were my secrets exposed even though I added profiles.yml in the .gitignore?
- **Question**: Why did `profiles.yml` still expose secrets even after adding it to `.gitignore`?
- **Context**: You added `profiles.yml` to `.gitignore`, but the secrets were still visible in the repository or remote history.
- **Answer**: `.gitignore` only prevents new, untracked files from being added to Git. It does not remove or stop tracking a file that was already committed earlier.
  1. **Already tracked files remain tracked**: If `profiles.yml` was committed before adding it to `.gitignore`, Git will continue to track it until you remove it from the index.
  2. **`.gitignore` is not a security control**: It is a convenience for ignoring local files, not an enforcement mechanism for secrets that already exist in history.
  3. **Path/root issues**: If the actual file is not in the repository root or is stored elsewhere (for example, `~/.dbt/profiles.yml`), the ignore rule may not apply as expected.
  4. **Remote history still contains it**: Even after removing the file locally, the secret can remain in the remote repository history unless you rewrite history.
- **Diagram**:
  ```mermaid
  flowchart LR
      A[profiles.yml committed first] --> B[Git is tracking it]
      C[Add profiles.yml to .gitignore later] --> D[No effect on tracked file]
      B --> E[Secrets remain in repo history]
      D --> E
      style A fill:#ffccbc
      style C fill:#ffe0b2
      style E fill:#f8bbd0
  ```
- **Examples**:
  - Remove the file from the index but keep it locally:
    ```bash
    git rm --cached profiles.yml
    git add .gitignore
    git commit -m "Remove profiles.yml from repository and ignore it"
    git push origin main
    ```
  - If the file has already been pushed, rotate the secrets immediately and consider rewriting history:
    ```bash
    # Rewrite history only if absolutely necessary and with care
    git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch profiles.yml' --prune-empty -- --all
    git push --force origin main
    ```
  - Best practice: keep sensitive credentials in `~/.dbt/profiles.yml`, environment variables, or a secrets manager instead of committed repo files.
- **Interview Cross-Questions**:
  - Why does `.gitignore` not protect files already committed?
  - What steps do you take after accidentally committing a secret to Git?
  - How do you remove sensitive data from Git history safely?
  - What are better alternatives to storing credentials in `profiles.yml`?
  - How do you enforce secret management in a team project?

- Data Loading with COPY INTO
- AWS S3 Integration
- dbt Sources
- dbt Source Freshness
- Data Quality Testing
- dbt Models & Materializations
- ELT vs ETL
- dbt Adapters
- Git Version Control
- dbt Threads (Parallelism)
- dbt Project Configuration (`dbt_project.yml`)
- dbt Models

## Diagrams
- **S3 to Snowflake Data Load**
  ```mermaid
  flowchart TD
      A[AWS S3 Bucket] --> B[Create Storage Integration in Snowflake]
      B --> C[Grant USAGE on Integration to Role]
      C --> D[Create External Stage using Integration]
      D --> E[COPY INTO table FROM @stage]
      E --> F[Data Loaded into Snowflake Table]
      
      style A fill:#e1f5fe
      style F fill:#c8e6c9
  ```
- **dbt Source Declaration**
  ```mermaid
  flowchart TD
      A[Snowflake Raw Tables<br>(e.g., raw.airbnb.listings)] --> B{models/sources.yml};
      B -- "Defines source 'airbnb_raw'" --> C[dbt Source Declaration];
      C -- "Referenced via {{ source('airbnb_raw', 'listings') }}" --> D[dbt Staging Model<br>(e.g., stg_listings.sql)];
      D --> E[Transformed Data<br>(e.g., Staging Tables/Views)];

      style A fill:#c8e6c9
      style D fill:#e1f5fe
      style E fill:#fff9c4
  ```

## Examples Repository
- [Links to code examples, data samples, etc.]

## Interview Preparation
This section collects all cross-questions for easy review.
- What are the security implications of using storage integration vs. direct credentials?
- How do you handle different file formats (CSV, JSON, Parquet) in the loading process?
- What performance optimizations can be applied for large data loads?
- How do you monitor and troubleshoot failed loads?
- What's the difference between internal and external stages?
- How do you handle incremental loads vs. full refreshes?
- What are the cost implications of data transfer between S3 and Snowflake?
- Why use `dbt source` instead of directly referencing tables (e.g., `raw.airbnb.listings`)?
- What is `dbt source freshness` and how do you configure it?
- How can you test your source data? What are some common source tests?
- What's the difference between a source and a seed in dbt?
- How does the `source()` macro help with environment management (dev vs. prod)?
- What does `dbt run` do, and how does it differ from `dbt compile` or `dbt test`?

### Question 9: What CLI command does `dbt run` execute?
- **Question**: What does `dbt run` do at the CLI level?
- **Context**: `dbt run` is the core command for building models and materializing them in the data warehouse.
- **Answer**: `dbt run` compiles and executes all models in your dbt project that are eligible to run, following the DAG order and respecting dependency relationships.
  1. **Parses the project**: dbt reads your `dbt_project.yml`, `profiles.yml`, model SQL files, and any configuration files.
  2. **Builds the DAG**: It analyzes `{{ ref() }}` and `{{ source() }}` references to determine model dependencies.
  3. **Compiles SQL**: For each model, dbt renders the final SQL query using Jinja and any macros.
  4. **Executes queries**: Depending on materialization, dbt runs SQL against your warehouse to create tables, views, or incremental models.
  5. **Respects selection criteria**: It only runs models matching the current selection, filters, or tags if provided.
  
  In practice, `dbt run` is equivalent to running the compiled SQL in the correct order, not a single static command. It orchestrates the entire build process rather than executing a fixed command string like `COPY INTO`.
- **Diagram**:
  ```mermaid
  graph TD
      A[dbt project files] --> B[Parse YAML + SQL + Macros]
      B --> C[Build DAG with ref() and source()]
      C --> D[Compile SQL for each model]
      D --> E[Execute SQL in warehouse]
      E --> F[Materialized tables/views/incremental models]

      style A fill:#e0f7fa
      style E fill:#ffcdd2
      style F fill:#c8e6c9
  ```
- **Examples**:
  - Run all models in the project:
    ```bash
    dbt run
    ```
  - Run just staging models:
    ```bash
    dbt run --models staging
    ```
  - Run with 8 threads:
    ```bash
    dbt run --threads 8
    ```
- **Interview Cross-Questions**:
  - What is the difference between `dbt run` and `dbt compile`?
  - What does `dbt run --models my_model+` do?
  - How does dbt determine model order when running?
  - Can `dbt run` run tests or sources directly? Why or why not?
  - What happens if one model fails during `dbt run`?

### Question 10: What happens when we pass a semicolon (`;`) in a dbt model?
- **Question**: What happens when we include a semicolon in a dbt model SQL file?
- **Context**: dbt models are SQL files that are compiled and executed in the warehouse. Developers sometimes wonder whether semicolons are allowed or whether they cause issues.
- **Answer**: dbt models should generally contain a single SQL statement. A trailing semicolon at the end of the model is usually tolerated, but semicolons should not be used to separate multiple statements within a model.
  1. **Trailing semicolon**: A final `;` is usually harmless and often ignored by dbt or the target database adapter.
  2. **Multiple statements are unsupported**: Putting multiple statements in one model with semicolons can cause dbt to fail because it expects a single compiled query per model.
  3. **Adapter-specific behavior**: Most adapters (including Snowflake) will accept a final semicolon, but some may be stricter. Avoid semicolons inside Jinja expressions or between CTEs.
  4. **Best practice**: Keep dbt model SQL simple and avoid explicit semicolons unless necessary. Use separate models for separate transformation steps.
- **Examples**:
  - Normal model:
    ```sql
    SELECT id, name
    FROM {{ ref('stg_listings') }}
    ```
  - Allowed in many cases:
    ```sql
    SELECT id, name
    FROM {{ ref('stg_listings') }};
    ```
  - Not supported:
    ```sql
    CREATE TABLE tmp AS SELECT * FROM {{ ref('stg_listings') }};
    SELECT * FROM tmp;
    ```
- **Interview Cross-Questions**:
  - Why does dbt recommend one statement per model?
  - How do you handle multi-step transformations in dbt if multi-statement SQL is not allowed?
  - What is the difference between model SQL and SQL used in hooks or operations?

### Question 11: What are dbt sources?
- **Question**: What are dbt sources?
- **Context**: Sources are a fundamental concept in dbt for referencing raw data tables in your warehouse.
- **Answer**: dbt sources are named references to raw data tables in your data warehouse that your dbt models depend on. They provide a layer of abstraction and metadata management for your raw data.
  1. **Purpose**: Sources allow you to declare and describe the tables you want to use as inputs to your transformations, enabling data quality testing, freshness checks, and clear lineage.
  2. **Declaration**: Defined in YAML files (typically `models/sources/sources.yml`), sources specify the database, schema, and table names, along with optional metadata like descriptions and tests.
  3. **Usage**: Referenced in models using the `{{ source() }}` Jinja function, e.g., `{{ source('airbnb_raw', 'listings') }}`.
  4. **Benefits**: Provides environment-agnostic references, supports testing and documentation, and helps track data lineage from raw sources through transformations.
- **Diagram**:
  ```mermaid
  graph LR
      A[Raw Tables in Warehouse<br>(e.g., raw.airbnb.listings)] --> B{dbt Source Declaration<br>models/sources.yml}
      B --> C[Source Reference<br>{{ source('airbnb_raw', 'listings') }}]
      C --> D[dbt Models<br>(staging, marts)]
      D --> E[Data Lineage & Testing]

      style A fill:#c8e6c9
      style B fill:#e1f5fe
      style D fill:#fff9c4
  ```
- **Examples**:
  - Basic source declaration:
    ```yaml
    version: 2

    sources:
      - name: airbnb_raw
        description: "Raw Airbnb data loaded from S3."
        database: raw
        schema: airbnb
        tables:
          - name: listings
            description: "Raw listings data."
    ```
  - Using in a model:
    ```sql
    SELECT id, name, price
    FROM {{ source('airbnb_raw', 'listings') }}
    ```
- **Interview Cross-Questions**:
  - What is the difference between a dbt source and a dbt seed?
  - Why should you use sources instead of hardcoding table names?
  - How do sources help with environment management (dev vs. prod)?
  - What tests can you apply to sources?

## Examples Repository
- [Links to code examples, data samples, etc.]

## Interview Preparation
This section collects all cross-questions for easy review.
- What are the security implications of using storage integration vs. direct credentials?
- How do you handle different file formats (CSV, JSON, Parquet) in the loading process?
- What performance optimizations can be applied for large data loads?
- How do you monitor and troubleshoot failed loads?
- What's the difference between internal and external stages?
- How do you handle incremental loads vs. full refreshes?
- What are the cost implications of data transfer between S3 and Snowflake?
- Why use `dbt source` instead of directly referencing tables (e.g., `raw.airbnb.listings`)?
- What is `dbt source freshness` and how do you configure it?
- How can you test your source data? What are some common source tests?
- What's the difference between a source and a seed in dbt?
- How does the `source()` macro help with environment management (dev vs. prod)?
- What does `dbt run` do, and how does it differ from `dbt compile` or `dbt test`?

### Question 12: How to add materialization at the model level?
- **Question**: How to add materialization at the model level?
- **Context**: Configuring materialization directly in a dbt model file for per-model control.
- **Answer**: To set materialization at the model level, use the `{{ config(materialized='...') }}` Jinja block at the very top of your model SQL file. This overrides any project or folder-level defaults for that specific model.
  1. **Syntax**: Place `{{ config(materialized='materialization_type') }}` as the first line in the model.
  2. **Supported types**: `view`, `table`, `incremental`, `ephemeral`.
  3. **Additional configs**: You can combine with other configs like `schema`, `alias`, etc., in the same block.
  4. **Precedence**: Model-level config takes priority over project/folder configs.
- **Diagram**:
  ```mermaid
  graph TD
      A[Model File<br>models/marts/dim_listings.sql] --> B[Add config block at top]
      B --> C[{{ config(materialized='table') }}]
      C --> D[Model SQL below]
      D --> E[dbt run creates table]

      style A fill:#e0f7fa
      style C fill:#ffe082
      style E fill:#c8e6c9
  ```
- **Examples**:
  - Table materialization:
    ```sql
    {{ config(materialized='table') }}

    SELECT id, name, price
    FROM {{ ref('stg_listings') }}
    ```
  - Incremental with unique key:
    ```sql
    {{ config(materialized='incremental', unique_key='id') }}

    SELECT id, name, price, updated_at
    FROM {{ ref('raw_listings') }}
    {% if is_incremental() %}
      WHERE updated_at > (SELECT MAX(updated_at) FROM {{ this }})
    {% endif %}
    ```
  - Ephemeral model:
    ```sql
    {{ config(materialized='ephemeral') }}

    SELECT id, host_id
    FROM {{ ref('stg_listings') }}
    ```
- **Interview Cross-Questions**:
  - What is the precedence order for materialization configs?
  - When would you use model-level materialization over project-level?
  - Can you combine multiple configs in one config block?

### Question 13: What is the project file, model file, and property file in dbt?
- **Question**: What is the project file, model file, and property file in dbt?
- **Context**: Understanding the key file types that make up a dbt project structure.
- **Answer**: dbt projects consist of several key file types that define configurations, transformations, and metadata.
  1. **Project file ()**: The main configuration file for the entire dbt project. It defines project name, profile, paths, and default settings for models.
  2. **Model file**: SQL files (e.g., ) in the  directory that contain the transformation logic. These are compiled and executed to create tables/views in the warehouse.
  3. **Property file**: YAML files (often named  or ) that define metadata for models, including descriptions, column types, and tests.
- **Diagram**:
  ```mermaid
  graph TD
      A[dbt Project] --> B[dbt_project.yml<br>Project config]
      A --> C[models/<br>Model files (.sql)]
      A --> D[models/<br>Property files (.yml)]
      B --> E[Project settings]
      C --> F[SQL transformations]
      D --> G[Metadata & tests]

      style A fill:#e0f7fa
      style B fill:#ffe082
      style C fill:#c8e6c9
      style D fill:#fff9c4
  ```
- **Examples**:
  - **Project file** ():
    ```yaml
    name: 'my_project'
    version: '1.0.0'
    profile: 'my_profile'
    model-paths: ["models"]
    ```
  - **Model file** ():
    ```sql
    SELECT id, name, price
    FROM {{ source('raw', 'listings') }}
    ```
  - **Property file** ():
    ```yaml
    version: 2
    models:
      - name: stg_listings
        description: "Staged listings data"
        columns:
          - name: id
            tests:
              - unique
              - not_null
    ```
- **Interview Cross-Questions**:
  - What is the difference between a model file and a property file?
  - Why is the project file important for dbt?
  - How do property files help with data quality?
  - Can you have multiple project files in one dbt project?

### Question 13: What is the project file, model file, and property file in dbt?
- **Question**: What is the project file, model file, and property file in dbt?
- **Context**: Understanding the key file types that make up a dbt project structure.
- **Answer**: dbt projects consist of several key file types that define configurations, transformations, and metadata.
  1. **Project file (`dbt_project.yml`)**: The main configuration file for the entire dbt project. It defines project name, profile, paths, and default settings for models.
  2. **Model file**: SQL files (e.g., `.sql`) in the `models/` directory that contain the transformation logic. These are compiled and executed to create tables/views in the warehouse.
  3. **Property file**: YAML files (often named `schema.yml` or `properties.yml`) that define metadata for models, including descriptions, column types, and tests.
- **Diagram**:
  ```mermaid
  graph TD
      A[dbt Project] --> B[dbt_project.yml<br>Project config]
      A --> C[models/<br>Model files (.sql)]
      A --> D[models/<br>Property files (.yml)]
      B --> E[Project settings]
      C --> F[SQL transformations]
      D --> G[Metadata & tests]

      style A fill:#e0f7fa
      style B fill:#ffe082
      style C fill:#c8e6c9
      style D fill:#fff9c4
  ```
- **Examples**:
  - **Project file** (`dbt_project.yml`):
    ```yaml
    name: 'my_project'
    version: '1.0.0'
    profile: 'my_profile'
    model-paths: ["models"]
    ```
  - **Model file** (`models/staging/stg_listings.sql`):
    ```sql
    SELECT id, name, price
    FROM {{ source('raw', 'listings') }}
    ```
  - **Property file** (`models/staging/schema.yml`):
    ```yaml
    version: 2
    models:
      - name: stg_listings
        description: "Staged listings data"
        columns:
          - name: id
            tests:
              - unique
              - not_null
    ```
- **Interview Cross-Questions**:
  - What is the difference between a model file and a property file?
  - Why is the project file important for dbt?
  - How do property files help with data quality?
  - Can you have multiple project files in one dbt project?

### Question 13: What does dbt run and dbt compile do?
- **Question**: What does dbt run and dbt compile do?
- **Context**: Understanding the core dbt CLI commands for model execution and compilation in data transformation workflows.
- **Answer**: 
  - **dbt run**: This command executes all the models in your dbt project. It compiles the Jinja templates in your model files into raw SQL, then runs that SQL against your database (e.g., Snowflake). Depending on the materialization, it creates or updates tables, views, or incremental loads. It's the primary command to build your data warehouse.
    - **Process**: Parses models, resolves dependencies (using ref() and source()), compiles to SQL, executes in dependency order.
    - **Output**: Creates/updates database objects; logs success/failures.
    - **Use case**: To materialize your transformations into the database.
  - **dbt compile**: This command compiles your dbt models into SQL files without executing them. It processes Jinja templates, resolves references, and generates the final SQL that would be run, saving it to the target/compiled folder.
    - **Process**: Same parsing and compilation as run, but stops before execution.
    - **Output**: SQL files in target/compiled/; useful for debugging or manual execution.
    - **Use case**: To check generated SQL, debug issues, or integrate with other tools.
  - **Key Differences**: run executes the SQL (affects database), compile only generates SQL (no database changes).
- **Diagram**:
  ```mermaid
  graph TD
      A[dbt run] --> B[Parse Models]
      B --> C[Resolve Dependencies]
      C --> D[Compile Jinja to SQL]
      D --> E[Execute SQL in Database]
      E --> F[Create/Update Tables/Views]

      G[dbt compile] --> B
      G --> C
      G --> D
      D --> H[Save SQL to target/compiled/]
      H --> I[No Execution]

      style A fill:#4caf50
      style G fill:#2196f3
      style F fill:#8bc34a
      style I fill:#ffc107
  ```
- **Examples**:
  - Running all models: `dbt run` (executes everything in models/ folder).
  - Running specific model: `dbt run --models bronze_listings` (only runs that model).
  - Compiling all: `dbt compile` (generates SQL for all models).
  - Compiling specific: `dbt compile --models marts.dim_customers` (compiles only that model).
  - Output example (compile): After `dbt compile`, check `target/compiled/models/bronze/bronze_listings.sql` for the generated SQL.
- **Interview Cross-Questions**:
  - What is the difference between dbt run and dbt build?
  - How does dbt handle model dependencies during run?
  - When would you use dbt compile instead of run?
  - What happens if a model fails during dbt run?

### Question 14: What is a Jinja function?
- **Question**: What is a Jinja function?
- **Context**: Understanding how Jinja templating is used in dbt to dynamically generate SQL and create reusable code blocks.
- **Answer**: 
  - **Jinja Overview**: Jinja is a templating language that allows you to use Python-like logic and variables in your SQL files. In dbt, Jinja lets you write dynamic, reusable SQL by adding conditional logic, loops, and macro definitions.
  - **Jinja Functions**: These are predefined or custom functions in Jinja/dbt that you can call within your models and macros to achieve various tasks.
    - **Built-in Jinja functions**: Variables like {{ var('variable_name') }} for runtime variables, state() for model state, execute() for conditional execution.
    - **dbt-specific functions**: ref() to reference other models, source() to reference raw data sources, config() to set model properties, this to reference the current model.
    - **Custom Jinja Functions/Macros**: You can define reusable blocks of code as macros using {% macro macro_name(args) %} ... {% endmacro %}.
  - **Syntax**: Jinja uses double braces {{ }} for expressions and single braces with percent {% %} for statements.
- **Common Jinja Functions in dbt**:
  - {{ ref('model_name') }}: References another dbt model; creates dependency.
  - {{ source('source_name', 'table_name') }}: References a raw data source defined in YAML.
  - {{ var('key') }}: Accesses variables passed at runtime using --vars flag.
  - {{ config(materialized='table') }}: Sets model-level configuration.
  - {{ this }}: Refers to the current model being built.
  - {{ is_incremental() }}: Checks if a model is being run in incremental mode.
  - {{ execute }}: Boolean flag; true during execute phase of dbt run.
- **Diagram**:
  ```mermaid
  graph TD
      A[Jinja Code in dbt Model] --> B[dbt Parser]
      B --> C{Jinja Syntax?}
      C -->|{{ }}| D[Expression Evaluation]
      C -->|{% %}| E[Statement Execution]
      D --> F[Replace with Value]
      E --> G[Execute Logic]
      F --> H[Final SQL]
      G --> H
      H --> I[Send to Database]

      style A fill:#e1bee7
      style H fill:#c8e6c9
      style I fill:#bbdefb
  ```
- **Examples**:
  - Using ref():
    ```sql
    SELECT *
    FROM {{ ref('stg_listings') }}
    WHERE created_at > '2025-01-01'
    ```
  - Using source():
    ```sql
    SELECT id, name, price
    FROM {{ source('airbnb_raw', 'listings') }}
    ```
  - Using var() for runtime variables:
    ```sql
    SELECT *
    FROM {{ ref('listings') }}
    WHERE date = '{{ var("run_date") }}'
    ```
    Command: dbt run --vars '{run_date: "2025-01-15"}'
  - Using is_incremental():
    ```sql
    {{ config(materialized='incremental') }}

    SELECT id, name, updated_at
    FROM {{ source('airbnb_raw', 'listings') }}
    {% if is_incremental() %}
      WHERE updated_at > (SELECT MAX(updated_at) FROM {{ this }})
    {% endif %}
    ```
  - Creating a custom macro:
    ```sql
    {% macro get_latest_by_date(table_name, date_col) %}
      WITH latest AS (
        SELECT *,
          ROW_NUMBER() OVER (ORDER BY {{ date_col }} DESC) as rn
        FROM {{ table_name }}
      )
      SELECT * FROM latest WHERE rn = 1
    {% endmacro %}
    
    -- Usage in a model:
    {{ get_latest_by_date(ref('listings'), 'updated_at') }}
    ```
  - Conditional logic:
    ```sql
    SELECT id, name, price
    FROM {{ ref('listings') }}
    {% if execute %}
      WHERE price > {{ var('min_price', 100) }}
    {% endif %}
    ```
- **Interview Cross-Questions**:
  - What is the difference between {{ }} and {% %} in Jinja?
  - How do you pass variables to dbt using --vars?
  - What is the difference between ref() and source()?
  - How do you create a custom macro in dbt?
  - When would you use execute flag in Jinja?

### Question 15: Production-Level Jinja Examples in dbt
- **Question**: Add different Jinja examples that are used in industry production-level code.
- **Context**: Providing advanced, real-world Jinja patterns commonly used in production dbt projects for dynamic SQL generation, macros, and complex logic.
- **Answer**: Below are production-level Jinja examples demonstrating advanced templating techniques used in industry dbt projects. These go beyond basic ref() and source() calls, showing dynamic schema generation, conditional logic, loops, and custom macros.
- **Examples**:
  1. **Dynamic Schema Generation Macro** (like your generate_schema_name.sql):
     ```sql
     {% macro generate_schema_name(custom_schema_name, node) -%}
       {%- set default_schema = target.schema -%}
       {%- if custom_schema_name is none -%}
         {{ default_schema }}
       {%- elif target.name == 'prod' -%}
         {{ custom_schema_name | trim }}
       {%- else -%}
         {{ default_schema }}_{{ custom_schema_name | trim }}
       {%- endif -%}
     {%- endmacro %}
     ```
     - **Usage**: In dbt_project.yml: `generate_schema_name: "{{ custom.generate_schema_name(var('custom_schema', none), this) }}"`

  2. **Environment-Based Table Selection**:
     ```sql
     {% set source_table = 'raw_listings' if target.name == 'dev' else 'prod_listings' %}
     
     SELECT id, name, price
     FROM {{ source('airbnb', source_table) }}
     {% if target.name == 'prod' %}
       WHERE created_at >= '{{ var("prod_start_date") }}'
     {% endif %}
     ```

  3. **Loop for Generating Multiple Columns**:
     ```sql
     {% set columns = ['id', 'name', 'price', 'host_id'] %}
     
     SELECT
       {% for col in columns %}
         {{ col }}{% if not loop.last %},{% endif %}
       {% endfor %}
     FROM {{ ref('stg_listings') }}
     ```

  4. **Incremental Load with Custom Logic**:
     ```sql
     {{ config(materialized='incremental', unique_key='id') }}
     
     SELECT id, name, price, updated_at,
            '{{ invocation_id }}' as dbt_batch_id
     FROM {{ source('airbnb_raw', 'listings') }}
     {% if is_incremental() %}
       WHERE updated_at > (SELECT MAX(updated_at) FROM {{ this }})
         OR id IN (SELECT DISTINCT id FROM {{ ref('force_refresh_ids') }})
     {% endif %}
     ```

  5. **Macro for Data Quality Checks**:
     ```sql
     {% macro test_not_null(column_name, model_name) %}
       SELECT COUNT(*) as null_count
       FROM {{ ref(model_name) }}
       WHERE {{ column_name }} IS NULL
       HAVING COUNT(*) > 0
     {% endmacro %}
     ```
     - **Usage in test**: `{{ test_not_null('price', 'dim_listings') }}`

  6. **Adapter-Specific SQL Generation**:
     ```sql
     {% set sql_engine = 'snowflake' if 'snowflake' in target.type else 'postgres' %}
     
     SELECT
       id,
       {% if sql_engine == 'snowflake' %}
         TRY_CAST(price AS DECIMAL(10,2)) as price
       {% else %}
         CAST(price AS DECIMAL(10,2)) as price
       {% endif %}
     FROM {{ ref('raw_listings') }}
     ```

  7. **Dynamic Column Selection with Variables**:
     ```sql
     {% set include_sensitive = var('include_sensitive_data', false) %}
     
     SELECT
       id,
       name,
       price,
       {% if include_sensitive %}
         host_email,
         host_phone
       {% endif %}
       created_at
     FROM {{ ref('listings') }}
     ```

  8. **Pre/Post Hook with Conditional Logic**:
     ```sql
     {{ config(
       materialized='table',
       pre_hook="{% if target.name == 'prod' %}GRANT SELECT ON {{ this }} TO analyst_role;{% endif %}",
       post_hook="INSERT INTO audit_log VALUES ('{{ this.name }}', '{{ invocation_id }}', CURRENT_TIMESTAMP);"
     ) }}
     
     SELECT * FROM {{ ref('stg_listings') }}
     ```

  9. **Macro for Generating Surrogate Keys**:
     ```sql
     {% macro surrogate_key(field_list) %}
       {% if field_list is string %}
         {% set field_list = [field_list] %}
       {% endif %}
       
       {% set fields = [] %}
       {% for field in field_list %}
         {% do fields.append("COALESCE(CAST(" ~ field ~ " AS VARCHAR), '_dbt_null_')") %}
       {% endfor %}
       
       {% if target.type == 'snowflake' %}
         HASH({{ fields | join(', ') }})
       {% else %}
         MD5(CONCAT({{ fields | join(', ') }}))
       {% endif %}
     {% endmacro %}
     ```
     - **Usage**: `{{ surrogate_key(['id', 'source']) }} as listing_key`

  10. **Complex Incremental with Merge Logic**:
      ```sql
      {{ config(materialized='incremental', unique_key='id') }}
      
      {% set merge_condition = "t.updated_at < s.updated_at" %}
      
      SELECT
        COALESCE(s.id, t.id) as id,
        COALESCE(s.name, t.name) as name,
        COALESCE(s.price, t.price) as price,
        COALESCE(s.updated_at, t.updated_at) as updated_at
      FROM {{ this }} t
      {% if is_incremental() %}
        FULL OUTER JOIN {{ source('airbnb_raw', 'listings') }} s
          ON t.id = s.id
          AND {{ merge_condition }}
      {% else %}
        RIGHT JOIN {{ source('airbnb_raw', 'listings') }} s
          ON 1=1
      {% endif %}
      ```
- **Diagram**:
  ```mermaid
  graph TD
      A[Production Jinja Patterns] --> B[Dynamic Logic]
      A --> C[Environment Awareness]
      A --> D[Reusable Macros]
      A --> E[Adapter Flexibility]
      B --> F[Conditional SQL]
      C --> G[Dev/Prod Differences]
      D --> H[Custom Functions]
      E --> I[Database Agnostic]
      F --> J[Runtime Decisions]
      G --> K[Config Variations]
      H --> L[Code Reuse]
      I --> M[Cross-Platform]

      style A fill:#4caf50
      style M fill:#2196f3
  ```
- **Interview Cross-Questions**:
  - How do you handle database-specific syntax in dbt macros?
  - What are pre and post hooks used for in production?
  - How do you implement surrogate key generation across different databases?
  - When would you use loops in Jinja for column generation?
  - How do you conditionally include sensitive data based on environment?

### Question 16: What is incremental load and how does it work?
- **Question**: What is incremental load, how does it work?
- **Context**: Explaining incremental materialization in dbt for efficient production data pipelines.
- **Answer**:
  - **Incremental load** is a dbt materialization strategy where only new or changed rows are processed during a run, instead of rebuilding the entire table every time. This is ideal for large datasets and production workloads where full refreshes would be too slow or expensive.
  - **How it works**:
    1. dbt evaluates the model and identifies whether it is being executed in incremental mode (using `is_incremental()`).
    2. If the target table does not exist, dbt creates it from the full SQL query.
    3. If the target exists, dbt runs only the incremental SQL block and merges new or updated rows into the existing table.
    4. The incremental condition is usually based on a timestamp column, unique key, or a change data capture (CDC) logic.
  - **Core elements**:
    - `{{ config(materialized='incremental', unique_key='id') }}`: Marks the model as incremental.
    - `is_incremental()`: A Jinja test to execute incremental-only SQL.
    - `{{ this }}`: References the target table for comparing existing rows.
    - `unique_key`: Defines how to match source rows to existing rows.
  - **Benefits**:
    - Faster runs on large tables.
    - Lower compute and storage costs.
    - Better for streaming or high-frequency data ingestion.
  - **Typical pattern**:
    ```sql
    {{ config(materialized='incremental', unique_key='id') }}

    SELECT id, name, price, updated_at
    FROM {{ source('airbnb_raw', 'listings') }}
    {% if is_incremental() %}
      WHERE updated_at > (SELECT MAX(updated_at) FROM {{ this }})
    {% endif %}
    ```
  - **What happens during the first run**: dbt treats the model as a full load and creates the table.
  - **What happens on subsequent runs**: dbt executes only the incremental branch and inserts/updates rows.
  - **Advanced incremental patterns**:
    - Use `MERGE` for source systems that support it (Snowflake, BigQuery, Redshift).
    - Combine incremental logic with `dbt_utils.star` to select new columns automatically.
    - Add `WHERE` filters for deleted or changed records.
    - Use `vars` and config flags to switch between `full_refresh` and incremental mode.
  - **Interview Cross-Questions**:
    - What is the difference between incremental and full-refresh models in dbt?
    - How does dbt know whether to run incremental logic or full-load logic?
    - Why is `unique_key` important for incremental models?
    - When might you choose to do a full refresh instead of incremental?
    - How do you handle late-arriving data in an incremental model?

### Question 17: Explanation of bronze_bookings.sql incremental model
- **Question**: What does the incremental load code in bronze_bookings.sql do?
- **Context**: Real-world example of an incremental model implementation in the Airbnb project.
- **Code Snippet**:
  ```sql
  {% set incremental_column = 'CREATED_AT' %}

  select *
  from {{ source('staging', 'bookings') }}

  {% if is_incremental() %}
  where {{ incremental_column }} >= (
      select coalesce(max({{ incremental_column }}), cast('1900-01-01' as timestamp))
      from {{ this }}
  )
  {% endif %}
  ```
- **Line-by-line breakdown**:
  - **Line 1**: `{% set incremental_column = 'CREATED_AT' %}` - Defines a Jinja variable to store the column name used for incremental filtering. Using a variable makes it reusable if you need to reference it multiple times.
  - **Line 3-4**: `select * from {{ source('staging', 'bookings') }}` - Selects all columns from the raw bookings source table defined in YAML sources.
  - **Line 6**: `{% if is_incremental() %}` - Checks if this model is running in incremental mode. This block only executes on subsequent runs (not the first full load).
  - **Line 7-10**: The WHERE clause filters rows where `CREATED_AT >= max(CREATED_AT)` from the existing table. The subquery:
    - Gets the maximum `CREATED_AT` from the existing table `{{ this }}` (the target table being built).
    - Uses `COALESCE` to default to '1900-01-01' if the table is empty (first run).
    - Only new or recently modified bookings are loaded.
- **What happens**:
  - **First run**: `is_incremental()` returns false, so the WHERE clause is skipped. All bookings are loaded into the table.
  - **Second run**: `is_incremental()` returns true. Only bookings created/modified after the max existing CREATED_AT are loaded and appended.
- **Why this pattern**:
  - **Efficiency**: Instead of reprocessing the entire bookings table, only new rows are fetched from the source.
  - **Cost-effective**: Reduces compute on Snowflake and data transfer from S3.
  - **Idempotency**: Safe to re-run; duplicate keys are handled by Snowflake's insert behavior or merge logic.
- **Potential enhancement**:
  - Add `unique_key='booking_id'` in the config to enable merge-based updates if bookings can be modified (not just inserted).
  - Add `on_schema_change='fail'` to prevent silent schema mismatches.
  ```sql
  {{ config(materialized='incremental', unique_key='booking_id', on_schema_change='fail') }}
  ```
- **Interview Cross-Questions**:
  - Why use a Jinja variable for the incremental column instead of hardcoding it?
  - What happens if CREATED_AT has NULL values in the source?
  - How would you handle late-arriving data (rows inserted with old timestamps)?
  - What's the difference between this append-only pattern and a merge-based incremental?
  - How would you test that incremental logic is working correctly?

### Question 18: What does materialized = incremental do and how to configure it in dbt_project.yml?
- **Question**: What does `materialized = incremental` do? Can we configure it in dbt_project.yml?
- **Context**: Understanding incremental materialization configuration at project and folder levels for consistent dbt project setup.
- **Answer**:
  - **What `materialized = incremental` does**: It tells dbt to treat a model as incremental, meaning:
    1. On the first run, dbt creates the full table from the entire source dataset.
    2. On subsequent runs, dbt only processes new or changed rows based on your incremental logic (using `is_incremental()`).
    3. It merges or appends only new rows instead of dropping and recreating the table.
    4. Saves time, compute costs, and storage for large datasets.
  - **Yes, you can configure it in dbt_project.yml** at different levels:
    1. **Project-level**: All models in the project default to incremental.
    2. **Folder-level**: All models in a specific folder (e.g., bronze/) default to incremental.
    3. **Model-level**: Individual models override project/folder settings (highest precedence).
- **Configuration Examples in dbt_project.yml**:
  - **Project-level (all models incremental)**:
    ```yaml
    version: '1.0.0'
    name: 'airbnb_project'
    
    models:
      airbnb_project:
        materialized: incremental
    ```
  - **Folder-level (bronze folder models incremental)**:
    ```yaml
    version: '1.0.0'
    name: 'airbnb_project'
    
    models:
      airbnb_project:
        bronze:
          materialized: incremental
        silver:
          materialized: table
        gold:
          materialized: view
    ```
  - **With additional incremental configs**:
    ```yaml
    models:
      airbnb_project:
        bronze:
          materialized: incremental
          unique_key: id
          on_schema_change: fail
        
        silver:
          materialized: table
    ```
- **Key incremental configurations**:
  - `materialized: incremental` - Marks the model as incremental.
  - `unique_key: [id, source]` - Defines how to match rows for merge/upsert (can be single or multiple columns).
  - `on_schema_change: fail|ignore|append_new_columns` - How to handle schema changes in incremental runs.
  - `incremental_strategy: append|delete+insert|merge` - How to insert new rows (database-specific).
- **Precedence order** (highest to lowest):
  1. **Model-level config** (in model file with `{{ config(...) }}`).
  2. **Folder-level config** (in dbt_project.yml under folder name).
  3. **Project-level config** (in dbt_project.yml under models).
  4. **dbt defaults** (table materialization if nothing specified).
- **Real-world example from dbt_project.yml**:
  ```yaml
  name: 'airbnb_project'
  version: '1.0.0'
  
  models:
    airbnb_project:
      # All bronze models are incremental with CREATED_AT as the natural key
      bronze:
        materialized: incremental
        unique_key: id
        
        # Specific model override
        bronze_bookings:
          materialized: incremental
          unique_key: booking_id
          
      # Silver models are tables (no incremental)
      silver:
        materialized: table
      
      # Gold models are views
      gold:
        materialized: view
  ```
- **When NOT to use incremental in dbt_project.yml**:
  - For small tables that rebuild quickly.
  - When you need full refreshes for debugging or auditing.
  - For models that depend on other incrementals (can cause inconsistencies).
- **Interview Cross-Questions**:
  - What's the difference between folder-level and model-level incremental configuration?
  - How does dbt know which materialization strategy to use when multiple levels are defined?
  - Can you override a project-level incremental config at the model level?
  - What happens if you don't specify `unique_key` in an incremental model?
  - Why might you choose `delete+insert` over `append` strategy?

### Question 19: What are the different modes of incrementing data in dbt?
- **Question**: What are the different modes of incrementing data in dbt?
- **Context**: Understanding dbt incremental strategies and the ways dbt applies new row processing in production.
- **Answer**:
  - dbt incremental models can use different strategies to add or update rows in the target table. These are configured with `incremental_strategy` and/or by the target adapter's default behavior.
  - **Common incremental strategies**:
    1. **append** (default for many adapters)
       - dbt simply inserts the new rows produced by the incremental query into the target table.
       - No deduplication or merge logic is applied automatically.
       - Use this when source data is append-only and there are no updates to existing rows.
    2. **merge**
       - dbt uses a SQL `MERGE` statement to update existing rows and insert new rows.
       - Requires a `unique_key` to determine how source rows match target rows.
       - Best for slowly changing dimensions, update-capable source records, or when upserts are needed.
       - Supported on adapters like Snowflake, BigQuery, Redshift, SQL Server, and others.
    3. **delete+insert**
       - dbt deletes rows from the target table that match the incremental condition and then inserts the new rows.
       - Useful when source rows can change and merge is not supported, but you still want a deterministic replace of the changed range.
       - Often used with timestamp-based filters or partition predicates.
  - **Adapter-specific behaviors**:
    - Some platforms default to `append` if no `incremental_strategy` is specified.
    - Snowflake and BigQuery support `merge`, while older adapters may only support `append` or `delete+insert`.
  - **Configuration example**:
    ```sql
    {{ config(
      materialized='incremental',
      unique_key='id',
      incremental_strategy='merge'
    ) }}
    ```
  - **When to choose each mode**:
    - `append`: use for append-only log or event tables with no updates.
    - `merge`: use when records can change and you need upsert behavior.
    - `delete+insert`: use when merge is unavailable or when you want to rewrite a partition or key range.
  - **Additional concepts**:
    - `is_incremental()`: controls whether the incremental filter or merge source conditions run.
    - `unique_key`: required for `merge` and helpful for ensuring idempotent behavior.
    - `full_refresh`: can still be used to rebuild incremental models from scratch when needed.
  - **Interview Cross-Questions**:
    - What is the difference between `append` and `merge` incremental strategies?
    - When would you use `delete+insert` instead of `merge`?
    - How does `unique_key` influence incremental behavior?
    - What are the risks of using append-only incremental loads?
    - How do you handle schema changes in incremental models?" 

### Question 20: How to add an "updated at" timestamp in dbt models?
- **Question**: I want an "updated at" timestamp to know when it was last updated, how to do that?
- **Context**: Adding audit timestamps to track when records were last processed or updated in dbt models, especially useful for incremental loads and data lineage.
- **Answer**:
  - In dbt, you can add timestamp columns to track when records were last updated. This is commonly done for audit trails, incremental load tracking, and data freshness monitoring.
  - **Common approaches**:
    1. **Add a static timestamp column** in your SELECT statement.
    2. **Use dbt variables** like `run_started_at` or `invocation_id` for run-specific tracking.
    3. **Conditional timestamps** based on incremental vs full refresh.
    4. **Database-specific functions** for current timestamp.
- **Examples**:
  - **Basic updated_at column** (Snowflake example):
    ```sql
    SELECT
      id,
      name,
      price,
      CURRENT_TIMESTAMP as updated_at
    FROM {{ source('airbnb_raw', 'listings') }}
    ```
  - **Incremental-aware updated_at** (only update timestamp on incremental runs):
    ```sql
    SELECT
      id,
      name,
      price,
      {% if is_incremental() %}
        CURRENT_TIMESTAMP as updated_at
      {% else %}
        NULL as updated_at
      {% endif %}
    FROM {{ source('airbnb_raw', 'listings') }}
    ```
  - **Using dbt run variables**:
    ```sql
    SELECT
      id,
      name,
      price,
      '{{ run_started_at }}'::timestamp as dbt_run_started_at,
      '{{ invocation_id }}' as dbt_invocation_id
    FROM {{ source('airbnb_raw', 'listings') }}
    ```
  - **For incremental models with merge strategy** (update existing records):
    ```sql
    {{ config(materialized='incremental', unique_key='id', incremental_strategy='merge') }}

    SELECT
      id,
      name,
      price,
      CURRENT_TIMESTAMP as updated_at
    FROM {{ source('airbnb_raw', 'listings') }}
    {% if is_incremental() %}
      WHERE updated_at > (SELECT MAX(updated_at) FROM {{ this }})
    {% endif %}
    ```
  - **Preserve existing timestamps on merge** (don't overwrite):
    ```sql
    {{ config(materialized='incremental', unique_key='id', incremental_strategy='merge') }}

    SELECT
      s.id,
      COALESCE(t.name, s.name) as name,
      COALESCE(t.price, s.price) as price,
      CASE
        WHEN t.id IS NULL THEN CURRENT_TIMESTAMP  -- New record
        ELSE t.updated_at  -- Preserve existing timestamp
      END as updated_at
    FROM {{ source('airbnb_raw', 'listings') }} s
    LEFT JOIN {{ this }} t ON s.id = t.id
    ```
- **Database-specific timestamp functions**:
  - **Snowflake**: `CURRENT_TIMESTAMP`, `SYSDATE`, `CURRENT_TIMESTAMP()`
  - **BigQuery**: `CURRENT_TIMESTAMP()`, `CURRENT_DATETIME()`
  - **Redshift**: `GETDATE()`, `CURRENT_TIMESTAMP`
  - **PostgreSQL**: `NOW()`, `CURRENT_TIMESTAMP`
- **Best practices**:
  - Use consistent naming: `updated_at`, `dbt_updated_at`, `last_modified_at`
  - Consider timezone handling: use UTC for consistency across environments
  - For incremental models, decide if you want to update timestamps only on changes or always
  - Use `invocation_id` for debugging which dbt run processed the record
- **Interview Cross-Questions**:
  - What's the difference between `run_started_at` and `CURRENT_TIMESTAMP`?
  - How would you handle timezone differences in updated_at timestamps?
  - When should you preserve existing timestamps vs always updating them?
  - How do you use `invocation_id` for debugging data issues?
  - What's the impact of adding timestamps to large incremental tables?

### Question 21: Why isn't my new column appearing in incremental models?
- **Question**: The additional column I added (`snowflake_load_time`) is not getting reflected in Snowflake for my incremental model.
- **Context**: Troubleshooting schema changes in incremental dbt models, especially when adding new columns to existing incremental tables.
- **Code Example**:
  ```sql
  {{ config(materialized='incremental',
        unique_key='BOOKING_ID',
        incremental_strategy='merge') }}

  select *,
          current_timestamp() as snowflake_load_time
  from {{ source('staging', 'bookings') }}

  {% if is_incremental() %}
  where CREATED_AT >= (
      select coalesce(max(CREATED_AT), cast('1900-01-01' as timestamp))
      from {{ this }}
  )
  {% endif %}
  ```
- **Root Cause**:
  - **Incremental models don't automatically add new columns** during incremental runs. dbt only processes the rows that match your incremental condition, but doesn't modify the table schema.
  - When using `incremental_strategy='merge'`, dbt generates a MERGE statement that only updates existing columns. New columns are ignored unless the table schema is updated.
- **Solutions**:
  1. **Full refresh** (rebuilds the entire table):
     ```bash
     dbt run --models bronze_bookings --full-refresh
     ```
     - This drops and recreates the table with the new column.
     - Use when you want to start fresh or when schema changes are significant.
     
  2. **Configure schema change handling**:
     ```sql
     {{ config(materialized='incremental',
           unique_key='BOOKING_ID',
           incremental_strategy='merge',
           on_schema_change='append_new_columns') }}
     ```
     - `append_new_columns`: Automatically adds new columns to the table during incremental runs.
     - `fail`: Fails the run if schema changes are detected (default behavior).
     - `ignore`: Ignores schema changes (not recommended).
     
  3. **Manual table alteration** (if you can't do full refresh):
     - First, add the column manually in Snowflake:
       ```sql
       ALTER TABLE your_database.your_schema.bronze_bookings 
       ADD COLUMN snowflake_load_time TIMESTAMP;
       ```
     - Then run your incremental model - it will populate the new column for new/updated rows.
     
  4. **For append-only incremental** (if merge isn't needed):
     - Switch to `incremental_strategy='append'` if you don't need upserts.
     - New columns will be added automatically since dbt just inserts new rows.
- **Best Practices**:
  - **Always test schema changes** in development before production.
  - **Use `on_schema_change='append_new_columns'`** for incremental models that frequently add columns.
  - **Document schema changes** in your dbt project for team awareness.
  - **Consider full refresh frequency** - don't do it too often in production.
- **Interview Cross-Questions**:
  - What does `on_schema_change` do in incremental models?
  - When should you use `--full-refresh` vs `on_schema_change`?
  - How does dbt handle schema changes differently in merge vs append strategies?
  - What are the risks of frequent full refreshes in production?
  - How would you handle removing columns from incremental models?

### Question 21: Why isn't my new column appearing in incremental models? (Continued)
- **Additional Solution - Manual Table Drop**:
  - **What you did**: Dropped the table in Snowflake manually, then ran `dbt run`.
  - **Why it works**: When the target table doesn't exist, dbt treats it as a "first run" and creates the table with the full schema from your model, including new columns.
  - **Result**: The `snowflake_load_time` column should now appear in your table.
  - **Note**: This is essentially a manual full refresh. The table will be rebuilt from scratch with all current data from your source.
- **Prevention for Future**:
  - Add `on_schema_change='append_new_columns'` to your config to handle new columns automatically:
    ```sql
    {{ config(materialized='incremental',
          unique_key='BOOKING_ID',
          incremental_strategy='merge',
          on_schema_change='append_new_columns') }}
    ```
  - This way, you won't need to drop tables or do full refreshes for schema changes.

### Question 22: What is upsert and how is it implemented in dbt?
- **Question**: What is upsert? How is it implemented in dbt?
- **Context**: Understanding upsert semantics for incremental loading and merge operations in dbt.
- **Answer**:
  - **Upsert** is a combination of "update" and "insert". It means: if a record already exists, update it; if it does not exist, insert it.
  - **Why upsert matters**: It ensures that your target table reflects the latest state from the source without creating duplicates for existing keys.
- **dbt implementation**:
  - In dbt, upsert behavior is usually implemented with `incremental_strategy='merge'` and a `unique_key`.
  - dbt generates a `MERGE` statement for supported adapters like Snowflake, BigQuery, Redshift, SQL Server, and others.
  - The `unique_key` tells dbt how to match source rows to target rows.
- **Example**:
  ```sql
  {{ config(
      materialized='incremental',
      unique_key='BOOKING_ID',
      incremental_strategy='merge'
  ) }}

  SELECT
    BOOKING_ID,
    GUEST_ID,
    CREATED_AT,
    STATUS,
    CURRENT_TIMESTAMP() as snowflake_load_time
  FROM {{ source('staging', 'bookings') }}
  {% if is_incremental() %}
    WHERE CREATED_AT >= (
      SELECT COALESCE(MAX(CREATED_AT), CAST('1900-01-01' AS TIMESTAMP))
      FROM {{ this }}
    )
  {% endif %}
  ```
  - This model will insert new rows and update existing rows based on `BOOKING_ID`.
- **How dbt generates merge logic**:
  - dbt uses the selected adapter to create a database-specific `MERGE` statement.
  - The source rows are the incremental result set, and the target is `{{ this }}`.
  - On match, dbt updates the target columns; on no match, dbt inserts the new row.
- **Best practice**:
  - Use a stable and unique `unique_key` field.
  - Add `on_schema_change='append_new_columns'` if the schema may evolve.
  - Validate that your source filter only produces rows that should be inserted/updated.
- **Interview Cross-Questions**:
  - What is the difference between insert, update, and upsert?
  - Why is `unique_key` important for merge-based incremental models?
  - How does dbt handle upsert on adapters that do not support merge?
  - When would you use append strategy instead of merge/upsert?
  - How do you test that your upsert logic is correctly updating existing rows?

### Question 23: Is this Jinja macro correct?
- **Question**: Is the `tag(col)` macro correct?
- **Context**: Reviewing and improving a custom Jinja macro for categorizing values in dbt.
- **Code Review**:
  ```jinja
  {% macro tag(col)%}
      {% if int(col) < 100%}
          'Low'
      {% elif int(col) < 200%}
          'Medium'
      {% else %}
          'High'
      {% endif %}
  {% endmacro%}
  ```
- **Analysis**:
  - **Syntax**: The macro syntax is mostly correct. The logic categorizes values: < 100 = 'Low', 100-199 = 'Medium', >= 200 = 'High'.
  - **Potential Issues**:
    1. **NULL handling**: If `col` is NULL, `int(col)` will fail. Add null check.
    2. **Type conversion**: `int(col)` assumes `col` is a string/number. If `col` is already numeric, this works; if string, it converts.
    3. **Error handling**: No protection against non-numeric values.
- **Improved Version**:
  ```jinja
  {% macro tag(col) %}
      {% if col is none %}
          NULL
      {% elif col | int < 100 %}
          'Low'
      {% elif col | int < 200 %}
          'Medium'
      {% else %}
          'High'
      {% endif %}
  {% endmacro %}
  ```
  - **Changes**:
    - Added `{% if col is none %}` to handle NULL values.
    - Used `col | int` (Jinja filter) instead of `int(col)` for safer conversion.
    - Returns `NULL` for null inputs instead of failing.
- **Usage Example**:
  ```sql
  SELECT
    booking_id,
    price,
    {{ tag('price') }} as price_category
  FROM {{ ref('bronze_bookings') }}
  ```
  - **Note**: When calling the macro, pass the column name as a string `'price'`, not as a variable `price`.
- **Testing the Macro**:
  - Create a simple test model:
    ```sql
    SELECT
      {{ tag('100') }} as test_100,  -- Should return 'Medium'
      {{ tag('50') }} as test_50,    -- Should return 'Low'
      {{ tag('250') }} as test_250   -- Should return 'High'
    ```
  - Run `dbt compile` to check for syntax errors.
- **Interview Cross-Questions**:
  - How do you handle NULL values in Jinja macros?
  - What's the difference between `int(col)` and `col | int` in Jinja?
  - How do you test custom macros in dbt?
  - When should you use macros vs case statements in SQL?
  - How do you handle type conversion errors in Jinja?

### Question 24: Does Jinja convert strings to 0 when casting to integer?
- **Question**: Do Jinja converts strings to 0 while casting to integer?
- **Context**: Understanding type conversion behavior in Jinja, especially when using the `| int` filter with invalid or non-numeric strings.
- **Answer**:
  - **Short answer**: No, Jinja does NOT silently convert strings to 0. It depends on the string content.
  - **Behavior**:
    - **Numeric strings** (e.g., '100', '50'): Converted successfully to integer. Result: `100`, `50`.
    - **Non-numeric strings** (e.g., 'abc', 'price'): Jinja raises an error or returns a default value depending on the filter.
    - **Empty string** (''): Typically converts to 0 or raises an error.
    - **Mixed strings** (e.g., '100abc'): Typically fails to convert.
- **Examples**:
  ```jinja
  {# Numeric string - works #}
  {{ '100' | int }}  --> 100
  
  {# Non-numeric string - error or default #}
  {{ 'abc' | int }}  --> Error OR 0 (depending on Jinja version)
  
  {# Empty string #}
  {{ '' | int }}  --> 0
  
  {# String with whitespace #}
  {{ '  100  ' | int }}  --> 100 (trims whitespace)
  ```
- **Safe conversion with default**:
  - Use `| int(default=0)` to provide a default fallback:
    ```jinja
    {{ 'abc' | int(default=0) }}  --> 0
    {{ '100' | int(default=0) }}  --> 100
    ```
- **Handling in dbt macros**:
  - **Unsafe** (can error):
    ```jinja
    {% macro add(col1, col2) %}
        {{ col1 | int }} + {{ col2 | int }}
    {% endmacro %}
    ```
  - **Safe** (with default fallback):
    ```jinja
    {% macro add(col1, col2) %}
        {{ col1 | int(default=0) }} + {{ col2 | int(default=0) }}
    {% endmacro %}
    ```
  - **Safest** (with null and error handling):
    ```jinja
    {% macro add(col1, col2) %}
        {% set c1 = col1 | int(default=0) if col1 is not none else 0 %}
        {% set c2 = col2 | int(default=0) if col2 is not none else 0 %}
        {{ c1 }} + {{ c2 }}
    {% endmacro %}
    ```
- **Real-world impact**:
  - If a column value is NULL or contains 'N/A', your macro will fail unless you handle it.
  - Always add error handling for user-provided or source data.
- **Testing**:
  - Test your macros with edge cases: NULL, empty strings, non-numeric values.
  - Use `dbt compile` or `dbt run` to check for Jinja errors.
- **Interview Cross-Questions**:
  - What happens if you use `| int` on a NULL value?
  - How do you provide a default value for failed type conversions?
  - What's the difference between `| int` and `| int(default=0)` in Jinja?
  - When would silent conversion to 0 be dangerous in a data pipeline?
  - How do you validate input types in dbt macros before converting?

### Question 25: How to run only a single model in dbt?
- **Question**: How to run only a single model in dbt?
- **Context**: Running specific dbt models during development, testing, or debugging without running the entire project.
- **Answer**:
  - Use the `--models` (or `-m`) flag with `dbt run` to select specific models.
  - dbt will automatically run the selected model's dependencies (upstream models) unless you disable that.
- **Basic Command**:
  ```bash
  dbt run --models model_name
  # or shorter
  dbt run -m model_name
  ```
- **Examples**:
  - **Run a single model by name**:
    ```bash
    dbt run --models bronze_bookings
    ```
    - This runs `bronze_bookings.sql` and all its dependencies (e.g., the source it references).
  
  - **Run a model in a specific folder**:
    ```bash
    dbt run --models bronze  # Runs all bronze models
    dbt run --models silver.silver_listings  # Runs specific model with folder path
    ```
  
  - **Run a model without dependencies** (new in dbt v0.20+):
    ```bash
    dbt run --models bronze_bookings --exclude-dependencies
    ```
    - Runs only the selected model, skipping upstream dependencies.
  
  - **Run multiple models** (comma-separated or multiple -m flags):
    ```bash
    dbt run --models bronze_bookings,bronze_listings
    dbt run -m bronze_bookings -m bronze_listings
    ```
  
  - **Run with tag selector**:
    ```bash
    dbt run --models tag:daily
    ```
    - Runs all models tagged with 'daily' in their config.
  
  - **Run model and its downstream dependents**:
    ```bash
    dbt run --models bronze_bookings+
    ```
    - The `+` means "and all models that depend on this model".
  
  - **Run model and upstream** (full lineage):
    ```bash
    dbt run --models +bronze_bookings+
    ```
    - Runs bronze_bookings and all models it depends on, plus all downstream models.
- **Common Development Workflows**:
  - **Quick test of a single model**:
    ```bash
    dbt run --models my_new_model --exclude-dependencies
    dbt docs generate
    ```
  
  - **Test after changes to a source**:
    ```bash
    dbt run --models source:staging  # Runs models using staging source
    ```
  
  - **Test a model and its downstream**:
    ```bash
    dbt run --models silver_bookings+
    ```
- **Useful flags with single model runs**:
  - `--exclude-dependencies`: Skip running upstream models.
  - `--full-refresh`: Force a full refresh (useful for incremental models).
  - `--debug`: Show detailed execution logs.
  - `--fail-fast`: Stop on first error.
  - `--select` (alias for `--models`): Alternative syntax.
- **Interview Cross-Questions**:
  - What's the difference between `dbt run -m model` and `dbt run -m model+`?
  - How do you run a model without its dependencies?
  - What does the `+` selector mean in dbt?
  - When would you use tags to select models instead of specific names?
  - How do you test a single incremental model with full refresh?

### Question 26: What are dbt-utils?
- **Question**: What are dbt-utils?
- **Context**: Understanding the dbt-utils package, a collection of reusable macros and tests that enhance dbt functionality.
- **Answer**:
  - **dbt-utils** is a package of reusable Jinja macros and SQL functions maintained by the dbt community that extend dbt's capabilities.
  - It provides common data transformations, tests, and utilities that would otherwise require custom macro writing.
  - Must be installed as a dependency in your `packages.yml` file.
- **Installation**:
  - Add to `packages.yml`:
    ```yaml
    packages:
      - package: dbt-labs/dbt_utils
        version: 1.1.1  # Use latest stable version
    ```
  - Run:
    ```bash
    dbt deps
    ```
- **Common dbt-utils macros**:
  1. **`surrogate_key(column_list)`** - Generate a surrogate key by hashing column values:
     ```sql
     SELECT
       {{ dbt_utils.surrogate_key(['id', 'source']) }} as key,
       name, price
     FROM {{ ref('bookings') }}
     ```
  
  2. **`star(from, except=[])`** - Select all columns except specified ones:
     ```sql
     SELECT
       {{ dbt_utils.star(ref('bronze_listings'), except=['sensitive_col', 'internal_id']) }}
     FROM {{ ref('bronze_listings') }}
     ```
  
  3. **`get_column_values(table, column)`** - Get distinct values from a column (useful for dynamic filtering):
     ```jinja
     {% set status_values = dbt_utils.get_column_values(table=ref('bookings'), column='status') %}
     SELECT * FROM {{ ref('bookings') }}
     WHERE status IN ({{ status_values | join(', ') }})
     ```
  
  4. **`group_by(n)`** - Group by first N columns (useful when you have many columns):
     ```sql
     SELECT col1, col2, col3, COUNT(*) as cnt
     FROM {{ ref('listings') }}
     GROUP BY {{ dbt_utils.group_by(3) }}
     ```
  
  5. **`unpivot()`** - Convert columns to rows (pivot longer):
     ```sql
     SELECT *
     FROM {{ dbt_utils.unpivot(
       relation=ref('sales_wide'),
       cast_to='string',
       exclude=['year', 'quarter'],
       field_name='metric',
       value_name='amount'
     ) }}
     ```
  
  6. **`generate_series(start, end)`** - Generate a series of numbers or dates:
     ```sql
     SELECT {{ dbt_utils.generate_series(1, 100) }} as num
     ```
  
  7. **`safe_cast(column, type)`** - Safely cast without errors on invalid values:
     ```sql
     SELECT
       {{ dbt_utils.safe_cast('price', api.Column.String) }} as price_str
     FROM {{ ref('listings') }}
     ```
- **Common dbt-utils tests**:
  - `dbt_utils.equality_test`: Compares two model outputs.
  - `dbt_utils.expression_is_true`: Validates a SQL expression.
  - `dbt_utils.recency`: Checks if data is recent (no stale data).
- **Example: Using star() with except in a model**:
  ```sql
  {{ config(materialized='table') }}

  SELECT
    {{ dbt_utils.star(ref('bronze_bookings'), except=['internal_id', 'test_col']) }},
    CURRENT_TIMESTAMP() as dbt_load_time
  FROM {{ ref('bronze_bookings') }}
  ```
- **Why use dbt-utils**:
  - Saves time writing common transformations.
  - Provides best practices and tested code.
  - Reduces code duplication across models.
  - Makes code more maintainable and readable.
- **Interview Cross-Questions**:
  - How do you install and use dbt-utils in your project?
  - When would you use `surrogate_key()` vs a natural key?
  - What's the difference between `star()` and `select *`?
  - How does `unpivot()` differ from `pivot()`?
  - What are common dbt-utils tests and how do you use them?

### Question 27: What are metadata-driven pipelines?
- **Question**: What are metadata-driven pipelines?
- **Context**: Understanding a design pattern where pipeline behavior is controlled by metadata rather than hardcoded logic, enabling scalability and flexibility in data engineering.
- **Answer**:
  - **Metadata-driven pipelines** are data pipelines where the transformation logic and execution behavior are controlled by metadata (configuration, usually in YAML, JSON, or CSV) rather than hardcoded code.
  - Instead of writing separate transformation logic for each table, you define metadata that describes how data should flow and be transformed.
  - The pipeline engine reads the metadata and executes transformations dynamically.
- **Key Concept**:
  - Traditional approach: Hard-code each model separately in SQL.
  - Metadata-driven approach: Define metadata once, apply to multiple tables or scenarios.
- **Benefits**:
  - **Scalability**: Add new data sources without writing new code.
  - **Reduced code duplication**: Reuse transformation patterns.
  - **Easier maintenance**: Update rules in one place.
  - **Lower learning curve**: Non-technical users can manage pipelines via metadata.
  - **Consistency**: Ensures uniform handling of similar data types.
- **Example: dbt-based metadata-driven pipeline**:
  - **Metadata YAML** (centralizes transformation rules):
    ```yaml
    tables:
      - name: bookings
        source: staging
        materialization: incremental
        unique_key: booking_id
        incremental_column: created_at
        exclude_columns: [internal_id, test_col]
        
      - name: listings
        source: staging
        materialization: table
        exclude_columns: [sensitive_data]
      
      - name: reviews
        source: staging
        materialization: incremental
        unique_key: review_id
        incremental_column: updated_at
    ```
  
  - **Generic Jinja macro** (processes any table based on metadata):
    ```jinja
    {% macro generate_model_from_metadata(table_config) %}
      {{ config(
        materialized=table_config.materialization,
        unique_key=table_config.unique_key if table_config.materialization == 'incremental' else none
      ) }}

      SELECT
        {{ dbt_utils.star(
          from=source(table_config.source, table_config.name),
          except=table_config.exclude_columns
        ) }}
      FROM {{ source(table_config.source, table_config.name) }}
      
      {% if table_config.materialization == 'incremental' %}
        WHERE {{ table_config.incremental_column }} >= (
          SELECT COALESCE(MAX({{ table_config.incremental_column }}), '1900-01-01'::timestamp)
          FROM {{ this }}
        )
      {% endif %}
    {% endmacro %}
    ```
  
  - **Model file** (uses macro with metadata):
    ```sql
    {%- set table_config = {
      'name': 'bookings',
      'source': 'staging',
      'materialization': 'incremental',
      'unique_key': 'booking_id',
      'incremental_column': 'created_at',
      'exclude_columns': ['internal_id', 'test_col']
    } -%}

    {{ generate_model_from_metadata(table_config) }}
    ```
- **Real-world example**:
  - **Without metadata-driven**: Write 50 similar models for 50 tables.
  - **With metadata-driven**: Write 1 generic macro + 50 lightweight model files that call it with different configs.
- **Metadata sources**:
  - YAML files (dbt sources, properties).
  - CSV/JSON configuration files.
  - Database tables (audit tables with transformation rules).
  - Environment variables.
- **Advanced use cases**:
  - Dynamic model generation: Create models at runtime based on metadata.
  - Automation of bronze/silver layer: Auto-generate bronze models from source definitions.
  - Testing rules: Define test expectations as metadata.
  - Data quality checks: Store thresholds and validation rules in metadata.
- **Challenges**:
  - Requires careful metadata design upfront.
  - Debugging is harder when logic is abstracted.
  - Not suitable for highly custom transformations.
- **Interview Cross-Questions**:
  - What's the difference between metadata-driven and code-driven pipelines?
  - When would you use metadata-driven pipelines vs hardcoded models?
  - How do you manage metadata versions in a metadata-driven pipeline?
  - What tools support metadata-driven data pipelines?
  - How do you debug issues in a metadata-driven pipeline?

### Question 28: What are snapshots in dbt?
- **Question**: What are snapshots?
- **Context**: Understanding dbt snapshots for capturing and tracking historical state changes in slowly changing dimensions (SCD Type 2).
- **Answer**:
  - **Snapshots** are a dbt feature that records the history of records over time by capturing their state at specific points.
  - They track changes to dimension records (e.g., when a customer's address or status changes).
  - Snapshots create a Type 2 Slowly Changing Dimension (SCD) table with effective and expiration dates.
  - Unlike incremental models that append only new records, snapshots track row-level changes.
- **Why snapshots matter**:
  - Track historical data for compliance and auditing.
  - Enable temporal queries (e.g., "what was the customer's address on 2025-01-15?").
  - Create a complete audit trail of dimension changes.
- **How snapshots work**:
  1. dbt compares source records with the previous snapshot state.
  2. Records that changed get a new version with updated `dbt_valid_from` and `dbt_valid_to` dates.
  3. Unchanged records are carried forward unchanged.
  4. Only changed records are inserted (efficient incremental approach).
- **Snapshot syntax**:
  ```sql
  {% snapshot snapshot_name %}
    {{
      config(
        target_schema='snapshots',
        unique_key='id',
        strategy='timestamp',
        updated_at='updated_at'
      )
    }}

    SELECT id, name, email, address, updated_at
    FROM {{ source('raw', 'customers') }}

  {% endsnapshot %}
  ```
- **Key parameters**:
  - `unique_key`: Column(s) that uniquely identify a record.
  - `strategy`: How to detect changes: `timestamp` or `check`.
  - `updated_at`: Timestamp column (for `timestamp` strategy).
  - `check_cols`: Columns to monitor for changes (for `check` strategy).
  - `target_schema`: Where to store snapshot tables.
- **Strategies**:
  1. **Timestamp strategy** (recommended):
     ```sql
     {{
       config(
         target_schema='snapshots',
         unique_key='customer_id',
         strategy='timestamp',
         updated_at='last_modified'
       )
     }}

     SELECT * FROM {{ source('raw', 'customers') }}
     ```
     - dbt compares the `last_modified` timestamp with the previous snapshot.
     - Simple and efficient for sources that have an `updated_at` column.

  2. **Check strategy** (all columns or specific ones):
     ```sql
     {{
       config(
         target_schema='snapshots',
         unique_key='customer_id',
         strategy='check',
         check_cols=['name', 'email', 'address']
       )
     }}

     SELECT * FROM {{ source('raw', 'customers') }}
     ```
     - dbt hashes the specified columns and compares hashes.
     - Use when no timestamp column exists.
- **Snapshot output columns**:
  - All source columns.
  - `dbt_valid_from`: When this version became valid.
  - `dbt_valid_to`: When this version expired (NULL for current version).
  - `dbt_scd_id`: Unique identifier for each version.
  - `dbt_updated_at`: Timestamp of snapshot run.
- **Example: Tracking customer changes**:
  - **Snapshot file** (`snapshots/customers_snapshot.sql`):
    ```sql
    {% snapshot customers_snapshot %}
      {{
        config(
          target_schema='snapshots',
          unique_key='customer_id',
          strategy='timestamp',
          updated_at='updated_at'
        )
      }}

      SELECT
        customer_id,
        name,
        email,
        address,
        status,
        updated_at
      FROM {{ source('raw', 'customers') }}
    {% endsnapshot %}
    ```

  - **Using snapshot in downstream model**:
    ```sql
    SELECT
      customer_id,
      name,
      address,
      dbt_valid_from,
      dbt_valid_to,
      CASE
        WHEN dbt_valid_to IS NULL THEN 'Current'
        ELSE 'Historical'
      END as record_status
    FROM {{ ref('customers_snapshot') }}
    ORDER BY customer_id, dbt_valid_from DESC
    ```

  - **Temporal query** (address on specific date):
    ```sql
    SELECT
      customer_id,
      name,
      address
    FROM {{ ref('customers_snapshot') }}
    WHERE dbt_valid_from <= '2025-01-15'::date
      AND (dbt_valid_to IS NULL OR dbt_valid_to > '2025-01-15'::date)
    ```
- **Running snapshots**:
  ```bash
  dbt snapshot                    # Run all snapshots
  dbt snapshot -m customers_snapshot  # Run specific snapshot
  dbt snapshot --full-refresh    # Rebuild entire snapshot table
  ```
- **Best practices**:
  - Use `timestamp` strategy when available (more efficient).
  - Snapshot dimension tables, not facts (facts are append-only).
  - Run snapshots regularly (daily recommended).
  - Document what changes you're tracking.
  - Use snapshots for SCD Type 2 scenarios.
- **Limitations**:
  - Snapshots only track row changes, not column additions/removals.
  - Not ideal for high-volume fact tables (too many rows to snapshot).
  - Requires unique key to identify records.
- **Interview Cross-Questions**:
  - What's the difference between snapshots and incremental models?
  - When would you use timestamp strategy vs check strategy?
  - How do you query a snapshot to get data from a specific point in time?
  - What's the difference between SCD Type 1 and Type 2?
  - Can you snapshot a fact table? Why or why not?

### Question 29: What are ephemeral models in dbt?
- **Question**: What are ephemeral models in dbt?
- **Context**: Understanding ephemeral materialization for creating reusable logic without materializing intermediate tables/views in the database.
- **Answer**:
  - **Ephemeral models** are dbt models that are NOT materialized as tables or views in the database.
  - Instead, they exist only as CTEs (Common Table Expressions) that are inlined into dependent models.
  - They are like helper or intermediate logic that gets compiled into the SQL of downstream models.
  - Useful for code reuse without cluttering the database with intermediate tables.
- **When to use ephemeral models**:
  - Shared logic that multiple models depend on but don't need to persist.
  - Intermediate calculations or transformations.
  - Staging/cleaning logic that feeds directly into final models.
  - To reduce database objects and improve query performance.
- **Syntax**:
  ```sql
  {{ config(materialized='ephemeral') }}

  SELECT
    id,
    name,
    UPPER(city) as city,
    price * 1.1 as price_with_tax
  FROM {{ source('raw', 'listings') }}
  ```
- **Example workflow**:
  - **Ephemeral model** (`stg_listings.sql`):
    ```sql
    {{ config(materialized='ephemeral') }}

    SELECT
      id,
      name,
      UPPER(city) as city,
      price,
      created_at
    FROM {{ source('raw', 'listings') }}
    WHERE created_at IS NOT NULL
    ```

  - **Downstream model** (`dim_listings.sql`):
    ```sql
    {{ config(materialized='table') }}

    SELECT
      id,
      name,
      city,
      price,
      created_at,
      CURRENT_TIMESTAMP() as load_time
    FROM {{ ref('stg_listings') }}
    WHERE price > 100
    ```

  - **Compiled SQL** (what dbt actually runs in Snowflake):
    ```sql
    CREATE TABLE dim_listings AS
    WITH stg_listings AS (
      SELECT
        id,
        name,
        UPPER(city) as city,
        price,
        created_at
      FROM raw.listings
      WHERE created_at IS NOT NULL
    )
    SELECT
      id,
      name,
      city,
      price,
      created_at,
      CURRENT_TIMESTAMP() as load_time
    FROM stg_listings
    WHERE price > 100
    ```
- **Key difference from table/view**:
  - **Table**: Created and stored in database, slower for small datasets.
  - **View**: Created in database, executable separately, less performant if chain of views.
  - **Ephemeral**: NOT created in database, inlined as CTE, more performant for small logic.
- **Advantages**:
  - **No database clutter**: Intermediate tables/views not created.
  - **Better performance**: CTEs are optimized by the database engine.
  - **Code reuse**: Share logic across models without materializing.
  - **Lower storage**: No persistence needed for temporary logic.
- **Disadvantages**:
  - **Can't be queried directly**: Ephemeral models don't exist in the database to query independently.
  - **Scalability**: For complex logic used by many models, materializing might be better.
  - **Testing**: Harder to test ephemeral models independently (no table to query).
- **Best practices**:
  - Use ephemeral for simple, lightweight transformations.
  - Use tables for logic that is reused by many downstream models (avoid recompiling).
  - Use views when you need the object to be queryable but don't need persistence.
  - Start with ephemeral; materialize to table only if performance analysis shows it's needed.
- **Real-world example**:
  ```sql
  {# Ephemeral: Staging model for data cleaning #}
  {{ config(materialized='ephemeral') }}
  
  SELECT
    booking_id,
    guest_id,
    COALESCE(price, 0) as price,
    CASE WHEN status IN ('confirmed', 'completed') THEN status ELSE 'unknown' END as status,
    created_at
  FROM {{ source('staging', 'bookings') }}
  WHERE created_at >= '2025-01-01'

  {# Table: Fact model that uses the ephemeral staging #}
  {{ config(materialized='table') }}
  
  SELECT
    booking_id,
    guest_id,
    price,
    status,
    created_at,
    CURRENT_DATE() as load_date
  FROM {{ ref('stg_bookings') }}  {# Ephemeral model is inlined here #}
  ```
- **Checking materialization type**:
  - Use `{{ this.type }}` in a model to see its materialization.
  - Ephemeral models will show as 'ephemeral' (not materialized).
- **When to NOT use ephemeral**:
  - For models that are queried frequently by analysts (they won't exist).
  - For performance-critical logic used by many downstream models (materialize to avoid recompiling).
  - For models that need to be tested or validated independently.
- **Materialization hierarchy** (from most to least persistent):
  - **table**: Materialized, stored, queryable, high storage cost.
  - **view**: Not stored, queryable, recomputed on each query.
  - **incremental**: Like table but only new/changed rows (most efficient for large data).
  - **ephemeral**: Not materialized, inlined as CTE, lowest storage, only used internally.
- **Interview Cross-Questions**:
  - What's the difference between ephemeral and view materialization?
  - Why would you use ephemeral instead of a table or view?
  - Can you query an ephemeral model directly? Why or why not?
  - When should you materialize an ephemeral model to a table?
  - How does dbt compile ephemeral models?

### Question 30: How can snapshots be used with YAML and macros?
- **Question**: How can snapshots be used using YAML and macros?
- **Context**: Implementing metadata-driven snapshots using YAML configuration and generic macros for scalable dimension tracking.
- **Answer**:
  - Instead of writing individual snapshot files for each dimension, you can define snapshot metadata in YAML and use a generic macro to generate snapshots.
  - This approach scales well when you have many dimension tables to snapshot.
  - Combines metadata-driven pipelines with snapshots for maximum reusability.
- **Architecture**:
  1. Define snapshot metadata in a YAML file (table names, unique keys, strategies, etc.).
  2. Create a generic macro that reads metadata and generates snapshot SQL.
  3. Snapshot files call the macro with different metadata configs.
- **Step 1: Define snapshot metadata in YAML**:
  - Create `snapshots_config.yml` (or similar):
    ```yaml
    snapshots:
      - name: customers_snapshot
        source_table: customers
        source_name: raw
        target_schema: snapshots
        unique_key: customer_id
        strategy: timestamp
        updated_at_column: updated_at
        description: "Tracks customer profile changes"
        
      - name: listings_snapshot
        source_table: listings
        source_name: raw
        target_schema: snapshots
        unique_key: listing_id
        strategy: check
        check_cols: [name, host_id, price, address]
        description: "Tracks listing changes"
        
      - name: hosts_snapshot
        source_table: hosts
        source_name: raw
        target_schema: snapshots
        unique_key: host_id
        strategy: timestamp
        updated_at_column: updated_at
        description: "Tracks host profile changes"
    ```

- **Step 2: Create a generic macro for snapshots**:
  - Create `macros/generate_snapshot.sql`:
    ```jinja
    {% macro generate_snapshot_from_metadata(snapshot_config) %}
      {%- set strategy_config = {
        'target_schema': snapshot_config.target_schema,
        'unique_key': snapshot_config.unique_key,
        'strategy': snapshot_config.strategy
      } -%}

      {%- if snapshot_config.strategy == 'timestamp' -%}
        {%- set strategy_config = strategy_config | combine({'updated_at': snapshot_config.updated_at_column}) -%}
      {%- elif snapshot_config.strategy == 'check' -%}
        {%- set strategy_config = strategy_config | combine({'check_cols': snapshot_config.check_cols}) -%}
      {%- endif -%}

      {{
        config(**strategy_config)
      }}

      SELECT *
      FROM {{ source(snapshot_config.source_name, snapshot_config.source_table) }}
    {% endmacro %}
    ```

- **Step 3: Create snapshot files using the macro**:
  - Create `snapshots/customers_snapshot.sql`:
    ```sql
    {%- set snapshot_config = {
      'name': 'customers_snapshot',
      'source_table': 'customers',
      'source_name': 'raw',
      'target_schema': 'snapshots',
      'unique_key': 'customer_id',
      'strategy': 'timestamp',
      'updated_at_column': 'updated_at'
    } -%}

    {% snapshot customers_snapshot %}
      {{ generate_snapshot_from_metadata(snapshot_config) }}
    {% endsnapshot %}
    ```

  - Create `snapshots/listings_snapshot.sql`:
    ```sql
    {%- set snapshot_config = {
      'name': 'listings_snapshot',
      'source_table': 'listings',
      'source_name': 'raw',
      'target_schema': 'snapshots',
      'unique_key': 'listing_id',
      'strategy': 'check',
      'check_cols': ['name', 'host_id', 'price', 'address']
    } -%}

    {% snapshot listings_snapshot %}
      {{ generate_snapshot_from_metadata(snapshot_config) }}
    {% endsnapshot %}
    ```

- **Advanced: Loading metadata from external YAML**:
  - Use dbt's `var()` to pass metadata:
    ```sql
    {%- set all_snapshots = var('snapshots_config') -%}
    {%- set snapshot_config = all_snapshots | selectattr('name', 'equalto', 'customers_snapshot') | list | first -%}

    {% snapshot customers_snapshot %}
      {{ generate_snapshot_from_metadata(snapshot_config) }}
    {% endsnapshot %}
    ```

  - Pass via `--vars` or `dbt_project.yml`:
    ```yaml
    vars:
      snapshots_config:
        - name: customers_snapshot
          source_table: customers
          source_name: raw
          unique_key: customer_id
          strategy: timestamp
          updated_at_column: updated_at
        
        - name: listings_snapshot
          source_table: listings
          source_name: raw
          unique_key: listing_id
          strategy: check
          check_cols: [name, host_id, price]
    ```

- **Benefits of YAML + Macro approach**:
  - **DRY principle**: Define snapshot logic once, reuse across tables.
  - **Easy maintenance**: Update rules in YAML, not in individual SQL files.
  - **Scalability**: Add 100 new snapshots by just adding 100 lines to YAML.
  - **Consistency**: All snapshots follow the same pattern.
  - **Documentation**: Metadata serves as documentation.

- **Example: Full workflow**:
  1. Add new dimension to snapshot metadata in YAML:
     ```yaml
     - name: bookings_snapshot
       source_table: bookings
       source_name: raw
       unique_key: booking_id
       strategy: timestamp
       updated_at_column: updated_at
     ```
  
  2. Create minimal snapshot file:
     ```sql
     {%- set cfg = var('snapshots_config') | selectattr('name', 'equalto', 'bookings_snapshot') | list | first -%}
     {% snapshot bookings_snapshot %}
       {{ generate_snapshot_from_metadata(cfg) }}
     {% endsnapshot %}
     ```
  
  3. Run snapshot:
     ```bash
     dbt snapshot
     ```

- **Advanced macro with validation**:
  ```jinja
  {% macro generate_snapshot_from_metadata(config) %}
    {%- if config.unique_key is not defined -%}
      {{ exceptions.raise_compiler_error("Snapshot config missing unique_key: " ~ config.name) }}
    {%- endif -%}

    {%- if config.strategy not in ['timestamp', 'check'] -%}
      {{ exceptions.raise_compiler_error("Invalid strategy: " ~ config.strategy) }}
    {%- endif -%}

    {%- set strategy_config = {
      'target_schema': config.target_schema or 'snapshots',
      'unique_key': config.unique_key,
      'strategy': config.strategy
    } -%}

    {%- if config.strategy == 'timestamp' -%}
      {%- if config.updated_at_column is not defined -%}
        {{ exceptions.raise_compiler_error("Timestamp strategy requires updated_at_column") }}
      {%- endif -%}
      {%- set strategy_config = strategy_config | combine({'updated_at': config.updated_at_column}) -%}
    {%- endif -%}

    {{ config(**strategy_config) }}
    SELECT * FROM {{ source(config.source_name, config.source_table) }}
  {% endmacro %}
  ```

- **Interview Cross-Questions**:
  - Why combine YAML and macros for snapshots?
  - How do you validate snapshot metadata in a macro?
  - When would you hardcode snapshots vs use metadata-driven approach?
  - How do you handle different snapshot strategies in a generic macro?
  - Can you use Jinja loops to generate multiple snapshots from YAML metadata?

### Question 31: What is seeding in dbt?
- **Question**: What is seeding in dbt?
- **Context**: Understanding dbt seed files, which load static CSV data into the warehouse as tables.
- **Answer**:
  - **Seeding** is the process of loading CSV files from your dbt project's `data/` directory into your data warehouse as tables.
  - Seed files are treated as source data that dbt manages alongside your models.
  - Use seeds for small reference datasets, lookup tables, configuration data, or static lists that your models need.
- **How seeding works**:
  1. Place CSV files in the `data/` folder of your dbt project.
  2. Define seed configuration in `dbt_project.yml` if you need custom settings.
  3. Run `dbt seed` to load the CSV files into your warehouse.
  4. Reference seed tables in models using `{{ ref('seed_name') }}`.
- **Basic command**:
  ```bash
  dbt seed
  ```
- **Run a single seed file**:
  ```bash
  dbt seed --select my_seed_file
  ```
- **Example CSV** (`data/country_codes.csv`):
  ```csv
  country_code,country_name,continent
  US,United States,North America
  IN,India,Asia
  GB,United Kingdom,Europe
  ```
- **Example model using seed**:
  ```sql
  SELECT
    b.booking_id,
    b.country_code,
    s.country_name,
    s.continent
  FROM {{ ref('bronze_bookings') }} b
  LEFT JOIN {{ ref('country_codes') }} s
    ON b.country_code = s.country_code
  ```
- **Seed configuration in `dbt_project.yml`**:
  ```yaml
  seeds:
    my_project:
      country_codes:
        file: data/country_codes.csv
        quote_columns: false
        header: true
        delimiter: ','
      +column_types:
        country_code: varchar
        country_name: varchar
        continent: varchar
  ```
- **Why use seeds**:
  - Load tiny, static datasets without building a full extraction pipeline.
  - Store lookup tables, country codes, type mappings, or default values.
  - Keep reference data version-controlled in the dbt repo.
- **Best practices**:
  - Use seeds only for small, stable datasets.
  - Avoid large CSVs; prefer raw source tables for heavy data.
  - Configure column types if you need strict schema control.
  - Document seed contents and intended use.
- **Interview Cross-Questions**:
  - What is the difference between seeds and sources in dbt?
  - When should you use a seed file versus a regular model?
  - How do you configure seed column types in dbt?
  - Can you use `dbt seed` in a production workflow?
  - How do you version-control seed data?

### Question 32: What are tags in tests?
- **Question**: What are tags in test?
- **Context**: Understanding how dbt tags are used to organize and execute tests selectively.
- **Answer**:
  - In dbt, **tags** are metadata labels you can attach to models, tests, seeds, snapshots, and macros.
  - For tests, tags allow you to group tests by purpose, severity, team, data domain, or release wave.
  - Tags make it easy to run only a subset of tests instead of all tests in the project.
- **How tags work with tests**:
  - Add tags in YAML test definitions or model config blocks.
  - Run tests by tag using the `--select` or `--models` flag with `tag:` selector.
- **Example: Tagging tests in YAML**:
  ```yaml
  models:
    - name: bronze_bookings
      columns:
        - name: booking_id
          tests:
            - not_null:
                tags: ['critical', 'booking']
            - unique:
                tags: ['critical', 'booking']
        - name: created_at
          tests:
            - not_null:
                tags: ['timestamp', 'bronze']
  ```
- **Example: Tagging generic tests**:
  ```yaml
  tests:
    - dbt_utils.expression_is_true:
        args:
          expression: "status IN ('confirmed', 'cancelled', 'pending')"
        tags: ['business-rule', 'booking']
  ```
- **Running tests by tag**:
  ```bash
  dbt test --select tag:critical
  dbt test --select tag:booking
  dbt test --select tag:business-rule
  ```
- **Benefits**:
  - **Selective execution**: Run only high-priority or domain-specific tests.
  - **Faster CI**: Run critical tags on every PR and full test suite nightly.
  - **Better organization**: Group tests by team, data domain, or test type.
  - **Easier debugging**: Isolate a failing tag group rather than all tests.
- **Tagging in model config**:
  - You can also add tags at the model level, and tests inherit them.
    ```yaml
    models:
      - name: bronze_bookings
        tags: ['bronze', 'booking']
    ```
  - Then running `dbt test --select tag:booking` includes tests on that model.
- **Interview Cross-Questions**:
  - How do you use tags to structure test execution in CI?
  - What is the difference between model tags and test tags?
  - Can tags be used with `dbt run` as well as `dbt test`?
  - When would you tag a test as `critical` vs `optional`?
  - How do tags help in maintaining a large dbt project?
