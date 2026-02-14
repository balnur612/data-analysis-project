create table customer_transactions.Transactions(
date_new DATE,
Id_check INT,
ID_client INT,
Count_product DECIMAL(10,3),
Sum_payment DECIMAL(10,2)
);

LOAD DATA INFILE "C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\transactions_info.csv"
INTO TABLE customer_transactions.transactions
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


SHOW VARIABLES LIKE 'secure_file_priv';

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/transactions_info.csv'
INTO TABLE customer_transactions.transactions
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/transactions_info.csv'
INTO TABLE customer_transactions.transactions
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ЗАДАНИЕ 1
-- список клиентов с непрерывной историей
SELECT t.ID_client,
       AVG(t.Sum_payment) AS avg_check,
       SUM(t.Sum_payment)/12 AS avg_month_sum,
       COUNT(t.Id_check) AS total_transactions
FROM customer_transactions.transactions t
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-05-31'
AND t.ID_client IN (
    SELECT ID_client
    FROM customer_transactions.transactions
    WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
    GROUP BY ID_client
    HAVING COUNT(DISTINCT YEAR(date_new)*100 + MONTH(date_new)) = 12
)
GROUP BY t.ID_client
ORDER BY t.ID_client;

CREATE TEMPORARY TABLE customer_transactions.active_clients AS
SELECT ID_client
FROM customer_transactions.transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY ID_client
HAVING COUNT(DISTINCT YEAR(date_new)*100 + MONTH(date_new)) = 12;

SELECT t.ID_client,
       YEAR(t.date_new) AS year,
       MONTH(t.date_new) AS month,
       SUM(t.Sum_payment) AS total_sum_month,
       COUNT(t.Id_check) AS transactions_count_month,
       AVG(t.Sum_payment) AS avg_check_month
FROM customer_transactions.transactions t
JOIN customer_transactions.active_clients ac ON t.ID_client = ac.ID_client
GROUP BY t.ID_client, YEAR(t.date_new), MONTH(t.date_new)
ORDER BY t.ID_client, year, month;

-- Задание 3
-- анализ по полу
SELECT 
    YEAR(t.date_new) AS year,
    MONTH(t.date_new) AS month,
    IFNULL(c.Gender, 'NA') AS Gender,
    
    COUNT(t.Id_check) AS transactions_count,
    SUM(t.Sum_payment) AS total_sum,

    --  доля по количеству операций
    COUNT(t.Id_check) * 100 /
    SUM(COUNT(t.Id_check)) OVER (PARTITION BY YEAR(t.date_new), MONTH(t.date_new)) 
    AS pct_transactions,

    --  доля по сумме
    SUM(t.Sum_payment) * 100 /
    SUM(SUM(t.Sum_payment)) OVER (PARTITION BY YEAR(t.date_new), MONTH(t.date_new)) 
    AS pct_sum

FROM customer_transactions.transactions t
LEFT JOIN customer_transactions.customers c 
       ON t.ID_client = c.Id_client

WHERE t.date_new BETWEEN '2015-06-01' AND '2016-05-31'

GROUP BY YEAR(t.date_new), MONTH(t.date_new), IFNULL(c.Gender, 'NA')
ORDER BY year, month, Gender;

-- Задание 4
-- за весь период
SELECT
    CASE 
        WHEN c.Age IS NULL THEN 'NA'
        ELSE CONCAT(FLOOR(c.Age/10)*10, '-', FLOOR(c.Age/10)*10 + 9)
    END AS age_group,

    COUNT(t.Id_check) AS total_transactions,
    SUM(t.Sum_payment) AS total_sum,

    COUNT(t.Id_check) * 100 /
    (SELECT COUNT(*) 
     FROM customer_transactions.transactions
     WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31')
    AS pct_transactions,

    SUM(t.Sum_payment) * 100 /
    (SELECT SUM(Sum_payment) 
     FROM customer_transactions.transactions
     WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31')
    AS pct_sum

FROM customer_transactions.transactions t
LEFT JOIN customer_transactions.customers c 
       ON t.ID_client = c.Id_client

WHERE t.date_new BETWEEN '2015-06-01' AND '2016-05-31'

GROUP BY age_group
ORDER BY age_group;

-- Задание 5
-- квартальный анализ
SELECT
    CONCAT(YEAR(t.date_new), '-Q', QUARTER(t.date_new)) AS year_quarter,

    CASE 
        WHEN c.Age IS NULL THEN 'NA'
        ELSE CONCAT(FLOOR(c.Age/10)*10, '-', FLOOR(c.Age/10)*10 + 9)
    END AS age_group,

    COUNT(t.Id_check) AS transactions_count,
    SUM(t.Sum_payment) AS total_sum,
    AVG(t.Sum_payment) AS avg_check

FROM customer_transactions.transactions t
LEFT JOIN customer_transactions.customers c 
       ON t.ID_client = c.Id_client

WHERE t.date_new BETWEEN '2015-06-01' AND '2016-05-31'

GROUP BY year_quarter, age_group
ORDER BY year_quarter, age_group;

-- Задание 2
-- Общая месячная аналитика
SELECT 
    YEAR(date_new) AS year,
    MONTH(date_new) AS month,

    AVG(Sum_payment) AS avg_check_month,
    COUNT(Id_check) AS total_transactions_month,
    COUNT(DISTINCT ID_client) AS active_clients_month,

    COUNT(Id_check) * 100 /
    (SELECT COUNT(*) 
     FROM customer_transactions.transactions
     WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31')
    AS pct_transactions_year,

    SUM(Sum_payment) * 100 /
    (SELECT SUM(Sum_payment)
     FROM customer_transactions.transactions
     WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31')
    AS pct_sum_year

FROM customer_transactions.transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY YEAR(date_new), MONTH(date_new)
ORDER BY year, month;




