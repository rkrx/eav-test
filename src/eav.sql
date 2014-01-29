DELIMITER //


DROP FUNCTION IF EXISTS rkr$eav$entity$attribute$get //
CREATE FUNCTION rkr$eav$entity$attribute$get(arg_entity_id CHAR(36) CHARSET latin1, arg_attribute VARCHAR(255) CHARSET latin1, arg_default LONGTEXT CHARSET utf8)
	RETURNS LONGTEXT CHARSET utf8
	SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	DECLARE xId CHAR(36) DEFAULT null;
	DECLARE xType VARCHAR(16) DEFAULT null;
	DECLARE xCheck INT DEFAULT null;
	DECLARE xValue LONGTEXT DEFAULT null;
	
	SET xValue = arg_default;

	IF ISNULL(arg_entity_id) THEN
		RETURN xValue;
	END IF;
	
	SELECT
		id,
		attr_type,
		1
	INTO
		xId,
		xType,
		xCheck
	FROM
		rkr__eav__entity_attributes
	WHERE
		entity_id = arg_entity_id
		AND
		attr_name = arg_attribute;
	
	IF ISNULL(xCheck) THEN
		RETURN xValue;
	END IF;

	IF xType = 'int' THEN
		SELECT attr_value INTO xValue FROM rkr__eav__entity_attribute_values_int WHERE attr_id = xId;
	END IF;
	
	IF xType = 'dec' THEN
		SELECT attr_value INTO xValue FROM rkr__eav__entity_attribute_values_dec WHERE attr_id = xId;
	END IF;
	
	IF xType = 'str' THEN
		SELECT attr_value INTO xValue FROM rkr__eav__entity_attribute_values_str WHERE attr_id = xId;
	END IF;
	
	IF xType = 'date' THEN
		SELECT attr_value INTO xValue FROM rkr__eav__entity_attribute_values_date WHERE attr_id = xId;
	END IF;
	
	RETURN xValue;
END//
DELIMITER ;


DROP FUNCTION IF EXISTS rkr$eav$entity$attribute$has;
DELIMITER //
CREATE FUNCTION rkr$eav$entity$attribute$has(arg_entity_id CHAR(36) CHARSET latin1) RETURNS TINYINT(1)
    READS SQL DATA
    SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	DECLARE xId CHAR(36) DEFAULT null;
	
	SELECT
		id
	INTO
		xId
	FROM
		rkr__eav__entity_attributes
	WHERE
		entity_id = arg_entity_id
	LIMIT 1;
	
	RETURN IF(ISNULL(xId), 0, 1);
END//
DELIMITER ;


DROP PROCEDURE IF EXISTS rkr$eav$entity$attribute$set;
DELIMITER //
CREATE PROCEDURE rkr$eav$entity$attribute$set(IN arg_entity_id CHAR(36) CHARSET latin1, IN arg_attribute VARCHAR(255) CHARSET latin1, IN arg_type VARCHAR(50), IN arg_value LONGTEXT CHARSET utf8)
    MODIFIES SQL DATA
    SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	DECLARE xId CHAR(36) DEFAULT null;
	
	SET xId = UUID();
	
	DELETE FROM rkr__eav__entity_attributes WHERE entity_id=arg_entity_id AND attr_name=arg_attribute;
	
	INSERT INTO
		rkr__eav__entity_attributes
		(id, entity_id, attr_name, attr_type)
	VALUES
		(xId, arg_entity_id, arg_attribute, arg_type);
		
	IF arg_type = 'str' THEN
		INSERT INTO rkr__eav__entity_attribute_values_str SET attr_id=xId, attr_value=arg_value;
	END IF;
		
	IF arg_type = 'int' THEN
		INSERT INTO rkr__eav__entity_attribute_values_int SET attr_id=xId, attr_value=arg_value;
	END IF;
		
	IF arg_type = 'dec' THEN
		INSERT INTO rkr__eav__entity_attribute_values_dec SET attr_id=xId, attr_value=arg_value;
	END IF;
		
	IF arg_type = 'date' THEN
		INSERT INTO rkr__eav__entity_attribute_values_date SET attr_id=xId, attr_value=arg_value;
	END IF;
END//
DELIMITER ;


DROP PROCEDURE IF EXISTS rkr$eav$entity$build_xml_attributes;
DELIMITER //
CREATE PROCEDURE rkr$eav$entity$build_xml_attributes(IN arg_entity_id CHAR(36) CHARSET latin1, IN arg_level INT, OUT arg_out LONGTEXT CHARSET utf8)
	READS SQL DATA
	SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	DECLARE finished INT DEFAULT 0;
	DECLARE attrName VARCHAR(255) DEFAULT '';
	DECLARE attrType LONGTEXT;
	DECLARE attrValue LONGTEXT;
	DECLARE ls VARCHAR(255);
	DECLARE attrCursor CURSOR FOR
		SELECT
			attr_name,
			attr_type
		FROM
			rkr__eav__entity_attributes
		WHERE
			entity_id = arg_entity_id;
		
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;
	
	SET arg_out = '';

	OPEN attrCursor;
	
	getAttributes: LOOP
		FETCH attrCursor INTO attrName, attrType;
		
		IF finished = 1 THEN 
			LEAVE getAttributes;
		END IF;
		
		SET attrValue = rkr$eav$entity$attribute$get(arg_entity_id, attrName, '');
		
		SET ls = REPEAT("\t", arg_level);
		
		SET arg_out = CONCAT(arg_out, 
				ls, '<a type="', attrType, '" name="', rkr$xml$escape(attrName), '">',
					rkr$xml$escape(attrValue),
				'</a>', "\n"
			);
	END LOOP getAttributes;
	
	CLOSE attrCursor;
END//
DELIMITER ;


DROP PROCEDURE IF EXISTS rkr$eav$entity$build_xml_children;
DELIMITER //
CREATE PROCEDURE rkr$eav$entity$build_xml_children(IN arg_id CHAR(36) CHARSET latin1, IN arg_level INT, IN arg_max_level INT, OUT arg_out LONGTEXT CHARSET utf8)
    READS SQL DATA
    SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	DECLARE finished INT DEFAULT 0;
	DECLARE childId CHAR(36) DEFAULT 0;
	DECLARE childCursor CURSOR FOR SELECT id FROM rkr__eav__entities WHERE parent_id = arg_id;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;
	
	SET arg_out = '';
	
	IF arg_max_level > 0 OR ISNULL(arg_max_level) THEN
		IF NOT ISNULL(arg_max_level) THEN
			SET arg_max_level = arg_max_level - 1;
		END IF;

		OPEN childCursor;
		
		getChildren: LOOP
			FETCH childCursor INTO childId;
			
			IF finished = 1 THEN 
				LEAVE getChildren;
			END IF;
			
			CALL rkr$eav$entity$build_xml_from_id(childId, arg_level, arg_max_level, @childContent);
			SET arg_out = CONCAT(arg_out, @childContent);
		END LOOP getChildren;
		
		CLOSE childCursor;
	END IF;
END//
DELIMITER ;


DROP PROCEDURE IF EXISTS rkr$eav$entity$build_xml_from_id;
DELIMITER //
CREATE PROCEDURE rkr$eav$entity$build_xml_from_id(IN arg_id CHAR(36), IN arg_level INT, IN arg_max_level INT, OUT arg_out LONGTEXT CHARSET utf8)
    READS SQL DATA
    SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	DECLARE finished INT DEFAULT 0;
	DECLARE childId CHAR(36) DEFAULT 0;
	DECLARE entityName VARCHAR(255) DEFAULT '';
	DECLARE entityChildren LONGTEXT;
	DECLARE entityAttributes LONGTEXT;
	DECLARE childCursor CURSOR FOR SELECT id FROM rkr__eav__entities WHERE parent_id = arg_id;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;
	
	SET entityName = null;
	SET arg_out = '';

	SELECT
		entity_name
	INTO
		entityName
	FROM
		rkr__eav__entities
	WHERE
		id = arg_id;
	
	IF NOT ISNULL(entityName) THEN
		CALL rkr$eav$entity$build_xml_children(arg_id, arg_level + 1, arg_max_level, entityChildren);
		CALL rkr$eav$entity$build_xml_attributes(arg_id, arg_level + 1, entityAttributes);
		
		SET @ls = REPEAT("\t", arg_level);
		SET arg_out = CONCAT(
				@ls, '<e id="', arg_id, '" name="', rkr$xml$escape(entityName), '">', "\n",
					entityChildren,
					entityAttributes,
				@ls, '</e>', "\n"
			);
	END IF;
END//
DELIMITER ;


DROP FUNCTION IF EXISTS rkr$eav$entity$fetch_xml;
DELIMITER //
CREATE FUNCTION rkr$eav$entity$fetch_xml(arg_path VARCHAR(512) CHARSET latin1, arg_max_level INT)
	RETURNS LONGTEXT CHARSET utf8
    READS SQL DATA
    SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	DECLARE id CHAR(36) DEFAULT null;
	DECLARE res LONGTEXT;
	
	SET id = rkr$eav$entity$get_id_from_path(arg_path, 0);
	CALL rkr$eav$entity$build_xml_from_id(id, 0, arg_max_level, res);
	RETURN res;
END//
DELIMITER ;


DROP FUNCTION IF EXISTS rkr$eav$entity$get_id_from_path;
DELIMITER //
CREATE FUNCTION rkr$eav$entity$get_id_from_path(arg_path VARCHAR(255) CHARSET latin1, createIfMissing TINYINT(1))
	RETURNS CHAR(36) CHARSET latin1
    READS SQL DATA
    SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	DECLARE xPathDepth INT;
	DECLARE i INT DEFAULT 1;
	DECLARE xId CHAR(36) DEFAULT null;
	DECLARE xParentId CHAR(36) DEFAULT null;
	DECLARE xPart VARCHAR(1024) DEFAULT '';

	SET xPathDepth = rkr$eav$path$get_depth(arg_path);
	
	WHILE i <= xPathDepth DO
		SET xPart = rkr$eav$path$get_part(arg_path, i);
		SET xParentId = xId;
		SET xId = null;
		
		SELECT
			id
		INTO
			xId
		FROM
			rkr__eav__entities
		WHERE
			IF(ISNULL(xParentId), ISNULL(parent_id), parent_id = xParentId)
			AND
			entity_name = xPart;
			
		IF ISNULL(xId) THEN
			IF createIfMissing THEN
				SET xId = UUID();
				
				INSERT INTO
					rkr__eav__entities
				SET
					id = xId,
					entity_create_date = NOW(),
					parent_id = xParentId,
					entity_name = xPart;
				
				CALL rkr$eav$entity$update_paths();
			ELSE
				RETURN null;
			END IF;
		END IF;
		
		SET i = i + 1;
	END WHILE;
	
	RETURN xId;
END//
DELIMITER ;


DROP FUNCTION IF EXISTS rkr$eav$entity$get_path_from_id;
DELIMITER //
CREATE FUNCTION rkr$eav$entity$get_path_from_id(arg_id CHAR(36) CHARSET latin1)
	RETURNS VARCHAR(512) CHARSET latin1
    READS SQL DATA
    SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	DECLARE xPath VARCHAR(1024) DEFAULT '';
	DECLARE xName VARCHAR(1024) DEFAULT '';
	DECLARE xId CHAR(36) DEFAULT null;
	DECLARE xParentId CHAR(36) DEFAULT null;
	
	SET xId = arg_id;
	
	REPEAT
		SET xParentId = null;
		SET xName = null;
	
		SELECT
			parent_id,
			entity_name
		INTO
			xParentId,
			xName
		FROM
			rkr__eav__entities
		WHERE
			id = xId;
			
		SET xId = xParentId;
		
		IF NOT ISNULL(xName) THEN
			SET xPath = rkr$eav$path$add(xName, xPath);
		END IF;
	UNTIL ISNULL(xParentId) OR ISNULL(xId) END REPEAT;
	
	RETURN xPath;
END//
DELIMITER ;


DROP FUNCTION IF EXISTS rkr$eav$entity$remove;
DELIMITER //
CREATE FUNCTION rkr$eav$entity$remove(path VARCHAR(512) CHARSET latin1)
	RETURNS TINYINT(1)
    MODIFIES SQL DATA
    SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	DELETE FROM rkr__eav__entities WHERE id = rkr$eav$entity$get_id_from_path(path, 0);
	RETURN ROW_COUNT() > 0;
END//
DELIMITER ;


DROP PROCEDURE IF EXISTS rkr$eav$entity$store_attributes;
DELIMITER //
CREATE PROCEDURE rkr$eav$entity$store_attributes(IN arg_entity_id CHAR(36) CHARSET latin1, IN arg_xpath VARCHAR(512) CHARSET utf8)
    MODIFIES SQL DATA
    SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	DECLARE xAttrCount INT DEFAULT 0;
	DECLARE xAttrName VARCHAR(255) DEFAULT 0;
	DECLARE xAttrType VARCHAR(16) DEFAULT 0;
	DECLARE xAttrValue LONGTEXT DEFAULT 0;
	DECLARE i INT;
	
	SET xAttrCount = EXTRACTVALUE(@rkr$eav$xml_data, CONCAT('count(', arg_xpath, '/a)'));
	
	SET i = 1;
	WHILE i <= xAttrCount DO
		SET xAttrName = EXTRACTVALUE(@rkr$eav$xml_data, CONCAT(arg_xpath, '/a[', i, ']/@name'));
		SET xAttrType = EXTRACTVALUE(@rkr$eav$xml_data, CONCAT(arg_xpath, '/a[', i, ']/@type'));
		SET xAttrValue = EXTRACTVALUE(@rkr$eav$xml_data, CONCAT(arg_xpath, '/a[', i, ']'));
		
		CALL rkr$eav$entity$attribute$set(arg_entity_id, xAttrName, xAttrType, xAttrValue);
		
		SET i = i + 1;
	END WHILE;
END//
DELIMITER ;


DROP PROCEDURE IF EXISTS rkr$eav$entity$store_entity;
DELIMITER //
CREATE PROCEDURE rkr$eav$entity$store_entity(IN arg_entity_id CHAR(36) CHARSET latin1, IN arg_xpath VARCHAR(255) CHARSET utf8)
	MODIFIES SQL DATA
	SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	DECLARE xChildCount INT DEFAULT 0;
	DECLARE xEntityId CHAR(36) DEFAULT null;
	DECLARE xEntityName VARCHAR(255) DEFAULT null;
	DECLARE xAttrCount INT DEFAULT 0;
	DECLARE xAttrName VARCHAR(255) DEFAULT 0;
	DECLARE xAttrType VARCHAR(16) DEFAULT 0;
	DECLARE xAttrValue LONGTEXT DEFAULT 0;
	DECLARE i INT;
	
	SET xEntityName = EXTRACTVALUE(@rkr$eav$xml_data, CONCAT(arg_xpath, '/@name'));
	SET xChildCount = EXTRACTVALUE(@rkr$eav$xml_data, CONCAT('count(', arg_xpath, '/e)'));
	SET xAttrCount = xAttrCount + EXTRACTVALUE(@rkr$eav$xml_data, CONCAT('count(', arg_xpath, '/a)'));
	
	DELETE FROM rkr__eav__entities WHERE parent_id = arg_entity_id AND entity_name = xEntityName;
	
	SET xEntityId = UUID();
	
	INSERT INTO
		rkr__eav__entities
		(id, parent_id, entity_name)
	VALUES
		(xEntityId, arg_entity_id, xEntityName);
	
	SET i = 1;
	WHILE i <= xChildCount DO
		CALL rkr$eav$entity$store_entity(xEntityId, CONCAT(arg_xpath, '/e[', i, ']'));
		SET i = i + 1;
	END WHILE;
		
	CALL rkr$eav$entity$store_attributes(arg_entity_id, arg_xpath);
END//
DELIMITER ;


DROP PROCEDURE IF EXISTS rkr$eav$entity$store_xml;
DELIMITER //
CREATE PROCEDURE rkr$eav$entity$store_xml(IN arg_path VARCHAR(255) CHARSET latin1, IN arg_xml LONGTEXT CHARSET utf8)
    MODIFIES SQL DATA
    SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	DECLARE xEntityId CHAR(36) DEFAULT null;
	DECLARE xStack LONGTEXT;
	
	SET xEntityId = rkr$eav$entity$get_id_from_path(arg_path, 1);

	CALL rkr$stack$push(xStack, @rkr$eav$xml_data);

	SET @rkr$eav$xml_data = arg_xml;
	CALL rkr$eav$entity$store_entity(xEntityId, '/e');
	CALL rkr$eav$entity$update_paths();

	CALL rkr$stack$pop(xStack, @rkr$eav$xml_data);
END//
DELIMITER ;


DROP PROCEDURE IF EXISTS rkr$eav$entity$update_paths;
DELIMITER //
CREATE PROCEDURE rkr$eav$entity$update_paths()
    MODIFIES SQL DATA
    SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	UPDATE
		rkr__eav__entities
	SET
		entity_path = rkr$eav$entity$get_path_from_id(id)
	WHERE
		ISNULL(entity_path);
END//
DELIMITER ;


DROP FUNCTION IF EXISTS rkr$eav$path$add;
DELIMITER //
CREATE FUNCTION rkr$eav$path$add(arg_path VARCHAR(512) CHARSET latin1, arg_part VARCHAR(512) CHARSET latin1)
	RETURNS VARCHAR(512) CHARSET latin1
    NO SQL
    SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	DECLARE res VARCHAR(512);
	SET res = CONCAT(TRIM(BOTH '/' FROM arg_path), '/', TRIM(BOTH '/' FROM arg_part));
	RETURN TRIM(BOTH '/' FROM res);
END//
DELIMITER ;


DROP FUNCTION IF EXISTS rkr$eav$path$get_depth;
DELIMITER //
CREATE FUNCTION rkr$eav$path$get_depth(path VARCHAR(255) CHARSET latin1)
	RETURNS INT(11)
    NO SQL
    DETERMINISTIC
    SQL SECURITY INVOKER
	DETERMINISTIC
BEGIN
	RETURN LENGTH(path) - LENGTH(REPLACE(path, '/', '')) + 1;
END//
DELIMITER ;


DROP FUNCTION IF EXISTS rkr$eav$path$get_part;
DELIMITER //
CREATE FUNCTION rkr$eav$path$get_part(arg_path VARCHAR(255) CHARSET latin1, arg_pos INT)
	RETURNS VARCHAR(255) CHARSET latin1
    NO SQL
    SQL SECURITY INVOKER
    DETERMINISTIC
BEGIN
	DECLARE delimiter CHAR(1) DEFAULT '/';
	RETURN REPLACE(SUBSTRING(SUBSTRING_INDEX(arg_path, delimiter, arg_pos), LENGTH(SUBSTRING_INDEX(arg_path, delimiter, arg_pos - 1)) + 1), delimiter, '');
END//
DELIMITER ;


SOURCE src/eav/schema.sql


SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '');
SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS);
SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT;
