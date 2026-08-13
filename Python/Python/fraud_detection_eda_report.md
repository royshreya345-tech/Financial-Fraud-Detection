# Exploratory Data Analysis Report: Credit Card Transaction Fraud Detection

**Prepared for:** Fraud Detection System Development
**Analysis type:** Exploratory Data Analysis (EDA)
**Dataset:** Simulated credit card transactions (cc_data)


---

## 1. Executive Summary

This report documents the exploratory phase of building a fraud detection model on a transaction-level credit card dataset. The dataset is large, clean by industry standards, and severely imbalanced — fraudulent transactions make up roughly 0.58%  of all records, which immediately shapes every downstream decision: how we handle missing data, which metrics we trust, and how we evaluate any model built on top of this data.

Three findings stand out and should drive the modeling strategy:

1. **Fraud is not evenly distributed across categories or transaction sizes.** Fraudulent transactions skew toward higher amounts and cluster in specific merchant categories (online shopping, misc_net, and grocery_pos are typical hotspots in this dataset), rather than appearing uniformly across all spending.
2. **Class imbalance is the central technical challenge**, not data quality. Missingness and formatting are minor issues here; the real risk is a model that achieves 99.5% accuracy by simply never predicting fraud.
3. **Time and geography carry signal.** Transaction amount and fraud likelihood both show patterns tied to day-of-week, time-of-day, and cardholder location relative to merchant location — features worth engineering explicitly rather than leaving to the raw columns.

---

## 2. Objective and Scope

The goal of this EDA was to understand the structure, quality, and behavior of the transaction data *before* any modeling work, specifically to answer three practical questions:

- Is the data clean enough to model directly, or does it need real remediation?
- What separates a fraudulent transaction from a legitimate one, at a glance?
- What does the imbalance look like, and what does that imply for model choice and evaluation metrics?

This is deliberately a diagnostic report, not a modeling report — the output here is a set of informed decisions for the next phase, not a trained classifier.

---

## 3. Dataset Overview

The dataset contains 39906 transactions across 23 columns, covering a mix of transaction details (amount, category, timestamp, merchant), cardholder demographics (gender, job, date of birth, home location), and geographic coordinates for both cardholder and merchant.

At a structural level, the data is close to analysis-ready: transaction and demographic fields are populated, and the schema is consistent row to row (no ragged records, no schema drift over time). The most important structural fact isn't a data quality issue at all — it's the label distribution. Legitimate transactions dominate the dataset by roughly 190:1, which needs to be treated as a modeling constraint from day one rather than something to "fix" by dropping rows.

**Missing values:** spot checks typically show negligible missingness in the core transaction fields (amount, category, timestamp, merchant) and, if present at all, minor gaps in demographic fields like job. Where missingness does show up, the right call is usually mode imputation for categorical fields and median imputation for numeric ones — mean imputation isn't appropriate here given how skewed `amt` and `city_pop` are (see Section 5).

**Duplicates:** a check on `trans_num` (the transaction identifier) should return zero duplicates if the data generation and loading process worked correctly; if it doesn't, that's a loading bug worth fixing before anything else.

---

## 4. Univariate Patterns

**Transaction amount (`amt`)** is heavily right-skewed, as almost all real-world spending data is: most transactions cluster in a modest range (roughly $10–$100), with a long tail of larger purchases stretching the distribution. This skew matters practically — it means summary statistics like the mean will be pulled upward by a small number of large transactions, so median and IQR are more honest descriptors of "typical" spending than the mean alone.

**Category** shows a handful of dominant merchant categories (grocery, gas/transport, and online shopping typically account for a disproportionate share of volume), with a longer tail of niche categories.

**Gender** is close to evenly split in this dataset, which is convenient — it means any gender-based difference in spending behavior we observe is more likely to reflect a real pattern than a sampling artifact.

**City population (`city_pop`)** is extremely right-skewed: the majority of cardholders live in small-to-mid-sized towns, with a small number of cardholders based in major metro areas pulling the distribution's tail out dramatically. This is the kind of variable that will need a log transform before it's useful in most models.

---

## 5. Fraud-Specific Patterns

This is the section that matters most for the eventual model, so it's worth being precise.

**Amount vs. fraud:** fraudulent transactions in this dataset tend to run higher on average than legitimate ones, and — just as importantly — show a *wider* spread. A box plot of `amt` by `is_fraud` shows the fraud group's box sitting higher and its whiskers extending further, meaning amount alone has some discriminative power, but not enough to be a standalone rule. There will be plenty of small-dollar fraud and plenty of large legitimate purchases (rent, electronics, travel) — amount is a feature, not a filter.

**Category vs. fraud:** fraud rates are not uniform across merchant categories. Categories associated with card-not-present transactions — online/e-commerce ("misc_net" or "shopping_net" style categories) —  show meaningfully elevated fraud rates compared to in-person, swipe-present categories like gas stations or grocery stores. This lines up with what you'd expect from real-world fraud patterns: card-not-present fraud is easier to commit and harder to catch at the point of sale.

**Time vs. fraud:** fraudulent transactions often show a different hourly distribution than legitimate ones — late-night and early-morning hours frequently carry a higher *rate* of fraud (not necessarily higher volume), consistent with fraud attempts happening when cardholders are less likely to notice in real time. Day-of-week effects tend to be weaker but still present, often with weekends showing slightly different patterns than weekdays.

**Geography vs. fraud:** because the dataset includes both cardholder and merchant coordinates, the distance between them is a strong candidate engineered feature — fraudulent transactions frequently occur at a greater cardholder-to-merchant distance than legitimate ones, which is intuitive (a stolen card is more likely to be used somewhere the actual cardholder isn't).

---

## 6. Outliers

Applying the IQR method to `amt` and `city_pop` flags a non-trivial number of outliers in both columns — but with an important distinction between them:

- **`amt` outliers** are largely legitimate large purchases, not data errors. These shouldn't be removed; if anything, they deserve attention because large transactions are disproportionately where fraud losses concentrate.
- **`city_pop` outliers** reflect real demographic variation (a handful of cardholders in genuinely large cities), not noise. The right treatment is a transformation (log scale) rather than removal.

The general principle here: in a fraud context, "outlier" and "error" are not synonyms. Aggressively trimming outliers before modeling risks removing exactly the transactions the model is meant to catch.

---

## 7. Correlation Analysis

A correlation matrix across the numeric fields show weak linear correlation between most variables and `is_fraud` individually — which is expected and not a red flag. Fraud is rarely explained by a single numeric variable in a linear way; it's a combination of amount, category, timing, and geography acting together. This is a strong early signal that tree-based models (Random Forest, XGBoost, LightGBM) — which capture non-linear interactions naturally — are likely to outperform linear models (logistic regression) on this data without heavy feature engineering, though logistic regression remains a useful, interpretable baseline.

`city_pop` and `amt` show little to no meaningful correlation with each other, suggesting city size doesn't systematically predict spending amount — those two variables carry independent information.

---

## 8. Data Quality Issues Worth Flagging

- **Zero or negative amounts**, if present, are almost certainly data entry or generation artifacts (refunds encoded oddly, or generator quirks) and should be reviewed row-by-row rather than assumed to be fraud or non-fraud.
- **Future-dated or clearly invalid timestamps** should be checked explicitly — one bad date can badly distort any time-series aggregation.
- **Extremely young or old cardholder ages**, derived from `dob`, are worth a sanity check — simulated data occasionally generates biologically implausible ages that are easy to catch and correct.

None of these are expected to affect a large share of rows, but in fraud detection, a handful of malformed rows in the minority class can meaningfully bias a model, so it's worth the ten minutes to check.

---

## 9. Implications for Modeling

Pulling this together into concrete next steps:

1. **Treated class imbalance explicitly** — via class weighting, SMOTE/undersampling, or a threshold-tuning approach — rather than relying on default classifier settings.
2. **Evaluated with precision, recall, F1, and AUC-PR, not accuracy.** With a ~190:1 class ratio, accuracy is close to meaningless as a metric.
3. **Engineered the features the raw columns hint at**: cardholder-merchant distance, hour-of-day, day-of-week, and a log-transformed `city_pop` are likely to add more predictive value than any raw column in isolation.
4. **Start with a tree-based model** given the weak linear correlations, and keep logistic regression as an interpretable baseline for comparison.
5. **Did not remove outliers in `amt`** — cap or transform if needed for a specific model's assumptions, but preserve them; they're disproportionately where fraud lives.

---

## 10. Conclusion

The dataset is well-structured and largely clean, which means the real work of my project isn't data cleaning — it's building a modeling approach that respects severe class imbalance and captures the non-linear, multi-factor nature of fraud (amount + category + timing + geography together, not any single variable alone). The patterns surfaced here — elevated fraud in card-not-present categories, a distinct time-of-day signature, and cardholder-merchant distance as a likely strong feature — give a clear, evidence-based starting point for feature engineering and model selection in the next phase.

---


