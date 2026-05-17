# 🛍️ Olist E-Commerce dbt Project

A end-to-end data modelling project using the [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) from Kaggle. Raw data is loaded into **Snowflake** and transformed using **dbt Cloud** following a layered modelling approach.

---

## 📦 Tech Stack

| Tool | Purpose |
|---|---|
| **Kaggle** | Source dataset |
| **Snowflake** | Cloud data warehouse |
| **dbt Cloud** | Data transformation & modelling |
| **Git** | Version control |

---

## 🗂️ Project Structure

```
olist_dbt/
├── models/
│   ├── staging/
│   │   ├── sources.yml              # Source definitions pointing to raw Snowflake tables
│   │   ├── schema.yml               # Staging model tests & documentation
│   │   ├── stg_customers.sql
│   │   ├── stg_orders.sql
│   │   ├── stg_order_items.sql
│   │   ├── stg_order_payments.sql
│   │   ├── stg_order_reviews.sql
│   │   ├── stg_products.sql
│   │   └── stg_sellers.sql
│   └── marts/
│       ├── schema.yml               # Mart model tests & documentation
│       ├── fct_orders.sql           # Fact table — one row per order
│       ├── dim_customers.sql        # Customer dimension with lifetime metrics
│       └── dim_products.sql         # Product dimension with sales metrics
├── tests/
│   ├── assert_positive_payment_value.sql
│   ├── assert_positive_order_price.sql
│   ├── assert_delivery_after_purchase.sql
│   └── assert_review_score_range.sql
├── dbt_project.yml
└── README.md
```

---

## 🗃️ Dataset Overview

The Olist dataset contains anonymised orders placed on the Brazilian e-commerce platform between 2016 and 2018. It consists of 9 tables covering the full order lifecycle.

### Raw Tables (loaded into `OLIST.RAW`)

| Table | Description | Rows (approx.) |
|---|---|---|
| `CUSTOMER_DATASET` | Customer IDs, city, state, zip code | 99,441 |
| `ORDERS_DATASET` | Order status, timestamps, delivery dates | 99,441 |
| `ORDER_ITEM_DATASET` | Items per order, product, seller, price | 112,650 |
| `ORDER_PAYMENTS_DATASET` | Payment type, installments, value | 103,886 |
| `ORDER_REVIEWS_DATASET` | Review scores and comments | 99,224 |
| `PRODUCTS_DATASET` | Product category, dimensions, weight | 32,951 |
| `SELLERS_DATASET` | Seller location details | 3,095 |
| `GEOLOCATION_DATASET` | Zip code to lat/lng mapping | 1,000,163 |
| `PRODUCT_CATEGORY_NAME` | Portuguese to English category translations | 71 |

---

## 🏗️ Data Architecture

This project follows the **3-layer dbt modelling pattern**:

```
┌─────────────────────────────────────────────────────────┐
│  SOURCE LAYER  (OLIST.RAW)                              │
│  Raw CSVs loaded directly from Kaggle into Snowflake    │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│  STAGING LAYER  (dbt_<user>_staging)                    │
│  - Rename columns to snake_case                         │
│  - Cast data types (timestamps, floats, ints)           │
│  - Light cleaning, no business logic                    │
│  - Materialised as VIEWS                                │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│  MARTS LAYER  (dbt_<user>_marts)                        │
│  - Business-ready models                                │
│  - Joins across staging models                          │
│  - Aggregations and derived metrics                     │
│  - Materialised as TABLES                               │
└─────────────────────────────────────────────────────────┘
```

---

## 📊 Data Models

### Staging Models

| Model | Source Table | Description |
|---|---|---|
| `stg_customers` | `CUSTOMER_DATASET` | Cleaned customer records |
| `stg_orders` | `ORDERS_DATASET` | Orders with cast timestamps |
| `stg_order_items` | `ORDER_ITEM_DATASET` | Line items with price as float |
| `stg_order_payments` | `ORDER_PAYMENTS_DATASET` | Payment records per order |
| `stg_order_reviews` | `ORDER_REVIEWS_DATASET` | Reviews with score as int |
| `stg_products` | `PRODUCTS_DATASET` + `PRODUCT_CATEGORY_NAME` | Products with English category names |
| `stg_sellers` | `SELLERS_DATASET` | Seller location data |

### Mart Models

#### `fct_orders` — Fact Table
One row per order. Central model joining orders, items, payments and reviews.

| Column | Description |
|---|---|
| `order_id` | Primary key |
| `customer_id` | FK to dim_customers |
| `order_status` | Current order status |
| `order_purchase_timestamp` | When the order was placed |
| `order_delivered_customer_date` | Actual delivery date |
| `order_estimated_delivery_date` | Estimated delivery date |
| `actual_delivery_days` | Days from purchase to delivery |
| `estimated_delivery_days` | Days from purchase to estimated delivery |
| `total_items` | Number of items in order |
| `total_price` | Sum of item prices |
| `total_freight` | Sum of freight values |
| `total_payment` | Total payment value |
| `payment_count` | Number of payment transactions |
| `review_score` | Customer review score (1–5) |

#### `dim_customers` — Customer Dimension
One row per customer with aggregated lifetime metrics.

| Column | Description |
|---|---|
| `customer_id` | Primary key |
| `customer_unique_id` | Unique customer identifier across orders |
| `customer_city` | City |
| `customer_state` | State |
| `total_orders` | Lifetime order count |
| `lifetime_value` | Total spend across all orders |
| `avg_review_score` | Average review score given |
| `first_order_date` | Date of first order |
| `last_order_date` | Date of most recent order |

#### `dim_products` — Product Dimension
One row per product with aggregated sales metrics.

| Column | Description |
|---|---|
| `product_id` | Primary key |
| `category` | English product category name |
| `product_weight_g` | Product weight in grams |
| `total_orders` | Number of times ordered |
| `total_revenue` | Total revenue generated |
| `avg_price` | Average selling price |

---

## 🧪 Testing

### Schema Tests (Generic)

| Test | Models Applied To |
|---|---|
| `unique` | All primary keys |
| `not_null` | All primary and foreign keys |
| `accepted_values` | `order_status`, `review_score` |

### Singular Tests (Custom)

| Test File | What It Checks |
|---|---|
| `assert_positive_payment_value` | No negative payment values |
| `assert_positive_order_price` | No zero or negative item prices |
| `assert_delivery_after_purchase` | Delivery date not before purchase date |
| `assert_review_score_range` | Review scores only between 1 and 5 |

### Run Tests
```bash
# Run all tests
dbt test

# Run tests for a specific model
dbt test --select fct_orders

# Run only staging tests
dbt test --select staging

# Run only mart tests
dbt test --select marts
```

---

## 🚀 Getting Started

### Prerequisites
- Snowflake account (Enterprise or Trial)
- dbt Cloud account (Developer free tier)
- Olist dataset downloaded from Kaggle

### Step 1 — Load Raw Data into Snowflake
```sql
-- Create database and schema
CREATE DATABASE OLIST;
CREATE SCHEMA OLIST.RAW;

-- Load each CSV via Snowflake UI:
-- Databases → OLIST → RAW → Load Data → Upload CSV
```

### Step 2 — Connect dbt Cloud to Snowflake
```
Account     →  <your-org>-<your-account>
Username    →  <your-snowflake-username>
Password    →  <your-snowflake-password>
Role        →  ACCOUNTADMIN
Warehouse   →  COMPUTE_WH
Database    →  OLIST
Schema      →  RAW
```

### Step 3 — Run dbt
```bash
# Install dependencies
dbt deps

# Run all models
dbt run

# Run tests
dbt test

# Run models and tests together
dbt build
```

---

## ⚙️ dbt Project Configuration

```yaml
# dbt_project.yml
models:
  dbt_snowflake_project:
    staging:
      +schema: staging
      +materialized: view
    marts:
      +schema: marts
      +materialized: table
```

---

## 📈 Example SQL Queries

### Total Revenue by Month
```sql
SELECT
    DATE_TRUNC('month', order_purchase_timestamp) AS order_month,
    SUM(total_payment) AS monthly_revenue,
    COUNT(order_id) AS total_orders
FROM fct_orders
WHERE order_status = 'delivered'
GROUP BY 1
ORDER BY 1;
```

### Top 10 Customers by Lifetime Value
```sql
SELECT
    customer_unique_id,
    customer_state,
    total_orders,
    ROUND(lifetime_value, 2) AS lifetime_value
FROM dim_customers
ORDER BY lifetime_value DESC
LIMIT 10;
```

### Average Delivery Days by State
```sql
SELECT
    c.customer_state,
    ROUND(AVG(o.actual_delivery_days), 1) AS avg_delivery_days,
    COUNT(o.order_id) AS total_orders
FROM fct_orders o
JOIN dim_customers c ON o.customer_id = c.customer_id
WHERE o.actual_delivery_days IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC;
```

---

## 🔗 Resources

- [Olist Dataset on Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- [dbt Documentation](https://docs.getdbt.com)
- [Snowflake Documentation](https://docs.snowflake.com)
- [dbt Best Practices](https://docs.getdbt.com/guides/best-practices)

---

## 👤 Author

**Dhinesh** — Data Engineering Practice Project  
 - LinkedIN Profile (https://www.linkedin.com/in/dhinesh-c-rajan/)
 - Portfolio URL (https://dhineshcr.github.io)
 - Github Profile (https://github.com/DhineshCR)

Built to practice end-to-end data modelling with dbt Cloud + Snowflake.
