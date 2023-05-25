/*
Урок 2. SQL – создание объектов, простые запросы выборки
*/


-- 1. Используя операторы языка SQL,
--    создайте табличку “sales”. Заполните ее данными.

CREATE DATABASE IF NOT EXISTS home_work_2;
USE home_work_2;

DROP TABLE IF EXISTS sales;
CREATE TABLE sales
(
	`id` INT PRIMARY KEY AUTO_INCREMENT,
    `order_date` DATE NOT NULL,
	`count_product` INT NOT NULL
);

INSERT INTO sales(order_date, count_product)
VALUE
	('2022-01-01', 156),
    ('2022-01-02', 180),
    ('2022-01-03', 21),
    ('2022-01-04', 124),
    ('2022-01-05', 341);
    

-- 2. Сгруппируйте значений количества в 3 сегмента — меньше 100, 100-300 и больше 300.
SELECT
    CASE
        WHEN count_product < 100 
			THEN 'Маленький заказ'
        WHEN count_product BETWEEN 100 AND 300 
			THEN 'Средний заказ'
		ELSE 'Большой заказ'
    END AS Segment,
	COUNT(*) AS 'Кол-во заказов'
FROM sales
GROUP BY Segment; -- 'Тип заказа'; -- кирилицу не любит

-- Без GROUP BY
SELECT order_date,
    CASE
        WHEN count_product < 100 
			THEN 'Маленький заказ'
        WHEN count_product BETWEEN 100 AND 300 
			THEN 'Средний заказ'
		ELSE 'Большой заказ'
    END AS 'Тип заказа'
FROM sales;
	

-- 3. Создайте таблицу “orders”, заполните ее значениями. 
--    Покажите “полный” статус заказа, используя оператор CASE
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    employee_id VARCHAR(10) NOT NULL,
    amount DECIMAL(7,2) NOT NULL,
    order_status VARCHAR(50) NOT NULL
);

INSERT INTO orders(employee_id, amount, order_status)
VALUES
	('e03', 15.00, 'OPEN'),
	('e01', 25.50, 'OPEN'),
	('e05', 100.70, 'CLOSED'),
	('e02', 22.18, 'OPEN'),
	('e04', 9.50, 'CANCELLED');

SELECT *
FROM orders;

SELECT 
    id, 
    employee_id, 
    amount, 
    order_status, 
    CASE 
        WHEN order_status = 'OPEN' THEN 'Order is in open state' 
        WHEN order_status = 'CLOSED' THEN 'Order is closed' 
        WHEN order_status = 'CANCELLED' THEN 'Order is cancelled' 
    END AS full_order_status
FROM orders;

-- Дополнительное задание:

-- 1. Установка внешнего ключа:

ALTER TABLE orders
ADD CONSTRAINT fk_orders_sales
FOREIGN KEY (product)
REFERENCES sales(product);

-- 2. Получение нужных данных без использования оператора JOIN:

SELECT 
    p.title AS publication_title, 
    p.description AS publication_description, 
    p.author_id, 
    c.login AS author_login
FROM 
    publications AS p
INNER JOIN clients AS c ON p.author_id = c.id;

-- 3. Выполнение поиска по публикациям, автором которых является клиент "Mikle":

SELECT 
    title, 
    description 
FROM 
    publications 
WHERE 
    author_id = (SELECT id FROM clients WHERE login = 'Mikle');