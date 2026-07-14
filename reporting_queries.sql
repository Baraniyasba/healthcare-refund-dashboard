-- ============================================================
-- Healthcare Refund Dashboard - SQL Reporting Layer
-- Run these against refund_dashboard.db to validate data
-- and to practice the exact SQL you'd write on the job.
-- ============================================================

-- 1. Total refund amount & count (headline KPI card)
SELECT
    COUNT(*)                       AS total_refunds,
    ROUND(SUM(refund_amount), 2)   AS total_refund_amount,
    ROUND(AVG(refund_amount), 2)   AS avg_refund_amount
FROM Fact_Refunds;

-- 2. Payer-wise refund summary
SELECT
    p.payer_name,
    p.payer_type,
    COUNT(*)                       AS refund_count,
    ROUND(SUM(f.refund_amount),2)  AS total_amount
FROM Fact_Refunds f
JOIN Dim_Payer p ON f.payer_id = p.payer_id
GROUP BY p.payer_name, p.payer_type
ORDER BY total_amount DESC;

-- 3. State & Client-wise refund summary
SELECT
    c.state,
    c.client_name,
    COUNT(*)                       AS refund_count,
    ROUND(SUM(f.refund_amount),2)  AS total_amount
FROM Fact_Refunds f
JOIN Dim_Client c ON f.client_id = c.client_id
GROUP BY c.state, c.client_name
ORDER BY c.state, total_amount DESC;

-- 4. User-wise refunds processed (only status = Processed)
SELECT
    u.user_name,
    u.team,
    COUNT(*)                       AS refunds_processed,
    ROUND(SUM(f.refund_amount),2)  AS total_amount_processed
FROM Fact_Refunds f
JOIN Dim_User u ON f.user_id = u.user_id
WHERE f.refund_status = 'Processed'
GROUP BY u.user_name, u.team
ORDER BY refunds_processed DESC;

-- 5. Refund type breakdown (CC / IVR CC / Clover / Copay / Refund Initiated)
SELECT
    rt.refund_type_name,
    rt.refund_category,
    COUNT(*)                       AS refund_count,
    ROUND(SUM(f.refund_amount),2)  AS total_amount,
    ROUND(AVG(f.refund_amount),2)  AS avg_amount
FROM Fact_Refunds f
JOIN Dim_RefundType rt ON f.refund_type_id = rt.refund_type_id
GROUP BY rt.refund_type_name, rt.refund_category
ORDER BY total_amount DESC;

-- 6. Aging / credit balance style view: refunds still open (not Processed/Rejected)
SELECT
    f.refund_id,
    f.claim_id,
    c.client_name,
    p.payer_name,
    f.refund_status,
    d.full_date AS initiated_date,
    JULIANDAY('2026-06-30') - JULIANDAY(d.full_date) AS days_open,
    f.refund_amount
FROM Fact_Refunds f
JOIN Dim_Client c ON f.client_id = c.client_id
JOIN Dim_Payer p ON f.payer_id = p.payer_id
JOIN Dim_Date d ON f.initiated_date_id = d.date_id
WHERE f.refund_status NOT IN ('Processed', 'Rejected')
ORDER BY days_open DESC;

-- 7. Monthly refund trend (for the "real-time" trend line visual)
SELECT
    d.year,
    d.month,
    d.month_name,
    COUNT(*)                       AS refund_count,
    ROUND(SUM(f.refund_amount),2) AS total_amount
FROM Fact_Refunds f
JOIN Dim_Date d ON f.initiated_date_id = d.date_id
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;

-- 8. Aging buckets (classic credit balance report structure)
SELECT
    CASE
        WHEN days_open <= 15 THEN '0-15 days'
        WHEN days_open <= 30 THEN '16-30 days'
        WHEN days_open <= 60 THEN '31-60 days'
        ELSE '60+ days'
    END AS aging_bucket,
    COUNT(*) AS refund_count,
    ROUND(SUM(refund_amount), 2) AS total_amount
FROM (
    SELECT
        f.refund_id,
        f.refund_amount,
        JULIANDAY('2026-06-30') - JULIANDAY(d.full_date) AS days_open
    FROM Fact_Refunds f
    JOIN Dim_Date d ON f.initiated_date_id = d.date_id
    WHERE f.refund_status NOT IN ('Processed', 'Rejected')
)
GROUP BY aging_bucket
ORDER BY aging_bucket;
