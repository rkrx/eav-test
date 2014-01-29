DELIMITER //


DROP PROCEDURE IF EXISTS rkr$stack$push//
CREATE PROCEDURE rkr$stack$push(INOUT stack LONGTEXT CHARSET utf8, IN val LONGTEXT CHARSET utf8)
    NO SQL
    SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	IF ISNULL(val) THEN
		SET stack = CONCAT('N:::', stack);
	ELSE
		SET stack = CONCAT('S:', LENGTH(val), ':', val, ':', stack);
	END IF;
END//


DROP PROCEDURE IF EXISTS rkr$stack$pop//
CREATE PROCEDURE rkr$stack$pop(INOUT stack LONGTEXT CHARSET utf8, OUT val LONGTEXT CHARSET utf8)
	NO SQL
	SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	DECLARE type CHAR CHARSET utf8;
	DECLARE pos INT;
	DECLARE len INT;

	SET type = SUBSTR(stack, 1, 1);

	IF type = 'N' THEN
		SET val = null;
		SET stack = SUBSTRING(stack, 5);
	ELSE
		SET pos = LOCATE(':', stack, 3);
		SET len = SUBSTRING(stack, 3, pos - 3);
		SET val = SUBSTRING(stack, pos + 1, len);
		SET stack = SUBSTRING(stack, pos + len + 2);
	END IF;
END//


DELIMITER ;
