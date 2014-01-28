/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;


CREATE TABLE IF NOT EXISTS `eav__attributes` (
  `id` char(36) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL DEFAULT '',
  `entity_id` char(36) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL DEFAULT '',
  `attr_name` varchar(128) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL DEFAULT '',
  `attr_type` enum('int','dec','str','date') CHARACTER SET latin1 COLLATE latin1_bin NOT NULL DEFAULT 'str',
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_attribute` (`entity_id`,`attr_name`),
  CONSTRAINT `FK_eav__attributes_eav__entities` FOREIGN KEY (`entity_id`) REFERENCES `eav__entities` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


CREATE TABLE IF NOT EXISTS `eav__entities` (
  `id` char(36) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL DEFAULT '',
  `parent_id` char(36) CHARACTER SET latin1 COLLATE latin1_bin DEFAULT NULL,
  `entity_create_date` datetime DEFAULT '2000-01-01 00:00:00',
  `entity_modify_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `entity_path` varchar(1024) CHARACTER SET latin1 COLLATE latin1_bin DEFAULT NULL,
  `entity_name` varchar(255) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `entity_name` (`entity_name`,`parent_id`),
  KEY `entity_path` (`entity_path`(255)),
  KEY `FK_eav__entities_eav__entities` (`parent_id`),
  CONSTRAINT `FK_eav__entities_eav__entities` FOREIGN KEY (`parent_id`) REFERENCES `eav__entities` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


DELIMITER //
CREATE FUNCTION `eav__entity__attribute__get`(`arg_entity_id` CHAR(36), `arg_attribute` VARCHAR(255), `arg_default` LONGTEXT) RETURNS longtext CHARSET latin1
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
		eav__attributes
	WHERE
		entity_id = arg_entity_id
		AND
		attr_name = arg_attribute;
	
	IF ISNULL(xCheck) THEN
		RETURN xValue;
	END IF;

	IF xType = 'int' THEN
		SELECT attr_value INTO xValue FROM eav__values_int WHERE attr_id = xId;
	END IF;
	
	IF xType = 'dec' THEN
		SELECT attr_value INTO xValue FROM eav__values_dec WHERE attr_id = xId;
	END IF;
	
	IF xType = 'str' THEN
		SELECT attr_value INTO xValue FROM eav__values_str WHERE attr_id = xId;
	END IF;
	
	IF xType = 'date' THEN
		SELECT attr_value INTO xValue FROM eav__values_date WHERE attr_id = xId;
	END IF;
	
	RETURN xValue;
END//
DELIMITER ;


DELIMITER //
CREATE FUNCTION `eav__entity__attribute__has`(`arg_entity_id` CHAR(36)) RETURNS tinyint(1)
    READS SQL DATA
    SQL SECURITY INVOKER
BEGIN
	DECLARE xId CHAR(36) DEFAULT null;
	
	SELECT
		id
	INTO
		xId
	FROM
		eav__attributes
	WHERE
		entity_id = arg_entity_id
	LIMIT 1;
	
	RETURN IF(ISNULL(xId), 0, 1);
END//
DELIMITER ;


DELIMITER //
CREATE PROCEDURE `eav__entity__attribute__set`(IN `arg_entity_id` CHAR(36), IN `arg_attribute` VARCHAR(255), IN `arg_type` VARCHAR(50), IN `arg_value` LONGTEXT)
    MODIFIES SQL DATA
    SQL SECURITY INVOKER
BEGIN
	DECLARE xId CHAR(36) DEFAULT null;
	
	SET xId = UUID();
	
	DELETE FROM eav__attributes WHERE entity_id=arg_entity_id AND attr_name=arg_attribute;
	
	INSERT INTO
		eav__attributes
		(id, entity_id, attr_name, attr_type)
	VALUES
		(xId, arg_entity_id, arg_attribute, arg_type);
		
	IF arg_type = "str" THEN
		INSERT INTO eav__values_str SET attr_id=xId, attr_value=arg_value;
	END IF;
		
	IF arg_type = "int" THEN
		INSERT INTO eav__values_int SET attr_id=xId, attr_value=arg_value;
	END IF;
		
	IF arg_type = "dec" THEN
		INSERT INTO eav__values_dec SET attr_id=xId, attr_value=arg_value;
	END IF;
		
	IF arg_type = "date" THEN
		INSERT INTO eav__values_date SET attr_id=xId, attr_value=arg_value;
	END IF;
END//
DELIMITER ;


DELIMITER //
CREATE PROCEDURE `eav__entity__build_xml_attributes`(IN `arg_entity_id` CHAR(36), IN `arg_level` INT, OUT `arg_out` longtEXT)
BEGIN
	DECLARE finished INT DEFAULT 0;
	DECLARE attrName VARCHAR(255) DEFAULT "";
	DECLARE attrType LONGTEXT;
	DECLARE attrValue LONGTEXT;
	DECLARE ls VARCHAR(255);
	DECLARE attrCursor CURSOR FOR
		SELECT
			attr_name,
			attr_type
		FROM
			eav__attributes
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
		
		SET attrValue = eav__entity__attribute__get(arg_entity_id, attrName, "");
		
		SET ls = REPEAT("\t", arg_level);
		
		SET arg_out = CONCAT(arg_out, 
				ls, '<a type="', attrType, '" name="', eav__xml__escape(attrName), '">', eav__xml__escape(attrValue), '</a>', "\n"
			);
	END LOOP getAttributes;
	
	CLOSE attrCursor;
END//
DELIMITER ;


DELIMITER //
CREATE PROCEDURE `eav__entity__build_xml_children`(IN `arg_id` CHAR(36), IN `arg_level` INT, IN `arg_max_level` INT, OUT `arg_out` LONGTEXT)
    READS SQL DATA
    SQL SECURITY INVOKER
BEGIN
	DECLARE finished INT DEFAULT 0;
	DECLARE childId CHAR(36) DEFAULT 0;
	DECLARE childCursor CURSOR FOR SELECT id FROM eav__entities WHERE parent_id = arg_id;
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
			
			CALL eav__entity__build_xml_from_id(childId, arg_level, arg_max_level, @childContent);
			SET arg_out = CONCAT(arg_out, @childContent);
		END LOOP getChildren;
		
		CLOSE childCursor;
	END IF;
END//
DELIMITER ;


DELIMITER //
CREATE PROCEDURE `eav__entity__build_xml_from_id`(IN `arg_id` CHAR(36), IN `arg_level` INT, IN `arg_max_level` INT, OUT `arg_out` LONGTEXT)
    READS SQL DATA
    SQL SECURITY INVOKER
BEGIN
	DECLARE finished INT DEFAULT 0;
	DECLARE childId CHAR(36) DEFAULT 0;
	DECLARE entityName VARCHAR(255) DEFAULT '';
	DECLARE entityChildren LONGTEXT;
	DECLARE entityAttributes LONGTEXT;
	DECLARE childCursor CURSOR FOR SELECT id FROM eav__entities WHERE parent_id = arg_id;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;
	
	SET entityName = null;
	SET arg_out = '';

	SELECT
		entity_name
	INTO
		entityName
	FROM
		eav__entities
	WHERE
		id = arg_id;
	
	IF NOT ISNULL(entityName) THEN
		CALL eav__entity__build_xml_children(arg_id, arg_level + 1, arg_max_level, entityChildren);
		CALL eav__entity__build_xml_attributes(arg_id, arg_level + 1, entityAttributes);
		
		SET @ls = REPEAT("\t", arg_level);
		SET arg_out = CONCAT(
				@ls, '<e id="', arg_id, '" name="', eav__xml__escape(entityName), '">', "\n",
					entityChildren,
					entityAttributes,
				@ls, '</e>', "\n"
			);
	END IF;
END//
DELIMITER ;


DELIMITER //
CREATE FUNCTION `eav__entity__fetch_xml`(`arg_path` VARCHAR(512), `arg_max_level` INT) RETURNS longtext CHARSET latin1
    READS SQL DATA
    SQL SECURITY INVOKER
BEGIN
	DECLARE id CHAR(36) DEFAULT null;
	DECLARE res LONGTEXT;
	
	SET id = eav__entity__get_id_from_path(arg_path, 0);
	CALL eav__entity__build_xml_from_id(id, 0, arg_max_level, res);
	RETURN res;
END//
DELIMITER ;


DELIMITER //
CREATE FUNCTION `eav__entity__get_id_from_path`(`path` VARCHAR(255), `createIfMissing` TINYINT(1)) RETURNS char(36) CHARSET latin1
    READS SQL DATA
    SQL SECURITY INVOKER
BEGIN
	DECLARE xPathDepth INT;
	DECLARE i INT DEFAULT 1;
	DECLARE xId CHAR(36) DEFAULT null;
	DECLARE xParentId CHAR(36) DEFAULT null;
	DECLARE xPart VARCHAR(1024) DEFAULT "";

	SET xPathDepth = eav__path__get_depth(path);
	
	WHILE i <= xPathDepth DO
		SET xPart = eav__path__get_part(path, i);
		SET xParentId = xId;
		SET xId = null;
		
		SELECT
			id
		INTO
			xId
		FROM
			eav__entities
		WHERE
			IF(ISNULL(xParentId), ISNULL(parent_id), parent_id = xParentId)
			AND
			entity_name = xPart;
			
		IF ISNULL(xId) THEN
			IF createIfMissing THEN
				SET xId = UUID();
				
				INSERT INTO
					eav__entities
				SET
					id = xId,
					entity_create_date = NOW(),
					parent_id = xParentId,
					entity_name = xPart;
				
				CALL eav__entity__update_paths();
			ELSE
				RETURN null;
			END IF;
		END IF;
		
		SET i = i + 1;
	END WHILE;
	
	RETURN xId;
END//
DELIMITER ;


DELIMITER //
CREATE FUNCTION `eav__entity__get_path_from_id`(`arg_id` CHAR(36)) RETURNS varchar(512) CHARSET latin1
    READS SQL DATA
    SQL SECURITY INVOKER
BEGIN
	DECLARE xPath VARCHAR(1024) DEFAULT "";
	DECLARE xName VARCHAR(1024) DEFAULT "";
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
			eav__entities
		WHERE
			id = xId;
			
		SET xId = xParentId;
		
		IF NOT ISNULL(xName) THEN
			SET xPath = eav__path__add(xName, xPath);
		END IF;
	UNTIL ISNULL(xParentId) OR ISNULL(xId) END REPEAT;
	
	RETURN xPath;
END//
DELIMITER ;


DELIMITER //
CREATE FUNCTION `eav__entity__remove`(`path` VARCHAR(512)) RETURNS tinyint(1)
    MODIFIES SQL DATA
    SQL SECURITY INVOKER
BEGIN
	DELETE FROM eav__entities WHERE id = eav__entity__get_id_from_path(path, 0);
	RETURN ROW_COUNT() > 0;
END//
DELIMITER ;


DELIMITER //
CREATE DEFINER=`root`@`%` PROCEDURE `eav__entity__store_attributes`(IN `arg_entity_id` CHAR(36), IN `arg_xml` LONGTEXT, IN `arg_xpath` VARCHAR(512))
    MODIFIES SQL DATA
    SQL SECURITY INVOKER
BEGIN
	DECLARE xAttrCount INT DEFAULT 0;
	DECLARE xAttrName VARCHAR(255) DEFAULT 0;
	DECLARE xAttrType VARCHAR(16) DEFAULT 0;
	DECLARE xAttrValue LONGTEXT DEFAULT 0;
	DECLARE i INT;
	
	SET xAttrCount = EXTRACTVALUE(arg_xml, CONCAT('count(', arg_xpath, '/a)'));
	
	SET i = 1;
	WHILE i <= xAttrCount DO
		SET xAttrName = EXTRACTVALUE(arg_xml, CONCAT(arg_xpath, '/a[', i, ']/@name'));
		SET xAttrType = EXTRACTVALUE(arg_xml, CONCAT(arg_xpath, '/a[', i, ']/@type'));
		SET xAttrValue = EXTRACTVALUE(arg_xml, CONCAT(arg_xpath, '/a[', i, ']'));
		
		CALL eav__entity__attribute__set(arg_entity_id, xAttrName, xAttrType, xAttrValue);
		
		SET i = i + 1;
	END WHILE;
END//
DELIMITER ;


DELIMITER //
CREATE PROCEDURE `eav__entity__store_entity`(IN `arg_entity_id` CHAR(36), IN `arg_xml` LONGTEXT, IN `arg_xpath` VARCHAR(255))
BEGIN
	DECLARE xChildCount INT DEFAULT 0;
	DECLARE xEntityId CHAR(36) DEFAULT null;
	DECLARE xEntityName VARCHAR(255) DEFAULT null;
	DECLARE xAttrCount INT DEFAULT 0;
	DECLARE xAttrName VARCHAR(255) DEFAULT 0;
	DECLARE xAttrType VARCHAR(16) DEFAULT 0;
	DECLARE xAttrValue LONGTEXT DEFAULT 0;
	DECLARE i INT;
	
	SET xEntityName = EXTRACTVALUE(arg_xml, CONCAT(arg_xpath, '/@name'));
	SET xChildCount = EXTRACTVALUE(arg_xml, CONCAT('count(', arg_xpath, '/e)'));
	SET xAttrCount = xAttrCount + EXTRACTVALUE(arg_xml, CONCAT('count(', arg_xpath, '/a)'));
	
	DELETE FROM eav__entities WHERE parent_id = arg_entity_id AND entity_name = xEntityName;
	
	SET xEntityId = UUID();
	
	INSERT INTO
		eav__entities
		(id, parent_id, entity_name)
	VALUES
		(xEntityId, arg_entity_id, xEntityName);
	
	SET i = 1;
	WHILE i <= xChildCount DO
		CALL eav__entity__store_entity(xEntityId, arg_xml, CONCAT(arg_xpath, '/e[', i, ']'));
		SET i = i + 1;
	END WHILE;
		
	CALL eav__entity__store_attributes(arg_entity_id, arg_xml, arg_xpath);
END//
DELIMITER ;


DELIMITER //
CREATE PROCEDURE `eav__entity__store_xml`(IN `arg_path` VARCHAR(255), IN `arg_xml` LONGTEXT)
    MODIFIES SQL DATA
    SQL SECURITY INVOKER
BEGIN
	DECLARE xEntityId CHAR(36) DEFAULT null;
	
	SET xEntityId = eav__entity__get_id_from_path(arg_path, 1);
	CALL eav__entity__store_entity(xEntityId, arg_xml, '/e');
	CALL eav__entity__update_paths();
END//
DELIMITER ;


DELIMITER //
CREATE PROCEDURE `eav__entity__update_paths`()
    MODIFIES SQL DATA
    SQL SECURITY INVOKER
BEGIN
	UPDATE
		eav__entities
	SET
		entity_path = eav__entity__get_path_from_id(id)
	WHERE
		ISNULL(entity_path);
END//
DELIMITER ;


DELIMITER //
CREATE DEFINER=`root`@`%` FUNCTION `eav__path__add`(`arg_path` VARCHAR(512), `arg_part` VARCHAR(512)) RETURNS varchar(512) CHARSET latin1
    NO SQL
    DETERMINISTIC
    SQL SECURITY INVOKER
BEGIN
	DECLARE res VARCHAR(512);
	SET res = CONCAT(TRIM(BOTH '/' FROM arg_path), '/', TRIM(BOTH '/' FROM arg_part));
	RETURN TRIM(BOTH '/' FROM res);
END//
DELIMITER ;


DELIMITER //
CREATE FUNCTION `eav__path__get_depth`(`path` varchar(255)) RETURNS int(11)
    NO SQL
    DETERMINISTIC
    SQL SECURITY INVOKER
BEGIN
	RETURN LENGTH(path) - LENGTH(REPLACE(path, '/', '')) + 1;
END//
DELIMITER ;


DELIMITER //
CREATE FUNCTION `eav__path__get_part`(`arg_path` VARCHAR(255), `arg_pos` INT) RETURNS varchar(255) CHARSET latin1
    NO SQL
    DETERMINISTIC
    SQL SECURITY INVOKER
BEGIN
	DECLARE delimiter CHAR(1) DEFAULT '/';
	RETURN REPLACE(SUBSTRING(SUBSTRING_INDEX(arg_path, delimiter, arg_pos), LENGTH(SUBSTRING_INDEX(arg_path, delimiter, arg_pos - 1)) + 1), delimiter, '');
END//
DELIMITER ;


CREATE TABLE IF NOT EXISTS `eav__values_date` (
  `attr_id` char(36) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL DEFAULT '',
  `attr_value` datetime DEFAULT NULL,
  PRIMARY KEY (`attr_id`),
  CONSTRAINT `FK_eav__values_date_eav__attributes` FOREIGN KEY (`attr_id`) REFERENCES `eav__attributes` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


CREATE TABLE IF NOT EXISTS `eav__values_dec` (
  `attr_id` char(36) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL DEFAULT '',
  `attr_value` double DEFAULT NULL,
  PRIMARY KEY (`attr_id`),
  CONSTRAINT `FK_eav__values_dec_eav__attributes` FOREIGN KEY (`attr_id`) REFERENCES `eav__attributes` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


CREATE TABLE IF NOT EXISTS `eav__values_int` (
  `attr_id` char(36) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL DEFAULT '',
  `attr_value` int(11) DEFAULT NULL,
  PRIMARY KEY (`attr_id`),
  CONSTRAINT `FK_eav__values_int_eav__attributes` FOREIGN KEY (`attr_id`) REFERENCES `eav__attributes` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


CREATE TABLE IF NOT EXISTS `eav__values_str` (
  `attr_id` char(36) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL DEFAULT '',
  `attr_value` longtext COLLATE utf8_unicode_ci,
  PRIMARY KEY (`attr_id`),
  CONSTRAINT `FK_eav__values_str_eav__attributes` FOREIGN KEY (`attr_id`) REFERENCES `eav__attributes` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


DELIMITER //
CREATE FUNCTION `eav__xml__escape`(`arg_data` LONGTEXT) RETURNS longtext CHARSET latin1
    NO SQL
    DETERMINISTIC
    SQL SECURITY INVOKER
BEGIN
	SET @xmlData = arg_data;
	SET @xmlData = REPLACE(@xmlData, '&', '&amp;');
	SET @xmlData = REPLACE(@xmlData, '<', '&lt;');
	SET @xmlData = REPLACE(@xmlData, '>', '&gt;');
	SET @xmlData = REPLACE(@xmlData, '"', '&quot;');
	RETURN @xmlData;
END//
DELIMITER ;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
