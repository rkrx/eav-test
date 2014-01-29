CREATE TABLE IF NOT EXISTS rkr__eav__entities (
	id CHAR(36) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL DEFAULT '',
	parent_id CHAR(36) CHARACTER SET latin1 COLLATE latin1_bin DEFAULT NULL,
	entity_create_date datetime DEFAULT '2000-01-01 00:00:00',
	entity_modify_date timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	entity_path VARCHAR(1024) CHARACTER SET latin1 COLLATE latin1_bin DEFAULT NULL,
	entity_name VARCHAR(255) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL DEFAULT '',
	PRIMARY KEY (id),
	UNIQUE KEY entity_name (entity_name, parent_id),
	KEY entity_path (entity_path(255)),
	KEY FK_rkr__eav__entities_rkr__eav__entities (parent_id),
	CONSTRAINT FK_rkr__eav__entities_rkr__eav__entities FOREIGN KEY (parent_id) REFERENCES rkr__eav__entities (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


CREATE TABLE IF NOT EXISTS rkr__eav__entity_attributes (
	id CHAR(36) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL DEFAULT '',
	entity_id CHAR(36) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL DEFAULT '',
	attr_name VARCHAR(128) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL DEFAULT '',
	attr_type ENUM('int','dec','str','date') CHARACTER SET latin1 COLLATE latin1_bin NOT NULL DEFAULT 'str',
	PRIMARY KEY (id),
	UNIQUE KEY unique_attribute (entity_id, attr_name),
	CONSTRAINT FK_rkr__eav__attributes_rkr__eav__entities FOREIGN KEY (entity_id) REFERENCES rkr__eav__entities (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


CREATE TABLE IF NOT EXISTS rkr__eav__entity_attribute_values_date (
	attr_id CHAR(36) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL DEFAULT '',
	attr_value DATETIME DEFAULT NULL,
	PRIMARY KEY (attr_id),
	CONSTRAINT FK_rkr__eav__values_date_rkr__eav__attributes FOREIGN KEY (attr_id) REFERENCES rkr__eav__entity_attributes (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


CREATE TABLE IF NOT EXISTS rkr__eav__entity_attribute_values_dec (
	attr_id CHAR(36) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL DEFAULT '',
	attr_value DOUBLE DEFAULT NULL,
	PRIMARY KEY (attr_id),
	CONSTRAINT FK_rkr__eav__values_dec_rkr__eav__attributes FOREIGN KEY (attr_id) REFERENCES rkr__eav__entity_attributes (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


CREATE TABLE IF NOT EXISTS rkr__eav__entity_attribute_values_int (
	attr_id CHAR(36) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL DEFAULT '',
	attr_value INT(11) DEFAULT NULL,
	PRIMARY KEY (attr_id),
	CONSTRAINT FK_rkr__eav__values_int_rkr__eav__attributes FOREIGN KEY (attr_id) REFERENCES rkr__eav__entity_attributes (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


CREATE TABLE IF NOT EXISTS rkr__eav__entity_attribute_values_str (
	attr_id CHAR(36) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL DEFAULT '',
	attr_value longtext COLLATE utf8_unicode_ci,
	PRIMARY KEY (attr_id),
	CONSTRAINT FK_rkr__eav__values_str_rkr__eav__attributes FOREIGN KEY (attr_id) REFERENCES rkr__eav__entity_attributes (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
