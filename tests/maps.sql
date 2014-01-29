DELIMITER ;

SET @debug = '';
SET @data = '';

CALL rkr$map$set(@data, 'A', 'Hello World');
SET @out = rkr$map$get(@data, 'A', 'ne, nix');

SELECT
	@data,
	@debug,
	@out


#SELECT @data, @debug;