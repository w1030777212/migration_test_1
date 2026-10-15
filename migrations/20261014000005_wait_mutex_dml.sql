-- Version 20261014000005: hold one Release task to observe the same-database scheduler gate.
-- This statement does not modify application tables.
SELECT pg_sleep(90);
