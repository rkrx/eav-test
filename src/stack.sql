DELIMITER //


DROP PROCEDURE IF EXISTS rkr$stack$push//
CREATE PROCEDURE rkr$stack$push(INOUT stack LONGTEXT CHARSET utf8, IN val LONGTEXT CHARSET utf8)
    NO SQL
    SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	DECLARE newStack LONGTEXT CHARSET utf8;
	CALL rkr$array$push(newStack, val);
	CALL rkr$array$push(newStack, stack);
	SET stack = newStack;
END//


DROP PROCEDURE IF EXISTS rkr$stack$pop//
CREATE PROCEDURE rkr$stack$pop(INOUT stack LONGTEXT CHARSET utf8, OUT val LONGTEXT CHARSET utf8)
	NO SQL
	SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	SET val = rkr$array$get(stack, 1);
	SET stack = rkr$array$get(stack, 2);
END//


DELIMITER ;
