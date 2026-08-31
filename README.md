# Credit Card Fraud Detection & Analysis

An analysis of ~39,900 credit card transactions to identify patterns behind fraudulent activity, combining SQL, Python, Excel, and Tableau across the full pipeline — from raw data to an interactive dashboard.

Fraud in this dataset is a rare-event problem: only **~0.58%** of transactions are fraudulent (a ~190:1 class imbalance), which shapes every decision below, from how missing values are handled to which metrics can be trusted.

## Key Findings

- **Fraud concentrates in specific conditions**, not evenly across the data — it skews toward higher transaction amounts and clusters in card-not-present categories like online shopping (`misc_net`).
- **Timing matters**: late-night and early-morning transactions carry a higher *rate* of fraud than daytime activity.
- **Geography is a strong signal**: fraudulent transactions tend to occur at a greater distance between the cardholder's home location and the merchant, compared to legitimate ones.
- **Outliers aren't errors here**: unusually large transaction amounts are mostly legitimate high-value purchases, and disproportionately where fraud losses concentrate — they shouldn't be filtered out.
- **Class imbalance drives everything downstream**: with fraud at under 1% of transactions, accuracy is a misleading metric. Precision, recall, F1, and AUC-PR are used instead, and any future model would need explicit imbalance handling (class weighting, SMOTE, or threshold tuning).

## Repository Structure

```
├── data/
│   ├── cc_data.csv                    # Transaction-level data (~39,900 rows)
│   ├── cc_data_metadata.csv           # Data dictionary
│   ├── location_data.csv              # cc_num → lat/long lookup
│   └── location_data_metadata.csv     # Data dictionary
│
├── sql/
│   └── financial_fraud_detection_analysis.sql             # Schema setup + exploration/aggregation queries
│
├── notebooks/
│   ├── fraud_detection.ipynb          # EDA: distributions, correlations, missing values
│   └── fraude_detection_eda_report.md                  # Written findings & modeling recommendations
│
├── excel/
│   └── financial_fraud_detection_project.xlsx  # Summary stats, histograms, category/gender breakdowns
│
└── dashboards/
    └── Credit Card Fraud Detection & Analysis.twbx # Interactive Tableau workbook
```


## Dataset

Each row is a single credit card transaction with:
- **Transaction details**: amount, category, merchant, timestamp
- **Cardholder info**: gender, job, date of birth, home address, city population
- **Geolocation**: cardholder and merchant lat/long
- **Label**: `is_fraud` (1 = fraudulent, 0 = legitimate)

## Approach

**SQL** — Loaded the transaction and location data into a relational schema and answered core business questions: transaction volume, top merchants, category-level spend, fraud rate, and demographic/geographic breakdowns.

**Python (EDA)** — Profiled the dataset's shape, distributions, and missing values, then dug into what separates fraud from legitimate activity across amount, category, time, and location. Full write-up in `notebooks/eda_report.md`, covering:
- Dataset structure and data quality
- Univariate distributions (`amt` and `city_pop` are both heavily right-skewed)
- Fraud-specific patterns by amount, category, time, and geography
- Outlier treatment (why they were kept, not trimmed)
- Correlation analysis and its implication for model choice (tree-based models likely outperform linear ones here)
- Concrete next steps for a modeling phase

**Excel** — Quick-reference statistical summaries and visual breakdowns: distribution of `amt`, fraud counts by gender/category, transaction volume by state, and the relationship between city population and spend.

**Tableau** — An interactive dashboard combining:
- Spend distribution by gender and category (box-and-whisker)
- Geographic scatter of all transactions
- A map isolating fraudulent transaction locations
- Monthly transaction volume trend
- An inflation-adjusted transaction amount calculation, tracked weekly

## Running This Yourself

1. **SQL**: Load `cc_data.csv` and `location_data.csv` into a MySQL-compatible database, then run `sql/financial_fraud_detection_analysis.sql`.
2. **Python**: Open `notebooks/fraud_detection.ipynb` in Jupyter (`pandas`, `numpy`, `matplotlib`, `seaborn`, `scipy`) with `cc_data.csv` in the expected data path.
3. **Excel**: Open `excel/financial_fraud_detection_project.xlsx` directly — no setup required.
4. **Tableau**: Open `dashboards/Credit Card Fraud Detection & Analysis.twbx` in Tableau Desktop, Reader, or Public.

## Next Steps

- Engineer cardholder-to-merchant distance and time-of-day features explicitly, rather than relying on raw lat/long and timestamps.
- Log-transform `city_pop` given its skew.
- Train a tree-based classifier (Random Forest / XGBoost / LightGBM) as the primary candidate, with logistic regression as an interpretable baseline.
- Address class imbalance directly via class weighting, resampling (SMOTE/undersampling), or threshold tuning — and evaluate exclusively on precision, recall, F1, and AUC-PR.
