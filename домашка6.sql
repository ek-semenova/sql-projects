--=============== МОДУЛЬ 6. POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1.1
--Выведите для каждого сотрудника сведения о самой первой продаже этого сотрудника.
--Решение должно быть через оконную функцию.
--В результирующей таблице должны быть следующие столбцы:Все столбцы из таблицы с платежами.

SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY staff_id ORDER BY payment_date) AS rn
    FROM payment
) t
WHERE rn = 1;

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY staff_id ORDER BY payment_date) AS rn
    FROM payment
) t
WHERE rn = 1;

--ЗАДАНИЕ №1.2
--Выведите для каждого сотрудника сведения о самой первой продаже этого сотрудника.
--Решение должно быть через агрегацию.
--В результирующей таблице должны быть следующие столбцы:Все столбцы из таблицы с платежами.

SELECT p.*
FROM payment p
JOIN (
    SELECT staff_id, MIN(payment_date) AS first_date
    FROM payment
    GROUP BY staff_id
) t ON p.staff_id = t.staff_id AND p.payment_date = t.first_date;

EXPLAIN (ANALYZE, BUFFERS)
SELECT p.*
FROM payment p
JOIN (
    SELECT staff_id, MIN(payment_date) AS first_date
    FROM payment
    GROUP BY staff_id
) t ON p.staff_id = t.staff_id AND p.payment_date = t.first_date;

--ЗАДАНИЕ №1.3
--Выведите для каждого сотрудника сведения о самой первой продаже этого сотрудника.
--Решение должно быть через distinct on.
--В результирующей таблице должны быть следующие столбцы:Все столбцы из таблицы с платежами.

SELECT DISTINCT ON (staff_id) *
FROM payment
ORDER BY staff_id, payment_date;

EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT ON (staff_id) *
FROM payment
ORDER BY staff_id, payment_date;

--ЗАДАНИЕ №2
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов 
--со специальным атрибутом "Behind the Scenes.
--Обязательное условие для выполнения задания: Должно быть использовано СТЕ в котором получаете нужные фильмы. В сте должна быть использована строго одна таблица.
--В результирующей таблице должны быть следующие столбцы: Фамилия и имя пользователя в виде одного значения, 
--количество арендованных фильмов.

WITH behind_scenes AS (
    SELECT film_id
    FROM film
    WHERE 'Behind the Scenes' = ANY(special_features)
)
SELECT c.last_name || ' ' || c.first_name AS customer_name,
       COUNT(r.rental_id) AS rental_count
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN behind_scenes bs ON i.film_id = bs.film_id
GROUP BY c.customer_id, c.last_name, c.first_name
ORDER BY c.customer_id;

EXPLAIN (ANALYZE, BUFFERS)
WITH behind_scenes AS (
    SELECT film_id
    FROM film
    WHERE 'Behind the Scenes' = ANY(special_features)
)
SELECT c.last_name || ' ' || c.first_name AS customer_name,
       COUNT(r.rental_id) AS rental_count
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN behind_scenes bs ON i.film_id = bs.film_id
GROUP BY c.customer_id, c.last_name, c.first_name
ORDER BY c.customer_id;

--ЗАДАНИЕ №3
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов
-- со специальным атрибутом "Behind the Scenes".
--Обязательное условие для выполнения задания: Должен быть использован подзапрос в котором получаете нужные фильмы. В подзапросе должна быть использована строго одна таблица.
--В результирующей таблице должны быть следующие столбцы: Фамилия и имя пользователя в виде одного значения, 
--количество арендованных фильмов.

SELECT c.last_name || ' ' || c.first_name AS customer_name,
       COUNT(r.rental_id) AS rental_count
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
JOIN inventory i ON r.inventory_id = i.inventory_id
WHERE i.film_id IN (
    SELECT film_id
    FROM film
    WHERE 'Behind the Scenes' = ANY(special_features)
)
GROUP BY c.customer_id, c.last_name, c.first_name
ORDER BY c.customer_id;

EXPLAIN (ANALYZE, BUFFERS)
SELECT c.last_name || ' ' || c.first_name AS customer_name,
       COUNT(r.rental_id) AS rental_count
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
JOIN inventory i ON r.inventory_id = i.inventory_id
WHERE i.film_id IN (
    SELECT film_id
    FROM film
    WHERE 'Behind the Scenes' = ANY(special_features)
)
GROUP BY c.customer_id, c.last_name, c.first_name
ORDER BY c.customer_id;

--ЗАДАНИЕ №4
--Создайте материализованное представление с запросом из задания №3
--и напишите запрос для обновления материализованного представления

CREATE MATERIALIZED VIEW behind_scenes_rentals AS
SELECT c.last_name || ' ' || c.first_name AS customer_name,
       COUNT(r.rental_id) AS rental_count
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
JOIN inventory i ON r.inventory_id = i.inventory_id
WHERE i.film_id IN (
    SELECT film_id
    FROM film
    WHERE 'Behind the Scenes' = ANY(special_features)
)
GROUP BY c.customer_id, c.last_name, c.first_name
ORDER BY c.customer_id;

-- Обновление:
REFRESH MATERIALIZED VIEW behind_scenes_rentals;

--ЗАДАНИЕ №5
--С помощью explain analyze проведите анализ стоимости выполнения запросов из всех предыдущих заданий и ответьте на вопросы:
--1. какой вариант вычислений затрачивает меньше ресурсов системы: из задания 1.1, 1.2 или 1.3.
--2. какой вариант вычислений затрачивает меньше ресурсов системы: 
--с использованием CTE из 2 задания или с использованием подзапроса из 3 задания.

-- Ответ 1: Вариант 1.2 через агрегацию затрачивает меньше всего ресурсов.
-- Execution Time: 1.1 - 11.557ms, 1.2 - 4.014ms, 1.3 - 15.910ms

-- Ответ 2: Вариант с подзапросом из задания 3 немного эффективнее чем CTE.
-- Execution Time: CTE - 2.101ms, подзапрос - 1.833ms



--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Откройте по ссылке SQL-запрос: https://letsdocode.ru/sql-main/sql-hw5.sql
--Сделайте explain analyze этого запроса.
--Основываясь на описании запроса, найдите узкие места и опишите их.
--Сравните с вашим решением из 3 задания.
--Сделайте построчное описание explain analyze на русском языке оптимизированного запроса. 
--Описание строк в explain можно посмотреть по ссылке: https://use-the-index-luke.com/sql/explain-plan/postgresql/operations



--ЗАДАНИЕ №2
--Для каждого магазина определите и выведите одним SQL-запросом следующие аналитические показатели:
-- 1. день, в который арендовали больше всего фильмов (день в формате год-месяц-день)
-- 2. количество фильмов взятых в аренду в этот день
-- 3. день, в который продали фильмов на наименьшую сумму (день в формате год-месяц-день)
-- 4. сумму продажи в этот день
--В результирующей таблице должны быть следующие столбцы: Идентификатор магазина, день аренды, количество фильмов, день продажи, сумма продаж.



--ЗАДАНИЕ №3
--Создайте не наполненное материализованное представление, которое будет хранить отчёт следующей структуры:
--идентификатор сотрудника
--ФИО сотрудника в виде одной строки
--город проживания сотрудника
--идентификатор магазина
--город магазина
--дата последнего платежа, принятого сотрудником
--размер последнего платежа, принятого сотрудником
--общая сумма продаж
