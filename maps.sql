SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT;
SET NAMES utf8;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO';


DROP FUNCTION IF EXISTS rkr__map__get;
DELIMITER //
CREATE FUNCTION rkr__map__get(arg_data LONGTEXT CHARSET utf8, arg_key VARCHAR(512) CHARSET utf8, arg_default LONGTEXT CHARSET utf8)
	RETURNS LONGTEXT CHARSET utf8
    NO SQL
    SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	DECLARE xCount INT DEFAULT rkr__array__count(arg_data);
	DECLARE xItem LONGTEXT CHARSET utf8;
	DECLARE i INT DEFAULT 1;

	WHILE i < xCount DO
		SET xItem = rkr__array__get(i);
		IF rkr__array__get(xItem, 1) = arg_key THEN
			RETURN rkr__array__get(xItem, 2);
		END IF;
		SET i = i + 1;
	END WHILE;

	RETURN arg_default;
END//
DELIMITER ;


DROP PROCEDURE IF EXISTS rkr__map__set;
DELIMITER //
CREATE PROCEDURE rkr__map__set(INOUT arg_data LONGTEXT CHARSET utf8, IN arg_key LONGTEXT CHARSET utf8, IN arg_value LONGTEXT CHARSET utf8)
    NO SQL
    SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	DECLARE xCount INT DEFAULT rkr__array__count(arg_data);
	DECLARE xItem LONGTEXT CHARSET utf8;
	DECLARE i INT DEFAULT 1;

	CALL rkr__array__push(xItem, arg_key);
	CALL rkr__array__push(xItem, arg_value);
	CALL rkr__map__remove(arg_data, arg_key);
	CALL rkr__array__push(arg_data, xItem);
END//
DELIMITER ;


DROP PROCEDURE IF EXISTS rkr__map__remove;
DELIMITER //
CREATE PROCEDURE rkr__map__remove(INOUT arg_data LONGTEXT CHARSET utf8, arg_key VARCHAR(512) CHARSET utf8)
	NO SQL
	SQL SECURITY INVOKER
	DETERMINISTIC
body: BEGIN
	DECLARE xCount INT DEFAULT rkr__array__count(arg_data);
	DECLARE xItem LONGTEXT CHARSET utf8;
	DECLARE i INT DEFAULT 1;

	WHILE i < xCount DO
		SET xItem = rkr__array__get(i);
		IF rkr__array__get(xItem, 1) = arg_key THEN
			CALL rkr__array__remove(arg_data, i);
			LEAVE body;
		END IF;
		SET i = i + 1;
	END WHILE;
END//
DELIMITER ;


SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '');
SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS);
SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT;
