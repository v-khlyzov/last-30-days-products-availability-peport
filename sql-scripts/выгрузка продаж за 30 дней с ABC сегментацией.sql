WITH base_data_goods AS (
    SELECT
        p.seller_id,
        CONCAT(p.seller_id, '-', pp.product_id) AS product_key,
        COALESCE(SUM(pp.qty), 0)::int AS qty_last_30_days, 
        COALESCE(SUM(pp.price * pp.qty), 0)::int AS gmv_last_30_days
    FROM parcel AS p
    LEFT JOIN product pp ON pp.product_parcel_id = p.parcel_id
    WHERE p.date::date BETWEEN current_date - INTERVAL '31 days' AND current_date - INTERVAL '1 day'
        AND p.payment_status IN ('hold', 'confirmed', 'refund')
    GROUP BY 1, 2
),
total_gmv_goods AS (
    SELECT SUM(gmv_last_30_days) AS total_gmv FROM base_data_goods
),
cumulative_data_goods AS (
    SELECT 
        bd.*, 
        SUM(gmv_last_30_days) OVER (ORDER BY gmv_last_30_days DESC) AS cumul_gmv
    FROM base_data_goods bd
),
goods_segmentation AS (
    SELECT 
        cd.seller_id,
        cd.product_key,
        cd.qty_last_30_days,
        cd.gmv_last_30_days,
        CASE 
            WHEN cd.cumul_gmv <= tg.total_gmv * 0.5 THEN 'A'
            WHEN cd.cumul_gmv <= tg.total_gmv * 0.8 THEN 'B'
            ELSE 'C'
        END AS ABC_goods
    FROM cumulative_data_goods cd
    CROSS JOIN total_gmv_goods tg
),
base_data_sellers AS (
    SELECT
        p.seller_id,
        COALESCE(SUM(pp.qty), 0)::int AS qty_last_30_days, 
        COALESCE(SUM(pp.price * pp.qty), 0)::int AS gmv_last_30_days
    FROM parcel AS p
    LEFT JOIN product pp ON pp.product_parcel_id = p.parcel_id
    WHERE p.date::date BETWEEN current_date - INTERVAL '31 days' AND current_date - INTERVAL '1 day'
        AND p.payment_status IN ('hold', 'confirmed', 'refund')
    GROUP BY 1
),
total_gmv_sellers AS (
    SELECT SUM(gmv_last_30_days) AS total_gmv FROM base_data_sellers
),
cumulative_data_sellers AS (
    SELECT 
        bd.*, 
        SUM(gmv_last_30_days) OVER (ORDER BY gmv_last_30_days DESC) AS cumul_gmv
    FROM base_data_sellers bd
),
sellers_segmentation AS (
    SELECT 
        cd.seller_id,
        CASE 
            WHEN cd.cumul_gmv <= tg.total_gmv * 0.5 THEN 'A'
            WHEN cd.cumul_gmv <= tg.total_gmv * 0.8 THEN 'B'
            ELSE 'C'
        END AS ABC_sellers
    FROM cumulative_data_sellers cd
    CROSS JOIN total_gmv_sellers tg
)
SELECT 
    g.product_key,
    g.seller_id,
    g.qty_last_30_days,
    g.gmv_last_30_days,
    g.ABC_goods,
    s.ABC_sellers
FROM goods_segmentation g
LEFT JOIN sellers_segmentation s ON g.seller_id= s.seller_id
ORDER BY g.gmv_last_30_days DESC;