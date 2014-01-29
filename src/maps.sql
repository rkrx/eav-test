DELIMITER //


DROP FUNCTION IF EXISTS rkr$map$get //
CREATE FUNCTION rkr$map$get(arg_data LONGTEXT CHARSET utf8, arg_key VARCHAR(512) CHARSET utf8, arg_default LONGTEXT CHARSET utf8)
	RETURNS LONGTEXT CHARSET utf8
    NO SQL
    SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	DECLARE xCount INT DEFAULT rkr$array$count(arg_data);
	DECLARE xItem LONGTEXT CHARSET utf8;
	DECLARE i INT DEFAULT 1;

	WHILE i < xCount DO
		SET xItem = rkr$array$get(i);
		IF rkr$array$get(xItem, 1) = arg_key THEN
			RETURN rkr$array$get(xItem, 2);
		END IF;
		SET i = i + 1;
	END WHILE;

	RETURN arg_default;
END//


DROP PROCEDURE IF EXISTS rkr$map$set //
CREATE PROCEDURE rkr$map$set(INOUT arg_data LONGTEXT CHARSET utf8, IN arg_key LONGTEXT CHARSET utf8, IN arg_value LONGTEXT CHARSET utf8)
    NO SQL
    SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	DECLARE xCount INT DEFAULT rkr$array$count(arg_data);
	DECLARE xItem LONGTEXT CHARSET utf8;
	DECLARE i INT DEFAULT 1;

	CALL rkr$array$push(xItem, arg_key);
	CALL rkr$array$push(xItem, arg_value);
	CALL rkr$map$remove(arg_data, arg_key);
	CALL rkr$array$push(arg_data, xItem);
END//


DROP PROCEDURE IF EXISTS rkr$map$remove //
CREATE PROCEDURE rkr$map$remove(INOUT arg_data LONGTEXT CHARSET utf8, arg_key VARCHAR(512) CHARSET utf8)
	NO SQL
	SQL SECURITY INVOKER
	DETERMINISTIC
body: BEGIN
	DECLARE xCount INT DEFAULT rkr$array$count(arg_data);
	DECLARE xItem LONGTEXT CHARSET utf8;
	DECLARE i INT DEFAULT 1;

	WHILE i < xCount DO
		SET xItem = rkr$array$get(i);
		IF rkr$array$get(xItem, 1) = arg_key THEN
			CALL rkr$array$remove(arg_data, i);
			LEAVE body;
		END IF;
		SET i = i + 1;
	END WHILE;
END //


DELIMITER ;