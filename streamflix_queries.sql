-- ============================================================
-- STREAMFLIX PRODUCT ANALYST - SQL PROFICIENCY (SECTION 2)
-- Technical Assessment
-- ============================================================

-- ============================================================
-- TABLE SCHEMA
-- ============================================================

CREATE TABLE sessions (
    session_id SERIAL PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    session_date DATE NOT NULL,
    minutes_watched INTEGER NOT NULL,
    content_type VARCHAR(20) NOT NULL CHECK (content_type IN ('movie', 'tv_show', 'documentary')),
    device_type VARCHAR(20) NOT NULL CHECK (device_type IN ('mobile', 'web', 'tv')),
    subscription_tier VARCHAR(20) NOT NULL CHECK (subscription_tier IN ('basic', 'standard', 'premium'))
);

CREATE INDEX idx_sessions_date ON sessions(session_date);
CREATE INDEX idx_sessions_user ON sessions(user_id);


-- ============================================================
-- QUERY 1: Month-over-Month Growth Rate in Total Minutes Watched
-- ============================================================
-- Purpose: Calculate the percentage change in total viewing time 
--          between consecutive months
-- Use Case: Identify growth trends and seasonal patterns

WITH monthly_totals AS (
    SELECT 
        DATE_TRUNC('month', session_date) AS month,
        SUM(minutes_watched) AS total_minutes
    FROM sessions
    WHERE EXTRACT(YEAR FROM session_date) = 2024
    GROUP BY DATE_TRUNC('month', session_date)
),
with_previous AS (
    SELECT 
        month,
        total_minutes,
        LAG(total_minutes) OVER (ORDER BY month) AS prev_month_minutes
    FROM monthly_totals
)
SELECT 
    TO_CHAR(month, 'YYYY-MM') AS month,
    total_minutes,
    prev_month_minutes,
    ROUND(
        ((total_minutes - prev_month_minutes) / prev_month_minutes::DECIMAL) * 100, 
        2
    ) AS mom_growth_rate_pct
FROM with_previous
WHERE prev_month_minutes IS NOT NULL
ORDER BY month;


-- ============================================================
-- QUERY 2: Top 10 Most Engaged Users (Last 30 Days)
-- ============================================================
-- Purpose: Identify power users based on composite engagement score
-- Formula: (Total Minutes × 0.5) + (Session Count × 10) + (Content Variety × 20)

WITH user_engagement AS (
    SELECT 
        user_id,
        SUM(minutes_watched) AS total_minutes,
        COUNT(*) AS session_count,
        COUNT(DISTINCT content_type) AS content_variety,
        COUNT(DISTINCT device_type) AS device_variety,
        AVG(minutes_watched) AS avg_session_duration
    FROM sessions
    WHERE session_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY user_id
)
SELECT 
    user_id,
    total_minutes,
    session_count,
    content_variety,
    device_variety,
    ROUND(avg_session_duration, 1) AS avg_session_min,
    ROUND(
        (total_minutes * 0.5) + (session_count * 10) + (content_variety * 20),
        2
    ) AS engagement_score
FROM user_engagement
ORDER BY engagement_score DESC
LIMIT 10;


-- ============================================================
-- QUERY 3: Content Types with Above-Average Watch Time 
--          but Below-Average Completion
-- ============================================================
-- Purpose: Identify content that attracts viewers but fails to retain them
-- Use Case: Content improvement and optimization prioritization

WITH content_metrics AS (
    SELECT 
        content_type,
        AVG(minutes_watched) AS avg_watch_time,
        COUNT(*) AS session_count,
        AVG(CASE WHEN minutes_watched >= 40 THEN 1.0 ELSE 0.0 END) AS completion_rate
    FROM sessions
    GROUP BY content_type
),
overall_averages AS (
    SELECT 
        AVG(minutes_watched) AS overall_avg_watch_time,
        AVG(CASE WHEN minutes_watched >= 40 THEN 1.0 ELSE 0.0 END) AS overall_avg_completion
    FROM sessions
)
SELECT 
    cm.content_type,
    ROUND(cm.avg_watch_time, 2) AS avg_watch_time,
    ROUND(cm.completion_rate * 100, 2) AS completion_rate_pct,
    ROUND(oa.overall_avg_watch_time, 2) AS overall_avg_watch,
    ROUND(oa.overall_avg_completion * 100, 2) AS overall_avg_completion_pct,
    cm.session_count,
    CASE 
        WHEN cm.avg_watch_time > oa.overall_avg_watch_time 
             AND cm.completion_rate < oa.overall_avg_completion 
        THEN 'HIGH WATCH / LOW COMPLETION'
        ELSE 'NORMAL'
    END AS category
FROM content_metrics cm
CROSS JOIN overall_averages oa
ORDER BY cm.avg_watch_time DESC;


-- ============================================================
-- QUERY 4: Cohort Retention Analysis by First Activity Month
-- ============================================================
-- Purpose: Track user retention over time based on signup cohort
-- Use Case: Measure long-term engagement and identify churn patterns

WITH user_cohorts AS (
    SELECT 
        user_id,
        DATE_TRUNC('month', MIN(session_date)) AS cohort_month
    FROM sessions
    GROUP BY user_id
),
user_activity AS (
    SELECT 
        s.user_id,
        uc.cohort_month,
        DATE_TRUNC('month', s.session_date) AS activity_month,
        EXTRACT(MONTH FROM AGE(DATE_TRUNC('month', s.session_date), uc.cohort_month))::INT AS months_since_signup
    FROM sessions s
    JOIN user_cohorts uc ON s.user_id = uc.user_id
),
cohort_sizes AS (
    SELECT 
        cohort_month, 
        COUNT(DISTINCT user_id) AS cohort_size
    FROM user_cohorts
    GROUP BY cohort_month
),
retention AS (
    SELECT 
        cohort_month,
        months_since_signup,
        COUNT(DISTINCT user_id) AS retained_users
    FROM user_activity
    GROUP BY cohort_month, months_since_signup
)
SELECT 
    TO_CHAR(r.cohort_month, 'YYYY-MM') AS cohort,
    cs.cohort_size,
    r.months_since_signup,
    r.retained_users,
    ROUND((r.retained_users::DECIMAL / cs.cohort_size) * 100, 1) AS retention_rate_pct
FROM retention r
JOIN cohort_sizes cs ON r.cohort_month = cs.cohort_month
ORDER BY r.cohort_month, r.months_since_signup;


-- ============================================================
-- QUERY 5: Users Who Downgraded with Decreased Watch Time
-- ============================================================
-- Purpose: Identify at-risk users who downgraded and reduced engagement
-- Use Case: Target retention campaigns and understand churn drivers

WITH tier_ranking AS (
    SELECT 
        tier_name,
        CASE tier_name 
            WHEN 'premium' THEN 3 
            WHEN 'standard' THEN 2 
            WHEN 'basic' THEN 1 
        END AS tier_rank
    FROM (VALUES ('premium'), ('standard'), ('basic')) AS t(tier_name)
),
user_monthly_activity AS (
    SELECT 
        user_id,
        DATE_TRUNC('month', session_date) AS month,
        MAX(subscription_tier) AS tier_at_month,
        SUM(minutes_watched) AS monthly_minutes,
        COUNT(*) AS session_count
    FROM sessions
    GROUP BY user_id, DATE_TRUNC('month', session_date)
),
with_previous AS (
    SELECT 
        uma.*,
        LAG(tier_at_month) OVER (PARTITION BY user_id ORDER BY month) AS prev_tier,
        LAG(monthly_minutes) OVER (PARTITION BY user_id ORDER BY month) AS prev_minutes
    FROM user_monthly_activity uma
)
SELECT 
    wp.user_id,
    TO_CHAR(wp.month, 'YYYY-MM') AS downgrade_month,
    wp.prev_tier AS previous_tier,
    wp.tier_at_month AS new_tier,
    wp.prev_minutes AS previous_month_minutes,
    wp.monthly_minutes AS current_month_minutes,
    ROUND(((wp.monthly_minutes - wp.prev_minutes) / wp.prev_minutes::DECIMAL) * 100, 1) AS watch_time_change_pct,
    wp.session_count
FROM with_previous wp
JOIN tier_ranking tr_prev ON wp.prev_tier = tr_prev.tier_name
JOIN tier_ranking tr_curr ON wp.tier_at_month = tr_curr.tier_name
WHERE tr_curr.tier_rank < tr_prev.tier_rank  -- Downgrade detected
  AND wp.monthly_minutes < wp.prev_minutes    -- Decreased watch time
ORDER BY watch_time_change_pct ASC
LIMIT 50;


-- ============================================================
-- END OF SECTION 2: SQL PROFICIENCY
-- ============================================================