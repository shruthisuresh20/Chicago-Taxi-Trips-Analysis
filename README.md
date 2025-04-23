# City of Chicago Taxi Trips Analysis (2024)

##  Project Overview

This project analyzes over **6.4 million taxi trips** from the City of Chicago in 2024. The objective is to extract actionable insights that:

- Uncover patterns in trip frequency, duration, and fare variability
- Optimize dispatching and pricing strategies
- Enhance urban mobility and rider experience
- Provide a BI dashboard to support strategic decision-making

---

## Data Pipeline Architecture

### 🔍 1. Extraction
- Raw dataset from taxi meters integrated with GPS and POS systems
- Timeframe: Full calendar year 2024 (AM + PM trips)
- Format: CSV files

### 🧪 2. Transformation
- Data cleaning using Python (Pandas, NumPy)
- Handled missing values, standardized timestamps
- Removed outliers using IQR method
- Feature engineered `trip hour`, `payment category`, and `trip type`

### 🧩 3. Loading
- Data loaded into **MySQL** using a **Star Schema**:
  - `taxi_trips_fact` – trip metrics
  - `time_dim`, `location_dim`, `company_dim` – supporting dimensions
- Optimized for OLAP queries and Tableau dashboard integration

### 🔁 4. Incremental Updates
- Monthly batch updates using Python + SQLAlchemy + cron job
- Prevents duplicate data and improves processing time

---

##  Key Insights

- **Peak Hours**: 7–10 AM & 4–8 PM show highest demand
- **Short Trips** dominate, most under 5 miles and 20 minutes
- **Credit Cards** are the most common payment method
- **O’Hare Airport** is a major pickup/drop-off hub
- **Tips** peak at night and vary by fare & passenger count

---

##  Tableau Dashboard

Includes:
- Revenue by time and community area (Roll-up)
- Driver-level performance by company (Drill-down)
- Night drop-offs by location (Slice)
- Average fare by hour and geography (Dice)
- Tips vs Fare by passenger count (Pivot)



## 🛠 Technologies Used

| Area                | Tools & Frameworks                     |
|---------------------|----------------------------------------|
| Data Cleaning       | Python, Pandas, NumPy                  |
| Database            | MySQL (Star Schema, Indexing)          |
| ETL Automation      | SQL, SQLAlchemy, Cron                  |
| Visualization       | Tableau                                |
| Design & Modeling   | Lucidchart                             |
| Notebooks           | Jupyter                                |

---




