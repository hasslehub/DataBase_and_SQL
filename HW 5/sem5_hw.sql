CREATE DATABASE IF NOT EXISTS home_work_5;
USE home_work_5;

DROP TABLE IF EXISTS cars;
CREATE TABLE cars
(
	id INT NOT NULL PRIMARY KEY,
    name VARCHAR(45),
    cost INT
);

INSERT cars
VALUES
	(1, "Audi", 52642),
    (2, "Mercedes", 57127 ),
    (3, "Skoda", 9000 ),
    (4, "Volvo", 29000),
	(5, "Bentley", 350000),
    (6, "Citroen ", 21000 ), 
    (7, "Hummer", 41400), 
    (8, "Volkswagen ", 21600);
    
SELECT *
FROM cars;

-- Создайте представление, в которое попадут автомобили стоимостью  до 25 000 долларов
CREATE VIEW ViewCars 
AS
SELECT * 
FROM Cars
WHERE cost < 25000;

SELECT *
FROM ViewCars;

-- Изменить в существующем представлении порог для стоимости: 
-- пусть цена будет до 30 000 долларов (используя оператор ALTER VIEW)

ALTER VIEW ViewCars 
AS
SELECT * 
FROM Cars
WHERE cost < 30000;

SELECT *
FROM ViewCars;

-- Создайте представление, в котором будут только автомобили марки “Шкода” и “Ауди”
CREATE VIEW VagCars 
AS
SELECT * 
FROM Cars
WHERE name = "Audi" OR name = "Skoda";

SELECT *
FROM VagCars;


-- Добавьте новый столбец под названием «время до следующей станции».
-- Исходная сущность
DROP TABLE IF EXISTS Route;
CREATE TABLE Route
(
train_id INT NOT NULL,
station varchar(20) NOT NULL,
station_time TIME NOT NULL
);

INSERT Route(train_id, station, station_time)
VALUES (110, "SanFrancisco", "10:00:00"),
(110, "Redwood Sity", "10:54:00"),
(110, "Palo Alto", "11:02:00"),
(110, "San Jose", "12:35:00"),
(120, "SanFrancisco", "11:00:00"),
(120, "Palo Alto", "12:49:00"),
(120, "San Jose", "13:30:00");

SELECT * 
FROM Route;

-- Добавьте новый столбец под названием «время до следующей станции».
ALTER TABLE Route
ADD COLUMN time_to_next_station TIME;

-- Проще это сделать с помощью оконной функции LEAD. 
-- Эта функция сравнивает значения из одной строки со следующей строкой, чтобы получить результат. 
-- В этом случае функция сравнивает значения в столбце «время» для станции со станцией сразу после нее.

UPDATE Route r
JOIN (
    SELECT train_id, 
		station, 
        station_time, 
		SUBTIME(LEAD(station_time) OVER(PARTITION BY train_id ORDER BY train_id), station_time) AS time_to_next_station
    FROM Route) t 
    ON r.train_id = t.train_id AND r.station = t.station AND r.station_time = t.station_time
	SET r.time_to_next_station = t.time_to_next_station;

SELECT * FROM Route;

