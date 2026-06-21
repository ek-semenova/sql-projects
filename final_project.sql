--№1
SELECT COUNT(*) 
FROM stroy.project
WHERE EXTRACT(YEAR FROM sign_date) = 2023;

--№2
SELECT JUSTIFY_INTERVAL(SUM(AGE(hire_date, birthdate)))
FROM stroy.employee e
JOIN stroy.person p ON e.person_id = p.person_id
WHERE e.hire_date BETWEEN '2022-01-01' AND '2022-12-31';

--№3
SELECT p.first_name || ' ' || p.last_name AS full_name,
       e.hire_date
FROM stroy.employee e
JOIN stroy.person p ON e.person_id = p.person_id
WHERE p.last_name LIKE 'М%'
  AND LENGTH(p.last_name) = 8
ORDER BY e.hire_date, RANDOM()
LIMIT 1;

--№4
SELECT COALESCE(
    AVG(EXTRACT(YEAR FROM AGE(p.birthdate)))::integer,
    0)
FROM stroy.employee e
JOIN stroy.person p ON e.person_id = p.person_id
WHERE e.dismissal_date IS NOT NULL
  AND NOT EXISTS (
    SELECT 1
    FROM stroy.project pr
    WHERE e.employee_id = ANY(pr.employees_id)
       OR e.employee_id = pr.project_manager_id
);

--5
SELECT SUM(pp.amount)
FROM stroy.project_payment pp
JOIN stroy.project pr ON pp.project_id = pr.project_id
JOIN stroy.customer c ON pr.customer_id = c.customer_id
JOIN stroy.address a ON c.address_id = a.address_id
JOIN stroy.city ci ON a.city_id = ci.city_id
JOIN stroy.country co ON ci.country_id = co.country_id
WHERE ci.city_name = 'Жуковский'
  AND co.country_name = 'Россия'
  AND pp.fact_transaction_timestamp IS NOT NULL;

--6
WITH bonus AS (
    SELECT pr.project_manager_id,
           SUM(pr.project_cost) * 0.01 AS bonus_amount,
           RANK() OVER (ORDER BY SUM(pr.project_cost) * 0.01 DESC) AS rnk
    FROM stroy.project pr
    WHERE pr.status = 'Завершен'
    GROUP BY pr.project_manager_id
)
SELECT b.project_manager_id,
       p.full_fio,
       b.bonus_amount
FROM bonus b
JOIN stroy.employee e ON b.project_manager_id = e.employee_id
JOIN stroy.person p ON e.person_id = p.person_id
WHERE b.rnk = 1;

--7

WITH running AS (
    SELECT 
        plan_payment_date,
        SUM(amount) OVER (
            PARTITION BY DATE_TRUNC('month', plan_payment_date)
            ORDER BY plan_payment_date
        ) AS running_total
    FROM stroy.project_payment
    WHERE payment_type = 'Авансовый'
      AND plan_payment_date IS NOT NULL
),
prev_running AS (
    SELECT 
        plan_payment_date,
        running_total,
        LAG(running_total) OVER (
            PARTITION BY DATE_TRUNC('month', plan_payment_date)
            ORDER BY plan_payment_date
        ) AS prev_total
    FROM running
)
SELECT plan_payment_date, running_total
FROM prev_running
WHERE running_total > 30000000
  AND (prev_total <= 30000000 OR prev_total IS NULL);

--8
WITH RECURSIVE departments AS (
    SELECT unit_id
    FROM stroy.company_structure
    WHERE unit_id = 17
    
    UNION
    
    SELECT cs.unit_id
    FROM stroy.company_structure cs
    JOIN departments d ON cs.parent_id = d.unit_id
)
SELECT SUM(ep.salary * ep.rate) AS total_salary
FROM stroy.employee_position ep
JOIN stroy.position p ON ep.position_id = p.position_id
JOIN departments d ON p.unit_id = d.unit_id;

--9

WITH numbered AS (
    SELECT 
        amount,
        fact_transaction_timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY EXTRACT(YEAR FROM fact_transaction_timestamp)
            ORDER BY fact_transaction_timestamp
        ) AS rn
    FROM stroy.project_payment
    WHERE fact_transaction_timestamp IS NOT NULL
),
every_fifth AS (
    SELECT amount, fact_transaction_timestamp
    FROM numbered
    WHERE rn % 5 = 0
),
moving AS (
    SELECT 
        AVG(amount) OVER (
            ORDER BY fact_transaction_timestamp
            ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
        ) AS moving_avg
    FROM every_fifth
),
total_moving_avg AS (
    SELECT SUM(moving_avg) AS total_sum
    FROM moving
),
project_costs AS (
    SELECT 
        EXTRACT(YEAR FROM sign_date) AS year,
        SUM(project_cost) AS sum_project_cost
    FROM stroy.project
    WHERE sign_date IS NOT NULL
    GROUP BY EXTRACT(YEAR FROM sign_date)
)
SELECT 
    pc.year,
    pc.sum_project_cost
FROM project_costs pc
CROSS JOIN total_moving_avg t
WHERE pc.sum_project_cost < t.total_sum;

--10

CREATE MATERIALIZED VIEW stroy.project_report AS
SELECT 
    pr.project_id,
    pr.project_name,
    last_pay.last_payment_date,
    last_pay.last_payment_amount,
    pm.full_fio AS project_manager_fio,
    c.customer_name,
    cw.types_of_work
FROM stroy.project pr
-- последний фактический платёж по проекту
JOIN (
    SELECT DISTINCT ON (project_id)
        project_id,
        fact_transaction_timestamp AS last_payment_date,
        amount AS last_payment_amount
    FROM stroy.project_payment
    WHERE fact_transaction_timestamp IS NOT NULL
    ORDER BY project_id, fact_transaction_timestamp DESC
) last_pay ON pr.project_id = last_pay.project_id
-- руководитель проекта
JOIN stroy.employee e ON pr.project_manager_id = e.employee_id
JOIN stroy.person pm ON e.person_id = pm.person_id
-- контрагент
JOIN stroy.customer c ON pr.customer_id = c.customer_id
-- типы работ контрагента, агрегированные в строку по каждому контрагенту
JOIN (
    SELECT ctw.customer_id,
           STRING_AGG(tw.type_of_work_name, ', ') AS types_of_work
    FROM stroy.customer_type_of_work ctw
    JOIN stroy.type_of_work tw ON ctw.type_of_work_id = tw.type_of_work_id
    GROUP BY ctw.customer_id
) cw ON c.customer_id = cw.customer_id;
