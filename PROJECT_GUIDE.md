# Healthcare Refund Intelligence Dashboard — Build Guide

## 1. Architecture

```
GitHub repo: data/  (public, raw-URL hosted CSVs)
   ├── Fact_Refunds.csv        (9,000 refund transactions)
   ├── Dim_Client.csv          (15 clients across 8 US states)
   ├── Dim_Payer.csv           (12 payers: Commercial/Government/Self-pay)
   ├── Dim_RefundType.csv      (CC, IVR CC, Clover, Copay, Refund Initiated)
   ├── Dim_User.csv            (20 refund/AR analysts)
   └── Dim_Date.csv            (365-day calendar)

        ↓ Power BI "Get Data → Web" connector (raw GitHub URLs)

refund_dashboard.db  (SQLite — mirrors the same star schema for SQL practice
                       and to demonstrate you understand the data model,
                       not just the visuals)
```

**Star schema**: `Fact_Refunds` in the center, with `Dim_Client`, `Dim_Payer`,
`Dim_User`, `Dim_RefundType`, `Dim_Date` as the surrounding dimensions.
This is the exact pattern used in real RCM/refund analytics platforms.

---

## 2. Hosting the data on GitHub (for resume authenticity)

Real SharePoint access isn't available for a portfolio build, so this project
hosts its source data on a public GitHub repo instead — a legitimate and
common substitute for a portfolio piece, and it doubles as a shareable
landing page for recruiters.

1. Create a public repo (e.g. `healthcare-refund-dashboard`) with this
   structure:
   ```
   healthcare-refund-dashboard/
   ├── README.md
   ├── data/          (the 6 CSVs)
   ├── sql/           (reporting_queries.sql)
   ├── docs/          (this guide)
   └── screenshots/   (dashboard page screenshots)
   ```
2. For each CSV, open it on GitHub → click **Raw** → copy the URL
   (`https://raw.githubusercontent.com/<username>/healthcare-refund-dashboard/main/data/<file>.csv`).
3. In Power BI Desktop: **Get Data → Web** → paste each raw URL, one query
   per file.
4. If you already built the model from local CSVs, don't recreate the
   tables — instead go to **Transform Data** (Power Query Editor), select
   each table, and edit the **Source** step (gear icon) to point at the raw
   GitHub URL instead of the local file path. This preserves all existing
   relationships and measures.
5. Publish the report to the Power BI Service (powerbi.com, free) and set a
   **scheduled refresh** (Settings → Datasets → Scheduled refresh) so it
   periodically re-pulls from GitHub — this is what supports an "automated,
   always-current" claim on your resume, accurately described as a
   cloud-hosted data source with scheduled refresh (not literally
   SharePoint, since that wasn't used).

If you'd rather skip this and just keep local CSVs for now, that's fine too —
the data model and dashboard work identically either way; only the
"automated refresh" story depends on this step.

---

## 3. Power BI Build Steps

### Step 1 — Import & Model
1. Get Data → Text/CSV (or Web, using the raw GitHub URLs) → load all 6 files.
2. Go to **Model view**. Create relationships:
   - `Fact_Refunds[client_id]` → `Dim_Client[client_id]` (many-to-one)
   - `Fact_Refunds[payer_id]` → `Dim_Payer[payer_id]`
   - `Fact_Refunds[user_id]` → `Dim_User[user_id]`
   - `Fact_Refunds[refund_type_id]` → `Dim_RefundType[refund_type_id]`
   - `Fact_Refunds[initiated_date_id]` → `Dim_Date[date_id]`
3. Mark `Dim_Date` as a **Date Table** (Modeling tab → Mark as Date Table).

### Step 2 — Core DAX Measures
Paste these into a new measure table called `_Measures`:

```DAX
Total Refund Amount = SUM(Fact_Refunds[refund_amount])

Total Refund Count = COUNTROWS(Fact_Refunds)

Avg Refund Amount = AVERAGE(Fact_Refunds[refund_amount])

Processed Refund Amount =
CALCULATE([Total Refund Amount], Fact_Refunds[refund_status] = "Processed")

Refunds Processed Count =
CALCULATE([Total Refund Count], Fact_Refunds[refund_status] = "Processed")

Open Refunds Amount =
CALCULATE(
    [Total Refund Amount],
    Fact_Refunds[refund_status] IN {"Initiated","In Review","Approved","On Hold"}
)

Rejected Refund Rate =
DIVIDE(
    CALCULATE([Total Refund Count], Fact_Refunds[refund_status] = "Rejected"),
    [Total Refund Count]
)

MTD Refund Amount =
CALCULATE([Total Refund Amount], DATESMTD(Dim_Date[full_date]))

Prior Month Refund Amount =
CALCULATE([Total Refund Amount], DATEADD(Dim_Date[full_date], -1, MONTH))

MoM Refund Growth % =
DIVIDE([Total Refund Amount] - [Prior Month Refund Amount], [Prior Month Refund Amount])

Avg Days Open (Aging) =
AVERAGEX(
    FILTER(Fact_Refunds, NOT Fact_Refunds[refund_status] IN {"Processed","Rejected"}),
    DATEDIFF(RELATED(Dim_Date[full_date]), TODAY(), DAY)
)
```

### Step 3 — Report Pages (matches your original requirements exactly)

**Page 1 — Executive Overview**
- KPI cards: Total Refund Amount, Total Refund Count, MTD Amount, MoM Growth %
- Trend line: refund amount by month (`Dim_Date[month_name]` on axis)
- Map or bar: refund amount by **State** (from `Dim_Client[state]`)

**Page 2 — Payer & Client View**
- Bar chart: Total Refund Amount by `Dim_Payer[payer_name]`
- Matrix: State × Client × Refund Amount (drillable)
- Slicer: Payer Type (Commercial/Government/Self-pay)

**Page 3 — Refund Type Breakdown**
- Donut/bar: refund count & amount by `Dim_RefundType[refund_type_name]`
  (CC, IVR CC, Clover, Copay, Refund Initiated)
- Table: refund type × status cross-tab

**Page 4 — User Productivity**
- Bar chart: Refunds Processed Count by `Dim_User[user_name]`
- Table: user × team × refunds processed × total amount processed
- Slicer: shift, team

**Page 5 — Credit Balance / Aging Report** *(this is the page that will most
impress a hiring manager who knows RCM — it's the real deliverable AR
teams live in)*
- Table: open refunds with `Avg Days Open`, aging bucket, client, payer
- Stacked bar: aging bucket (0-15 / 16-30 / 31-60 / 60+) by amount
- Conditional formatting: red for 60+ days open

### Step 4 — Slicers on every page
Client, State, Payer, Refund Type, Status, Date range — synced across pages
(Format → Edit Interactions / Sync Slicers pane).

---

## 4. How to talk about this on your resume

> Built an end-to-end Healthcare Refund & Credit Balance Analytics Dashboard
> in Power BI, modeling a star schema (SQL/SQLite) across 9,000+ refund
> transactions spanning payer, client/state, user, and refund-type
> dimensions; configured cloud-hosted data source with scheduled refresh;
> delivered aging/credit-balance reporting used to prioritize open refund
> inventory by dollar exposure.

Bullet variations depending on the job you're targeting:
- **For BA roles**: emphasize the requirements-gathering angle (KPI
  definitions matched to real RCM refund workflows you've lived: CC, IVR CC,
  Clover, Copay, Refund Initiated).
- **For Data Analyst roles**: emphasize the SQL data modeling, DAX measures,
  and aging-bucket logic.

---

## 5. Files in this project

| File | Purpose |
|---|---|
| `data/*.csv` (on GitHub) | Source data to import into Power BI |
| `refund_dashboard.db` | SQLite version of the same schema, for SQL practice/validation |
| `reporting_queries.sql` | 8 ready-to-run SQL queries matching each dashboard KPI |
| `generate_data.py` | The data generator itself — worth keeping/mentioning, shows you understand the schema you're building on |

---

## 6. Suggested next steps with me

1. I build the Power BI **.pbix isn't something I can generate directly**
   (that requires the Power BI Desktop app on your machine) — but I can walk
   you screen-by-screen through Steps 1–4 above, or troubleshoot any DAX/model
   errors as you build.
2. Once you have a first draft, share a screenshot and I'll help refine the
   visual design (this matters a lot for resume screenshots).
3. I can also write the aging-bucket and MoM-growth DAX in more depth, or
   add RLS (row-level security) by client/team if you want to show that as
   an advanced feature.
