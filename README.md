# employee_sqlproject

# Employee Analytics Project

## Overview

This project analyzes employee data to uncover insights on workforce demographics, salary trends, department transfers, and gender pay gaps. The dataset is sourced from a publicly available dataset hosted on GitHub and adapted from a sample employee database originally created by Fusheng Wang and Carlo Zaniolo.

SQL queries were developed to extract key metrics and relationships. Power BI was used to build interactive dashboards for data visualization.

---

## Dataset Attribution

- **Original Authors**: Fusheng Wang and Carlo Zaniolo  
  [TimeCenter Software](http://www.cs.aau.dk/TimeCenter/software.htm)  
  [Dataset ZIP Download](http://www.cs.aau.dk/TimeCenter/Data/employeeTemporalDataSet.zip)

- **Schema Adaptation**: Giuseppe Maxia  
- **Data Conversion**: Patrick Crews

> Licensed under Creative Commons Attribution-Share Alike 3.0 Unported License  
> http://creativecommons.org/licenses/by-sa/3.0/

⚠️ This dataset is **entirely fictional** and does not represent real individuals. Any similarities are purely coincidental.

---

## Dataset Structure

The database includes the following tables:

- `employees` – Employee personal details  
- `salaries` – Salary history records  
- `departments` – Department information  
- `dept_emp` – Employee department assignments  
- `dept_manager` – Department managers  
- `titles` – Job titles held by employees

Note: Active records use `to_date = '9999-01-01'`.

---

## SQL Queries

Key analytical queries include:

- ✅ **Active Managers** – Age, tenure, and department of current managers  
- ✅ **Gender Contributions** – Gender distribution across departments  
- ✅ **Top 10 Highest Salaries** – Current highest-paid employees  
- ✅ **Top 3 Salaries per Department** – Salary rankings within departments  
- ✅ **Salary Growth Trends** – Employees with notable salary increases  
- ✅ **Gender Pay Gap** – Average salaries by gender and role  
- ✅ **Post-1980 Entry Salaries** – Highest entry salaries by job/department  
- ✅ **Employee Transfer Frequency** – Staff who moved across departments  
- ✅ **Department Summary** – Employee count and salary distribution

📂 See the `queries/` folder or `sql_queries.sql` file for all scripts.

---

## Visualizing in Power BI

1. Connect Power BI Desktop to your SQL server/database.
2. Import SQL query results into Power BI.
3. Create visuals using:
   - Column/bar charts
   - Slicers for gender, department, year
   - KPI cards for salary averages and counts
4. Customize dashboards for HR reporting.
5. Optionally, schedule automatic data refresh.

---

## How to Run

### 1. Clone this Repository

```bash
git clone https://github.com/<your-username>/<repo-name>.git
cd <repo-name>
