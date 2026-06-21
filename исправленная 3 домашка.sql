--=============== МОДУЛЬ 3. ОСНОВЫ SQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите для каждого покупателя его адрес проживания, город и страну проживания.
--В результирующей таблице должны быть следующие столбцы: Имя пользователя, фамилия пользователя, адрес, город, страна.

SELECT c.first_name, c.last_name, a.address, ci.city, co.country
FROM customer c
JOIN address a ON c.address_id = a.address_id
JOIN city ci ON a.city_id = ci.city_id
JOIN country co ON ci.country_id = co.country_id;

--ЗАДАНИЕ №2.1
--С помощью SQL-запроса посчитайте для каждого магазина количество его покупателей.
--В результирующей таблице должны быть следующие столбцы: Идентификатор магазина, количество прикрепленных пользователей.

SELECT store_id, COUNT(*) AS customer_count
FROM customer
GROUP BY store_id;

--ЗАДАНИЕ №2.2
--Доработайте запрос и выведите только те магазины, 
--у которых количество покупателей больше 300-от.
--Для решения используйте фильтрацию по сгруппированным строкам с использованием функции агрегации.
--В результирующей таблице должны быть следующие столбцы: Идентификатор магазина, количество прикрепленных пользователей.

SELECT store_id, COUNT(*) AS customer_count
FROM customer
GROUP BY store_id
HAVING COUNT(*) > 300;

--ЗАДАНИЕ №2.3
-- Доработайте запрос, добавив в него информацию о городе магазина, 
--а также фамилию и имя продавца, который работает в этом магазине.
--В результирующей таблице должны быть следующие столбцы: Фамилия и имя сотрудника в виде одного значения, идентификатор магазина, 
--город нахождения магазина, количество прикрепленных пользователей.

SELECT s.first_name || ' ' || s.last_name AS staff_name,
       st.store_id,
       ci.city,
       COUNT(*) AS customer_count
FROM customer c
JOIN store st ON c.store_id = st.store_id
JOIN address a ON st.address_id = a.address_id
JOIN city ci ON a.city_id = ci.city_id
JOIN staff s ON st.manager_staff_id = s.staff_id
GROUP BY s.staff_id, st.store_id, ci.city_id
HAVING COUNT(*) > 300;

--ЗАДАНИЕ №3
--Для каждого фильма посчитайте сколько раз его брали в прокат, при этом работать нужно только с теми фильмами, в которых снимались актрисы с именем Julia.
--В результирующей таблице должны быть следующие столбцы: Название фильма, количество аренд.

SELECT f.title, COUNT(r.rental_id) AS rental_count
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
WHERE EXISTS (
    SELECT 1
    FROM film_actor fa
    JOIN actor a ON fa.actor_id = a.actor_id
    WHERE fa.film_id = f.film_id
      AND a.first_name = 'JULIA'
)
GROUP BY f.film_id, f.title
ORDER BY rental_count DESC;

--ЗАДАНИЕ №4
--Посчитайте для каждого покупателя 4 аналитических показателя:
--  1. количество фильмов, которые он взял в аренду
--  2. общую стоимость платежей за аренду всех фильмов (значение округлите до целого числа)
--  3. минимальное значение платежа за аренду фильма
--  4. максимальное значение платежа за аренду фильма
--В результирующей таблице должны быть следующие столбцы: Фамилия и имя пользователя в виде одного значения, 
--количество арендованных фильмов, округленная сумма платежей, минимальный и максимальный платеж.

SELECT c.first_name || ' ' || c.last_name AS customer_name,
       COUNT(r.rental_id) AS rental_count,
       ROUND(SUM(p.amount)) AS total_amount,
       MIN(p.amount) AS min_payment,
       MAX(p.amount) AS max_payment
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
JOIN payment p ON r.rental_id = p.rental_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY c.customer_id;

--ЗАДАНИЕ №5
--Используя данные из таблицы городов, составьте все возможные пары городов так, чтобы 
--в результате не было пар с одинаковыми названиями городов. Решение должно быть через Декартово произведение.
--В результирующей таблице должны быть следующие столбцы: два столбца с названиями городов.

SELECT c1.city AS city1, c2.city AS city2
FROM city c1
CROSS JOIN city c2
WHERE c1.city <> c2.city;

--ЗАДАНИЕ №6
--Выведите наиболее и наименее востребованные категории фильмов (те, которые арендовали наибольшее/наименьшее количество раз), количество аренд и сумму продаж.
--В результирующей таблице должны быть следующие столбцы: Название категории, количество аренд, сумма продаж.

(SELECT cat.name, COUNT(r.rental_id) AS rental_count, SUM(p.amount) AS total_amount
FROM category cat
JOIN film_category fc ON cat.category_id = fc.category_id
JOIN inventory i ON fc.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
JOIN payment p ON r.rental_id = p.rental_id
GROUP BY cat.category_id, cat.name
ORDER BY rental_count DESC
LIMIT 1)

UNION

(SELECT cat.name, COUNT(r.rental_id) AS rental_count, SUM(p.amount) AS total_amount
FROM category cat
JOIN film_category fc ON cat.category_id = fc.category_id
JOIN inventory i ON fc.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
JOIN payment p ON r.rental_id = p.rental_id
GROUP BY cat.category_id, cat.name
ORDER BY rental_count ASC
LIMIT 1);