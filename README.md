# dbt-airbnb-project

A comprehensive data engineering project using dbt (Data Build Tool) to build an Airbnb data warehouse on Snowflake with AWS S3 integration.

## 📋 Project Overview

This project demonstrates modern data engineering practices by building a complete Airbnb data pipeline. It transforms raw Airbnb data into a structured, analytics-ready data warehouse using dbt's transformation capabilities.

## 🏗️ Architecture

The project follows a **medallion architecture** with three layers:

### Bronze Layer (Raw Data)
- **Purpose**: Raw, minimally processed data from sources
- **Materialization**: Incremental models with merge strategy
- **Features**:
  - Data ingestion from S3 via Snowflake storage integration
  - Basic data type casting and null handling
  - Incremental loading with timestamp-based filtering
  - Audit columns (load timestamps)

### Silver Layer (Cleaned & Enriched)
- **Purpose**: Cleaned, standardized, and enriched data
- **Materialization**: Tables and views
- **Features**:
  - Data quality checks and validation
  - Business logic application
  - Dimension table creation
  - Fact table preparation

### Gold Layer (Analytics-Ready)
- **Purpose**: Final analytics and reporting layer
- **Materialization**: Views and ephemeral models
- **Features**:
  - Aggregated metrics and KPIs
  - Business intelligence ready datasets
  - Optimized for query performance

## 🛠️ Technologies Used

- **dbt (Data Build Tool)**: Data transformation and modeling
- **Snowflake**: Cloud data warehouse
- **AWS S3**: Data lake storage
- **Jinja2**: Templating for dynamic SQL generation
- **YAML**: Configuration and metadata management
- **Git**: Version control

## ✨ Key Features

### 🔄 Incremental Loading
- Efficient data processing with incremental models
- Merge-based upserts for dimension tables
- Timestamp-based change detection
- Automatic schema evolution handling

### 📊 Data Quality & Testing
- Comprehensive test suite with dbt tests
- Data validation rules and constraints
- Tag-based test organization for selective execution
- Custom macros for business rule validation

### 🔧 Advanced dbt Patterns
- **Ephemeral Models**: Reusable transformation logic without materialization
- **Snapshots**: Type 2 Slowly Changing Dimensions for historical tracking
- **Macros**: Custom Jinja functions for complex logic
- **Seeds**: Static reference data management
- **Metadata-Driven Pipelines**: YAML-configured transformations

### 📈 Analytics & Reporting
- Dimension and fact table design
- Business metric calculations
- Temporal analysis capabilities
- Audit trail and data lineage

## 🚀 Getting Started

### Prerequisites
- Python 3.8+
- dbt-core and dbt-snowflake
- Snowflake account with appropriate permissions
- AWS account with S3 access

### Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd dbt-airbnb-project
   ```

2. **Create virtual environment**:
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   ```

3. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Install dbt packages**:
   ```bash
   dbt deps
   ```

### Configuration

1. **Set up Snowflake connection** in `profiles.yml`:
   ```yaml
   airbnb_project:
     target: dev
     outputs:
       dev:
         type: snowflake
         account: your-account.snowflakecomputing.com
         user: your-user
         password: your-password
         role: your-role
         database: your-database
         warehouse: your-warehouse
         schema: dev
   ```

2. **Configure AWS S3 integration** in Snowflake (if not already done):
   - Create storage integration
   - Grant necessary permissions
   - Create external stages

### Running the Project

1. **Test connection**:
   ```bash
   dbt debug
   ```

2. **Load seed data**:
   ```bash
   dbt seed
   ```

3. **Run models**:
   ```bash
   dbt run
   ```

4. **Run tests**:
   ```bash
   dbt test
   ```

5. **Generate documentation**:
   ```bash
   dbt docs generate
   dbt docs serve
   ```

### Selective Execution

Run specific models or test groups:
```bash
# Run only bronze layer models
dbt run --models bronze

# Run critical tests only
dbt test --select tag:critical

# Run a single model
dbt run --models silver_bookings

# Run models and their downstream dependencies
dbt run --models bronze_bookings+
```

## 📁 Project Structure

```
dbt-airbnb-project/
├── aws_dbt_snowflake_airbnb_project/
│   ├── models/
│   │   ├── bronze/          # Raw data layer
│   │   ├── silver/          # Cleaned data layer
│   │   └── gold/            # Analytics layer
│   ├── snapshots/           # SCD Type 2 tracking
│   ├── seeds/               # Static reference data
│   ├── macros/              # Custom Jinja functions
│   ├── tests/               # Data quality tests
│   ├── dbt_project.yml      # Project configuration
│   └── profiles.yml         # Connection profiles
├── data/                    # CSV files for seeds
├── project.md               # Detailed technical notes
├── pyproject.toml           # Python dependencies
└── README.md               # This file
```

## 📚 Documentation

For detailed technical documentation, see [`project.md`](project.md), which contains:

- Comprehensive explanations of dbt concepts
- Code examples and patterns
- Interview preparation questions
- Troubleshooting guides
- Best practices and advanced techniques

## 🔍 Key Concepts Covered

- **Incremental Models**: Efficient data loading strategies
- **Materialization Types**: Tables, views, incremental, ephemeral
- **Jinja Templating**: Dynamic SQL generation
- **Snapshots**: Historical data tracking
- **Macros**: Reusable code blocks
- **Testing**: Data quality assurance
- **Metadata-Driven Pipelines**: YAML-configured transformations
- **Tags**: Selective execution and organization

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Run the full test suite
6. Submit a pull request

## 📄 License

This project is for educational purposes. Please check with your organization for licensing requirements.

## 🙋 Support

For questions or issues:
1. Check the [`project.md`](project.md) documentation
2. Review dbt documentation at [docs.getdbt.com](https://docs.getdbt.com)
3. Open an issue in the repository

---

**Built with ❤️ using dbt, Snowflake, and AWS**