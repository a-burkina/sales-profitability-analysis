-- Анализ прибыльности продаж Sample Superstore
-- Диалект: SQLite
-- Ожидаемая таблица: sales
-- Денежные показатели округляются только в итоговом выводе.

-- 1. Проверка количества строк
SELECT COUNT(*) AS row_count
FROM sales;

-- 2. Основные KPI
SELECT
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit,
    ROUND(100.0 * SUM(Profit) / NULLIF(SUM(Sales), 0), 2) AS profit_margin_pct,
    COUNT(DISTINCT "Order ID") AS order_count,
    COUNT(DISTINCT "Customer ID") AS customer_count
FROM sales;

-- 3. Продажи, прибыль и маржа по категориям
SELECT
    Category,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit,
    ROUND(100.0 * SUM(Profit) / NULLIF(SUM(Sales), 0), 2) AS profit_margin_pct
FROM sales
GROUP BY Category
ORDER BY total_profit DESC;

-- 4. Результаты по всем подкатегориям
SELECT
    Category,
    "Sub-Category" AS sub_category,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit,
    ROUND(100.0 * SUM(Profit) / NULLIF(SUM(Sales), 0), 2) AS profit_margin_pct
FROM sales
GROUP BY Category, "Sub-Category"
ORDER BY total_profit ASC;

-- 5. Только убыточные подкатегории
SELECT
    Category,
    "Sub-Category" AS sub_category,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit,
    ROUND(100.0 * SUM(Profit) / NULLIF(SUM(Sales), 0), 2) AS profit_margin_pct
FROM sales
GROUP BY Category, "Sub-Category"
HAVING SUM(Profit) < 0
ORDER BY total_profit ASC;

-- 6. Финансовый результат по диапазонам скидки
WITH discount_bands AS (
    SELECT
        CASE
            WHEN Discount = 0 THEN '0%'
            WHEN Discount < 0.10 THEN 'менее 10%'
            WHEN Discount < 0.20 THEN '10–19%'
            WHEN Discount < 0.30 THEN '20–29%'
            ELSE '30% и выше'
        END AS discount_band,
        CASE
            WHEN Discount = 0 THEN 1
            WHEN Discount < 0.10 THEN 2
            WHEN Discount < 0.20 THEN 3
            WHEN Discount < 0.30 THEN 4
            ELSE 5
        END AS band_order,
        Sales,
        Profit
    FROM sales
)
SELECT
    discount_band,
    COUNT(*) AS row_count,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit,
    ROUND(100.0 * SUM(Profit) / NULLIF(SUM(Sales), 0), 2) AS profit_margin_pct,
    SUM(CASE WHEN Profit < 0 THEN 1 ELSE 0 END) AS loss_row_count,
    ROUND(SUM(CASE WHEN Profit < 0 THEN -Profit ELSE 0 END), 2) AS gross_loss
FROM discount_bands
GROUP BY discount_band, band_order
ORDER BY band_order;

-- 7. Доля валовых убытков по отрицательным строкам,
--    приходящаяся на скидки 30% и выше
SELECT
    ROUND(
        SUM(
            CASE
                WHEN Profit < 0 AND Discount >= 0.30 THEN -Profit
                ELSE 0
            END
        ),
        2
    ) AS gross_loss_discount_30_plus,
    ROUND(
        SUM(CASE WHEN Profit < 0 THEN -Profit ELSE 0 END),
        2
    ) AS gross_loss_all_negative_rows,
    ROUND(
        100.0
        * SUM(
            CASE
                WHEN Profit < 0 AND Discount >= 0.30 THEN -Profit
                ELSE 0
            END
        )
        / NULLIF(SUM(CASE WHEN Profit < 0 THEN -Profit ELSE 0 END), 0),
        2
    ) AS gross_loss_share_discount_30_plus_pct
FROM sales;

-- Ожидаемое подтверждённое значение последнего показателя: 88.72%.

