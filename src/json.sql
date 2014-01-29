DELIMITER //


DROP FUNCTION IF EXISTS rkr$json$parse;
CREATE FUNCTION rkr$json$parse(arg_src LONGTEXT CHARSET utf8)
	RETURNS LONGTEXT CHARSET utf8
	NO SQL
	SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	DECLARE xCursor INT DEFAULT 1;
	DECLARE xResult LONGTEXT CHARSET utf8 DEFAULT '';

	CALL rkr$debug(arg_src);

	CALL rkr$json$parse_container(arg_src, xCursor, xResult);
	RETURN xResult;
END//


DROP PROCEDURE IF EXISTS rkr$json$parse_container;
CREATE PROCEDURE rkr$json$parse_container(IN arg_src LONGTEXT CHARSET utf8, INOUT arg_cursor INT, OUT arg_result LONGTEXT CHARSET utf8)
	NO SQL
	SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	SET arg_src = LTRIM(arg_src);

	IF SUBSTR(arg_src, arg_cursor, 1) = '{' THEN
		CALL rkr$json$parse_object(arg_src, arg_cursor, arg_result);
	ELSEIF SUBSTR(arg_src, arg_cursor, 1) = '[' THEN
		CALL rkr$json$parse_array(arg_src, arg_cursor, arg_result);
	ELSE
		CALL rkr$exception('rkr$json$parse_container', CONCAT('invalid character found at position ', arg_cursor, ': ', SUBSTR(arg_src, arg_cursor, 1)));
	END IF;
END//


DROP PROCEDURE IF EXISTS rkr$json$parse_object;
CREATE PROCEDURE rkr$json$parse_object(IN arg_src LONGTEXT CHARSET utf8, INOUT arg_cursor INT, OUT arg_result LONGTEXT CHARSET utf8)
	NO SQL
	SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	SET arg_src = LTRIM(arg_src);
	SET arg_cursor = arg_cursor + 1;

	CALL rkr$debug(SUBSTR(arg_src, arg_cursor, 1));
	IF SUBSTR(arg_src, arg_cursor, 1) != '}' THEN
		REPEAT
			CALL rkr$json$parse_object_entity(arg_src, arg_cursor, arg_result);
			SET arg_cursor = arg_cursor + 1;
		UNTIL SUBSTR(arg_src, arg_cursor, 1) NOT IN ('}', ',') END REPEAT;
	ELSE
		CALL rkr$map$init(arg_result, '');
	END IF;
END//


DROP PROCEDURE IF EXISTS rkr$json$parse_array;
CREATE PROCEDURE rkr$json$parse_array(IN arg_src LONGTEXT CHARSET utf8, INOUT arg_cursor INT, OUT arg_result LONGTEXT CHARSET utf8)
	NO SQL
	SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	SET arg_src = LTRIM(arg_src);
	SET arg_cursor = arg_cursor + 1;

	IF SUBSTR(arg_src, arg_cursor, 1) != ']' THEN
		REPEAT
			CALL rkr$json$parse_expression(arg_src, arg_cursor, arg_result);
			SET arg_cursor = arg_cursor + 1;
		UNTIL SUBSTR(arg_src, arg_cursor, 1) NOT IN (']', ',') END REPEAT;
	END IF;
END//


DROP PROCEDURE IF EXISTS rkr$json$parse_object_entity;
CREATE PROCEDURE rkr$json$parse_object_entity(IN arg_src LONGTEXT CHARSET utf8, INOUT arg_cursor INT, OUT arg_result LONGTEXT CHARSET utf8)
	NO SQL
	SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	SET arg_src = LTRIM(arg_src);

	IF SUBSTR(arg_src, arg_cursor, 1) IN ('"', '\'') THEN
		CALL rkr$json$parse_string(arg_src, arg_cursor, arg_result, SUBSTR(arg_src, arg_cursor, 1));
	ELSE
		CALL rkr$json$parse_identifier(arg_src, arg_cursor, arg_result);
	END IF;

	SET arg_cursor = arg_cursor + 1;

	IF SUBSTR(arg_src, arg_cursor, 1) != ':' THEN
		CALL rkr$exception('rkr$json$parse_object_entity', CONCAT('invalid character found at position ', arg_cursor, ': ', SUBSTR(arg_src, arg_cursor, 1)));
	END IF;

	SET arg_cursor = arg_cursor + 1;

	CALL rkr$json$parse_expression(arg_src, arg_cursor, arg_result);
END//


DROP PROCEDURE IF EXISTS rkr$json$parse_expression;
CREATE PROCEDURE rkr$json$parse_expression(IN arg_src LONGTEXT CHARSET utf8, INOUT arg_cursor INT, OUT arg_result LONGTEXT CHARSET utf8)
	NO SQL
	SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	SET arg_src = LTRIM(arg_src);
	# TODO
END//


DROP PROCEDURE IF EXISTS rkr$json$parse_string;
CREATE PROCEDURE rkr$json$parse_string(IN arg_src LONGTEXT CHARSET utf8, INOUT arg_cursor INT, OUT arg_result LONGTEXT CHARSET utf8)
	NO SQL
	SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	SET arg_src = LTRIM(arg_src);
	# TODO
END//


DROP PROCEDURE IF EXISTS rkr$json$parse_identifier;
CREATE PROCEDURE rkr$json$parse_identifier(IN arg_src LONGTEXT CHARSET utf8, INOUT arg_cursor INT, OUT arg_result LONGTEXT CHARSET utf8)
	NO SQL
	SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	SET arg_src = LTRIM(arg_src);
	# TODO
END//


DELIMITER ;
