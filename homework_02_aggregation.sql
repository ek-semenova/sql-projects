--=============== МОДУЛЬ 2. РАБОТА С БАЗАМИ ДАННЫХ =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Напишите 3 SQL-запроса, которые выведут информацию о фильмах со специальным атрибутом "Behind the Scenes". 
--В запросах должны использоваться разные операторы или функции для работы с массивами.
--В результирующей таблице должны быть следующие столбцы: Название фильма, столбец со специальными атрибутами.

-- Способ 1: оператор ANY
SELECT title, special_features
FROM film
WHERE 'Behind the Scenes' = ANY(special_features);

-- Способ 2: оператор @> (массив содержит элемент)
SELECT title, special_features
FROM film
WHERE special_features @> ARRAY['Behind the Scenes'];

-- Способ 3: приведение к тексту и ILIKE
SELECT title, special_features
FROM film
WHERE array_position(special_features, 'Behind the Scenes') IS NOT NULL;

--ЗАДАНИЕ №2
--Получите из таблицы платежей за прокат фильмов информацию по платежам, 
--которые выполнялись в промежуток с 17 июня 2005 года по 19 июня 2005 года включительно и 
--стоимость которых превышает 1.00. Платежи нужно отсортировать по дате платежа.
--В результирующей таблице должны быть следующие столбцы: идентификатор платежа, размер платежа, дата платежа.

SELECT payment_id, amount, payment_date
FROM payment
WHERE payment_date >= '2005-06-17' AND payment_date < '2005-06-20' AND amount > 1.00
ORDER BY payment_date;

--ЗАДАНИЕ №3
--Выведите ТОП-5 покупателей, которые совершили платежи на наибольшую сумму.
--В результирующей таблице должны быть следующие столбцы: Идентификатор пользователя, сумма платежей.

SELECT customer_id, SUM(amount) AS total_amount
FROM payment
GROUP BY customer_id
ORDER BY total_amount DESC
LIMIT 5;

--ЗАДАНИЕ №4
--Получите количество предпочитаемых жанров для каждого пользователя.
--В результирующей таблице должны быть следующие столбцы: Идентификатор пользователя, количество предпочитаемых жанров.

SELECT customer_id,
       jsonb_array_length(preferences -> 'profile' -> 'favorite_genres') AS genre_count
FROM customer
WHERE preferences IS NOT NULL;

--ЗАДАНИЕ №5
--Получите количество пользователей у которых отключено уведомление по email.
--В результирующей таблице должны быть следующие столбцы: Одно значение количества.

SELECT COUNT(*) 
FROM customer
WHERE (preferences -> 'notifications' ->> 'email') = 'false';

--ЗАДАНИЕ №6
--Получите сколько заплатил каждый пользователь за прокат фильмов за каждый месяц.
--В результирующей таблице должны быть следующие столбцы: Идентификатор пользователя, значение месяца, сумма платежей.

SELECT customer_id,
       EXTRACT(YEAR FROM payment_date) AS year,
       EXTRACT(MONTH FROM payment_date) AS month,
       SUM(amount) AS total_amount
FROM payment
GROUP BY customer_id, EXTRACT(YEAR FROM payment_date), EXTRACT(MONTH FROM payment_date)
ORDER BY customer_id, year, month;

--ЗАДАНИЕ №7
--Получите на какую сумму продал каждый сотрудник магазина
--В результирующей таблице должны быть следующие столбцы: Идентификатор сотрудника, сумма платежей.

SELECT staff_id, SUM(amount) AS total_amount
FROM payment
GROUP BY staff_id;

--ЗАДАНИЕ №8
--Используя данные из таблицы rental о дате выдачи фильма в аренду и дате возврата,
--вычислите для каждого покупателя среднее количество дней, за которые он возвращает фильмы, округленное до сотых. 
--В результирующей таблице должны быть следующие столбцы: Идентификатор пользователя, 
--среднее количество дней с учетом округления 

SELECT customer_id, ROUND(AVG(return_date::date - rental_date::date), 2) AS avg_days
FROM rental
WHERE return_date IS NOT NULL
GROUP BY customer_id
ORDER BY customer_id;

