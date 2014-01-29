DELIMITER //


DROP PROCEDURE IF EXISTS rkr$array$push //
CREATE PROCEDURE rkr$array$push(INOUT arg_data LONGTEXT CHARSET utf8, IN arg_value LONGTEXT CHARSET utf8)
    NO SQL
    SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	SET arg_data = CONCAT(
		arg_data,
		LENGTH(IFNULL(arg_value, '')),
		':',
		IF(ISNULL(arg_value), 'N', 'S'),
		':',
		IFNULL(arg_value, ''),
		';'
	);
END//


DROP FUNCTION IF EXISTS rkr$array$count //
CREATE FUNCTION rkr$array$count(arg_data LONGTEXT CHARSET utf8)
	RETURNS INT
    NO SQL
    SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	DECLARE xPos INT;
	DECLARE xPartPos INT;
	DECLARE xPartLen INT;
	DECLARE xLen INT;
	DECLARE i INT DEFAULT 0;

	SET xLen = LENGTH(arg_data);

	WHILE xPos < xLen DO
		SET xPartPos = LOCATE(':', arg_data, xPos);
		SET xPartLen = SUBSTR(arg_data, xPos, xPartPos - xPos);
		SET xPos = xPartPos + 3 + xPartLen + 1;
		SET i = i + 1;
	END WHILE;

	RETURN i;
END//


DROP PROCEDURE IF EXISTS rkr$array$index__get_location //
CREATE PROCEDURE rkr$array$index__get_location(arg_data LONGTEXT CHARSET utf8, arg_index INT, INOUT arg_pos INT, INOUT arg_start INT, INOUT arg_len INT)
    NO SQL
    SQL SECURITY INVOKER
	DETERMINISTIC
body: BEGIN
	DECLARE xPartPos INT;
	DECLARE xPartLen INT;
	DECLARE xLen INT;
	DECLARE i INT DEFAULT 1;

	SET xLen = LENGTH(arg_data);

	IF arg_index < 1 OR arg_pos < 1 THEN
		LEAVE body;
	END IF;

	WHILE arg_pos < xLen DO
		SET xPartPos = LOCATE(':', arg_data, arg_pos);
		SET xPartLen = SUBSTR(arg_data, arg_pos, xPartPos - arg_pos);

		IF i = arg_index THEN
			SET arg_start = xPartPos + 3;
			SET arg_len = xPartLen;
			LEAVE body;
		END IF;

		SET arg_pos = xPartPos + 3 + xPartLen + 1;
		SET i = i + 1;
	END WHILE;

	SET arg_pos = 0;
END//


DROP FUNCTION IF EXISTS rkr$array$get //
CREATE FUNCTION rkr$array$get(arg_data LONGTEXT CHARSET utf8, arg_index INT)
	RETURNS LONGTEXT CHARSET utf8
    NO SQL
    SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	DECLARE xPos INT DEFAULT 1;
	DECLARE xStart INT DEFAULT 0;
	DECLARE xLen INT DEFAULT 0;

	CALL rkr$array$index__get_location(arg_data, arg_index, xPos, xStart, xLen);

	IF SUBSTR(arg_data, xStart - 2, 1) = 'N' THEN
		RETURN null;
	END IF;

	RETURN SUBSTR(arg_data, xStart, xLen);
END//


DROP PROCEDURE IF EXISTS rkr$array$remove //
CREATE PROCEDURE rkr$array$remove(INOUT arg_data LONGTEXT CHARSET utf8, IN arg_index INT)
    NO SQL
    SQL SECURITY INVOKER
	DETERMINISTIC
body: BEGIN
	DECLARE xPos INT DEFAULT 1;
	DECLARE xStart INT;
	DECLARE xLen INT;

	IF arg_index < 1 THEN
		LEAVE body;
	END IF;

	CALL rkr$array$index__get_location(arg_data, arg_index, xPos, xStart, xLen);

	IF IFNULL(xPos, 0) < 1 THEN
		LEAVE body;
	END IF;

	SET arg_data = CONCAT(
		SUBSTR(arg_data, 1, xPos - 1),
		SUBSTR(arg_data, xStart + xLen + 1)
	);
END//


DELIMITER ;
