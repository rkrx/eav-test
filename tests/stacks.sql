SET @debug = '';
SET @stack = '';
SET @val = '';

CALL rkr$stack$push(@stack, 'a');
CALL rkr$stack$push(@stack, 'b');
CALL rkr$stack$push(@stack, 'c');

CALL rkr$debug(@stack);

CALL rkr$stack$pop(@stack, @val);
CALL rkr$debug(@val);

CALL rkr$stack$pop(@stack, @val);
CALL rkr$debug(@val);

CALL rkr$stack$pop(@stack, @val);
CALL rkr$debug(@val);

SELECT @debug;


