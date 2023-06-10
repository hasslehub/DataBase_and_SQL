-- CREATE DATABASE IF NOT EXISTS home_work_6;
USE lesson_4;


-- Создайте таблицу users_old, аналогичную таблице users. 
-- Создайте процедуру, с помощью которой можно переместить любого (одного) пользователя из таблицы users в таблицу users_old. 
-- (использование транзакции с выбором commit или rollback – обязательно).

DROP TABLE IF EXISTS users_old;
CREATE TABLE users_old (
	id INT PRIMARY KEY auto_increment, 
    firstname varchar(50), 
    lastname varchar(50), 
    email varchar(120)
);


DROP PROCEDURE IF EXISTS replace_user;
DELIMITER $$
CREATE PROCEDURE  replace_user (IN num1 INT) 
	DETERMINISTIC
BEGIN
INSERT INTO users_old (firstname,lastname,email) 
SELECT firstname, lastname, email 
	FROM users 
	WHERE users.id = num1;
DELETE FROM users 
	WHERE id = num1;
COMMIT;
END$$

DELIMITER ;

CALL replace_user(4); 




-- Создайте хранимую функцию hello(), которая будет возвращать приветствие, в зависимости от текущего времени суток. 
-- С 6:00 до 12:00 функция должна возвращать фразу "Доброе утро", с 12:00 до 18:00 функция должна возвращать фразу "Добрый день", 
-- с 18:00 до 00:00 — "Добрый вечер", с 00:00 до 6:00 — "Доброй ночи".

DROP FUNCTION IF EXISTS hello;
DELIMITER $$
CREATE FUNCTION hello() 
	RETURNS VARCHAR(25)
	DETERMINISTIC
BEGIN
DECLARE result_text VARCHAR(25);
SELECT CASE 
	WHEN CURRENT_TIME >= '12:00:00' AND  CURRENT_TIME < '18:00:00' THEN 'Добрый день'
	WHEN CURRENT_TIME >= '06:00:00' AND  CURRENT_TIME < '12:00:00' THEN 'Доброе утро'
	WHEN CURRENT_TIME >= '00:00:00' AND  CURRENT_TIME < '06:00:00' THEN 'Доброй ночи'
	ELSE 'Добрый вечер'
END INTO result_text;
RETURN result_text;
END$$

DELIMITER ;

SELECT hello();


 -- (по желанию)* Создайте таблицу logs типа Archive. Пусть при каждом создании записи в таблицах users, 
 -- communities и messages в таблицу logs помещается время и дата создания записи, название 
 -- таблицы, идентификатор первичного ключа.


DROP TABLE IF EXISTS logs;

CREATE TABLE logs (
    created_at DATETIME DEFAULT now(),
    table_name VARCHAR(20) NOT NULL,
    pk_id INT UNSIGNED NOT NULL
)  
ENGINE=ARCHIVE;

DROP TRIGGER IF EXISTS users_log;
CREATE TRIGGER  users_log
AFTER INSERT ON users FOR EACH ROW 
    INSERT INTO logs SET table_name = 'users' , pk_id = NEW.id;

DROP TRIGGER IF EXISTS communities_log;
CREATE TRIGGER  communities_log
AFTER INSERT ON communities FOR EACH ROW 
    INSERT INTO logs SET table_name = 'communities' , pk_id = NEW.id;

DROP TRIGGER IF EXISTS messages_log;
CREATE TRIGGER  messages_log
AFTER INSERT ON messages FOR EACH ROW 
    INSERT INTO logs SET table_name = 'messages' , pk_id = NEW.id;


-- Создайте функцию, которая принимает кол-во сек и формат их в кол-во дней, часов, минут и секунд.
-- Пример: 123456 ->'1 days 10 hours 18 minutes 36 seconds '

DROP PROCEDURE IF EXISTS times;
DELIMITER $$
CREATE PROCEDURE times(IN seconds INT)
BEGIN
    DECLARE days INT default 0;
    DECLARE hours INT default 0;
    DECLARE minutes INT default 0;

    WHILE seconds >= (60 * 60 * 24) DO
		SET days = seconds / (60 * 60 * 24);
		SET seconds = seconds % (60 * 60 * 24);
    END WHILE;

    WHILE seconds >= (60 * 60) DO
		SET hours = seconds / (60 * 60);
		SET seconds = seconds % (60 * 60);
    END WHILE;

    WHILE seconds >= 60 DO
		SET minutes = seconds / 60;
		SET seconds = seconds % 60;
    END WHILE;

SELECT days, hours, minutes, seconds;
END $$
DELIMITER ;

CALL times(123456);


-- Выведите только четные числа от 1 до 10 (Через цикл)
-- Пример: 2,4,6,8,10

DROP FUNCTION IF EXISTS even_integer; 
DELIMITER $$ 
CREATE FUNCTION even_integer(n INT) 
RETURNS VARCHAR(50)
DETERMINISTIC 

BEGIN 
	DECLARE i INT DEFAULT 0; 
	DECLARE result VARCHAR(50);
	SET result=''; 
	WHILE i < n DO 
		SET i = i + 2; 
		SET result = concat(result, '  ', i); 
	END WHILE; 
RETURN result; 
END $$ 
DELIMITER; 

SELECT even_integer(10);




-- 1. Создать процедуру, которая решает следующую задачу
-- Выбрать для одного пользователя 5 пользователей в случайной комбинации, которые удовлетворяют хотя бы одному критерию:
-- а) из одного города
-- б) состоят в одной группе
-- в) друзья друзей	

DROP PROCEDURE IF EXISTS users_list;
DELIMITER $$
CREATE PROCEDURE users_list(IN user_find INT)
BEGIN	
    SELECT t.id
    FROM
    (
		SELECT id
		FROM users u
		INNER JOIN profiles p
		ON u.id = p.user_id
		AND u.id <> user_find
		AND (
			SELECT p1.hometown
			FROM users u1
			INNER JOIN profiles p1
			ON u1.id = p1.user_id
			AND u1.id = user_find
		) = p.hometown
		UNION    
		SELECT DISTINCT u.id 
		FROM users u
		INNER JOIN users_communities uc
		ON u.id = uc.user_id
		WHERE uc.community_id IN 
			(SELECT community_id
				FROM users_communities
				WHERE users_communities.user_id = user_find)    
		UNION
		SELECT id
		FROM users 
		WHERE users.id IN (
			(SELECT initiator_user_id AS id 
				FROM friend_requests
				WHERE status='approved' 
				AND target_user_id IN (
					SELECT initiator_user_id AS id 
					FROM friend_requests
					WHERE target_user_id = user_find AND status='approved'
					UNION ALL
					SELECT target_user_id 
					FROM friend_requests
					WHERE initiator_user_id = user_find AND status='approved') 
                    
				UNION
				SELECT target_user_id 
				FROM friend_requests
				WHERE status='approved' 
				AND initiator_user_id IN (
					SELECT initiator_user_id AS id 
					FROM friend_requests
					WHERE target_user_id = user_find AND status='approved'
					UNION ALL
					SELECT target_user_id 
					FROM friend_requests
					WHERE initiator_user_id = user_find AND status='approved')
			)
		)
	) t
    ORDER BY RAND() 
    LIMIT 5;

END $$
DELIMITER;

CALL users_list(4);

-- 2. Создать функцию, вычисляющей коэффициент популярности пользователя

DROP FUNCTION IF EXISTS get_popularity_coefficient;
DELIMITER $$
CREATE FUNCTION get_popularity_coefficient(
	user_id INT
)
RETURNS INT DETERMINISTIC
BEGIN
	DECLARE result INT DEFAULT 0;
	SELECT 
		(   
			SELECT count(f.id)
			FROM (
				SELECT fr1.initiator_user_id AS id
				FROM friend_requests fr1
				WHERE fr1.target_user_id = u.id AND fr1.status='approved'
				UNION
				SELECT fr2.target_user_id 
				FROM friend_requests fr2
				WHERE fr2.initiator_user_id = u.id AND fr2.status='approved'
			) f
		) AS `count_friends` INTO result
	FROM users u
    WHERE u.id = user_id;
    
    RETURN result;
END $$

SELECT get_popularity_coefficient(1); 

--  Создать процедуру для добавления нового пользователя с профилем

DROP PROCEDURE IF EXISTS add_new_user;
DELIMITER $$
CREATE PROCEDURE add_new_user(
	IN firstname VARCHAR(50),
    IN lastname VARCHAR(50),
    IN email VARCHAR(120),
    IN gender CHAR(1),
    IN birthday DATE,
    IN hometown VARCHAR(100),
    IN photo_body text,
  	IN photo_filename VARCHAR(255),
    OUT user_id INT
)
BEGIN
    DECLARE media_id INT;
    DECLARE media_type_id INT;
	
    INSERT INTO users(firstname, lastname, email)
    VALUES
    (firstname, lastname, email);
	SET user_id = LAST_INSERT_ID();
        
    IF photo_body IS NOT NULL OR photo_filename IS NOT NULL THEN
		SELECT id INTO media_type_id
		FROM media_types
		WHERE name_type = "Photo"
		LIMIT 1;
        
		INSERT INTO media(user_id, media_type_id, body, filename)
		VALUES
		(user_id, media_type_id, photo_body, photo_filename);
		SET media_id = LAST_INSERT_ID();
	
    END IF;
    
    INSERT INTO profiles
    VALUES
    (user_id, gender, birthday, media_id, hometown);
    
END $$

CALL add_new_user("test", "test", "test", "m", '2011-12-20', "test", "test", "test", @user_id);

SELECT *
FROM users
LEFT JOIN profiles
ON users.id = profiles.user_id
LEFT JOIN media
ON profiles.photo_id = media.id
AND users.id = media.user_id
WHERE users.id = @user_id;
