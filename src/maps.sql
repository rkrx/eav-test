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

	IF NOT rkr$map$valid(arg_data) THEN
		RETURN arg_default;
	END IF;

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

	CALL rkr$map$init(arg_data);
	CALL rkr$array$push(xItem, arg_key);
	CALL rkr$array$push(xItem, arg_value);
	CALL rkr$map$remove(arg_data, arg_key);
	SET arg_data = SUBSTR(arg_data, 3);
	CALL rkr$array$push(arg_data, xItem);
	SET arg_data = CONCAT('m$', arg_data);
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

	IF NOT rkr$map$valid(arg_data) THEN
		LEAVE body;
	END IF;

	SET arg_data = SUBSTR(arg_data, 3);

	WHILE i < xCount DO
		SET xItem = rkr$array$get(i);
		IF rkr$array$get(xItem, 1) = arg_key THEN
			CALL rkr$array$remove(arg_data, i);
			LEAVE body;
		END IF;
		SET i = i + 1;
	END WHILE;

	SET arg_data = CONCAT('m$', arg_data);
END //


DROP PROCEDURE IF EXISTS rkr$map$init //
CREATE PROCEDURE rkr$map$init(INOUT arg_data LONGTEXT CHARSET utf8)
	NO SQL
	SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	IF NOT rkr$map$valid(arg_data) THEN
		SET arg_data = 'm$';
	END IF;
END //


DROP FUNCTION IF EXISTS rkr$map$valid //
CREATE FUNCTION rkr$map$valid(arg_data LONGTEXT CHARSET utf8)
	RETURNS BOOLEAN
	NO SQL
	SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	RETURN IF(SUBSTR(arg_data, 1, 3) = 'm$', true, false);
END //


DELIMITER ;