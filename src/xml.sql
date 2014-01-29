DELIMITER //


DROP FUNCTION IF EXISTS rkr$xml$escape//
CREATE FUNCTION rkr$xml$escape(arg_data LONGTEXT CHARSET utf8)
	RETURNS LONGTEXT CHARSET utf8
    NO SQL
    SQL SECURITY INVOKER
    DETERMINISTIC
BEGIN
	SET arg_data = REPLACE(arg_data, '&', '&amp;');
	SET arg_data = REPLACE(arg_data, '<', '&lt;');
	SET arg_data = REPLACE(arg_data, '>', '&gt;');
	SET arg_data = REPLACE(arg_data, '"', '&quot;');
	RETURN arg_data;
END//


DELIMITER ;