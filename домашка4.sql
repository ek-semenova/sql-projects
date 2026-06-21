CREATE SCHEMA semenova;

CREATE TABLE semenova.language (
    language_id SERIAL PRIMARY KEY,
    language_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE semenova.nationality (
    nationality_id SERIAL PRIMARY KEY,
    nationality_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE semenova.country (
    country_id SERIAL PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE semenova.language_nationality (
    language_id INT REFERENCES semenova.language(language_id),
    nationality_id INT REFERENCES semenova.nationality(nationality_id),
    PRIMARY KEY (language_id, nationality_id)
);

CREATE TABLE semenova.nationality_country (
    nationality_id INT REFERENCES semenova.nationality(nationality_id),
    country_id INT REFERENCES semenova.country(country_id),
    PRIMARY KEY (nationality_id, country_id)
);

INSERT INTO semenova.language (language_name) VALUES
('Русский'),
('Английский'),
('Немецкий'),
('Французский'),
('Испанский');

INSERT INTO semenova.nationality (nationality_name) VALUES
('Славяне'),
('Англосаксы'),
('Германцы'),
('Романские народы'),
('Латиноамериканцы');

INSERT INTO semenova.country (country_name) VALUES
('Россия'),
('Великобритания'),
('Германия'),
('Франция'),
('Испания');

INSERT INTO semenova.language_nationality (language_id, nationality_id) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5);

INSERT INTO semenova.nationality_country (nationality_id, country_id) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5);

CREATE TABLE semenova.film_new (
    film_name VARCHAR(255) NOT NULL,
    film_year INTEGER CHECK (film_year > 0),
    film_rental_rate NUMERIC(4,2) DEFAULT 0.99,
    film_duration INTEGER NOT NULL CHECK (film_duration > 0)
);

INSERT INTO semenova.film_new (film_name, film_year, film_rental_rate, film_duration)
VALUES
('The Shawshank Redemption', 1994, 2.99, 142),
('The Green Mile', 1999, 0.99, 189),
('Back to the Future', 1985, 1.99, 116),
('Forrest Gump', 1994, 2.99, 142),
('Schindler''s List', 1993, 3.99, 195);

UPDATE semenova.film_new
SET film_rental_rate = film_rental_rate + 1.41;

DELETE FROM semenova.film_new
WHERE film_name = 'Back to the Future';

INSERT INTO semenova.film_new (film_name, film_year, film_rental_rate, film_duration)
VALUES ('The Godfather', 1972, 2.99, 175);

SELECT *,
       ROUND(film_duration / 60.0, 1) AS film_duration_hours
FROM semenova.film_new;

DROP TABLE semenova.film_new;