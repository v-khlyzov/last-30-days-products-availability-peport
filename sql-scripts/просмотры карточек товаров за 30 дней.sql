SELECT 
    product_id,
    sum(count_details) as pdp_views
FROM 
    products AS p
WHERE 
    date BETWEEN yesterday() - INTERVAL 29 DAY AND yesterday()
GROUP BY product_id
HAVING sum(count_details) <> 0
ORDER BY pdp_views DESC;