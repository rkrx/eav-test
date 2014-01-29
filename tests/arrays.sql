DELIMITER ;

SET @debug = '';
SET @data = '';

CALL rkr$array$push(@data, 'A');
CALL rkr$array$push(@data, 'B');

SELECT
  rkr$array$get(@data, 1),
  rkr$array$get(@data, 2);

#SELECT @data, @debug;