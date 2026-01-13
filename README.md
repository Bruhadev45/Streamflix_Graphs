# StreamFlix Product Analyst - Technical Assessment

## Overview

This repository contains the complete analysis toolkit for the StreamFlix Product Analyst Technical Assessment, including SQL queries (Section 2) and a Jupyter Notebook for data visualization.

---

## Repository Contents

| File | Description |
|------|-------------|
| `streamflix_queries.sql` | 5 SQL queries for Section 2: SQL Proficiency |
| `StreamFlix_Analysis.ipynb` | Jupyter Notebook with 10 visualizations |
| `streamflix_sessions.csv` | Sample dataset |
| `README.md` | This documentation |

---

## Dataset Description

**Period:** January - June 2024  
**Records:** 80,000 sessions across 5,000 users

| Field | Type | Description |
|-------|------|-------------|
| `user_id` | VARCHAR | Unique user identifier |
| `session_date` | DATE | Date of viewing session |
| `minutes_watched` | INTEGER | Duration of session in minutes |
| `content_type` | VARCHAR | Type: `movie`, `tv_show`, `documentary` |
| `device_type` | VARCHAR | Platform: `mobile`, `web`, `tv` |
| `subscription_tier` | VARCHAR | Plan: `basic`, `standard`, `premium` |

---

## Section 2: SQL Proficiency (`streamflix_queries.sql`)

### 5 Core Assessment Queries

| # | Query Name | Purpose |
|---|------------|---------|
| 1 | **MoM Growth Rate** | Calculate month-over-month growth in total minutes watched |
| 2 | **Top 10 Engaged Users** | Identify power users using composite engagement score |
| 3 | **Content Performance** | Find content with high watch time but low completion |
| 4 | **Cohort Retention** | Track user retention by signup month cohort |
| 5 | **Downgrade Detection** | Identify users who downgraded with decreased engagement |

### Query Details

**Query 1 - MoM Growth Rate:**
- Uses `LAG()` window function
- Calculates percentage change between consecutive months
- Identifies growth trends and seasonal patterns

**Query 2 - Engagement Score Formula:**
```
Score = (Total Minutes × 0.5) + (Session Count × 10) + (Content Variety × 20)
```

**Query 3 - Content Performance:**
- Identifies content with above-average watch time but below-average completion
- Flags "HIGH WATCH / LOW COMPLETION" for optimization

**Query 4 - Cohort Retention:**
- Groups users by first activity month
- Calculates % retained in subsequent months
- Outputs retention matrix for heatmap visualization

**Query 5 - Downgrade Detection:**
- Detects tier changes: premium → standard → basic
- Flags users with simultaneous engagement decline
- Supports retention campaign targeting

### Database Compatibility

| Database | Status |
|----------|--------|
| PostgreSQL | ✅ Fully compatible |
| MySQL | ⚠️ Minor syntax changes needed |
| SQLite | ⚠️ Limited window function support |
| BigQuery | ✅ Compatible with minor adjustments |
| Snowflake | ✅ Fully compatible |

---

## Jupyter Notebook (`StreamFlix_Analysis.ipynb`)

### Requirements

```bash
pip install pandas numpy matplotlib seaborn
```

### 10 Charts Generated

| # | Chart Name | Type | Description |
|---|------------|------|-------------|
| 1 | Monthly Trends | 4-Panel Grid | MAU, total minutes, avg session, sessions/user |
| 2 | Device & Content | 4-Panel Grid | Pie charts + bar charts for distribution |
| 3 | Subscription Tiers | 3-Panel Bar | Users, avg minutes, sessions by tier |
| 4 | Device Trends | Stacked Area | Watch time by device over 6 months |
| 5 | Engagement Heatmap | Heatmap | Device × Content average minutes matrix |
| 6 | MoM Growth Rate | Bar Chart | Monthly growth percentage (+/-) |
| 7 | Metrics Framework | Diagram | Watch Party feature metrics structure |
| 8 | Financial Model | Dual Chart | Investment vs cumulative returns comparison |
| 9 | Cohort Retention | Heatmap | Retention % by cohort and month |
| 10 | TAM/SAM/SOM | Concentric Circles | Market size visualization |

### How to Run

1. **Install dependencies**
```bash
pip install pandas numpy matplotlib seaborn
```

2. **Place the CSV file**
Ensure `streamflix_sessions.csv` is in the same directory as the notebook.

3. **Run the notebook**
```bash
jupyter notebook StreamFlix_Analysis.ipynb
```

4. **Execute all cells**
- Click `Kernel` → `Restart & Run All`
- Or run cells individually with `Shift + Enter`

### Notebook Structure

```
StreamFlix_Analysis.ipynb
│
├── 1. Setup & Data Loading
│   ├── Import libraries
│   ├── Load CSV data
│   └── Data preprocessing
│
├── 2. Chart 1: Monthly Engagement Trends
├── 3. Chart 2: Device & Content Analysis
├── 4. Chart 3: Subscription Tier Comparison
├── 5. Chart 4: Device Usage Over Time
├── 6. Chart 5: Engagement Heatmap
├── 7. Chart 6: MoM Growth Rate
├── 8. Chart 7: Metrics Framework
├── 9. Chart 8: Financial Model
├── 10. Chart 9: Cohort Retention
└── 11. Chart 10: TAM/SAM/SOM
```

### Output Files

All charts are saved as PNG files:
```
chart1_monthly_trends.png
chart2_device_content.png
chart3_subscription_tiers.png
chart4_device_trends.png
chart5_heatmap.png
chart6_mom_growth.png
chart7_metrics_framework.png
chart8_financial_model.png
chart9_cohort_retention.png
chart10_tam_sam.png
```

---

## Setup Instructions

### PostgreSQL Setup

```bash
# Create database
createdb streamflix

# Run schema and queries
psql streamflix < streamflix_queries.sql
```

### Import CSV Data

```sql
COPY sessions(user_id, session_date, minutes_watched, content_type, device_type, subscription_tier)
FROM '/path/to/streamflix_sessions.csv'
DELIMITER ','
CSV HEADER;
```

---

## Troubleshooting

### Notebook Issues

| Issue | Solution |
|-------|----------|
| `ModuleNotFoundError` | Run `pip install pandas matplotlib seaborn numpy` |
| `FileNotFoundError` for CSV | Ensure CSV is in same directory as notebook |
| Charts not displaying | Add `%matplotlib inline` at top of notebook |

### SQL Issues

| Issue | Solution |
|-------|----------|
| Window function error | Ensure PostgreSQL 9.4+ or compatible DB |
| Date function error | Adjust `DATE_TRUNC` syntax for your DB |

---

## File Structure

```
streamflix-analysis/
├── streamflix_queries.sql      # 5 SQL queries (Section 2)
├── StreamFlix_Analysis.ipynb   # Jupyter Notebook (10 charts)
├── streamflix_sessions.csv     # Dataset
├── README.md                   # Documentation
└── output/
    └── *.png                   # Generated chart images
```

---
