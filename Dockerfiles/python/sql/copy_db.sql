-- Kill all session in database
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = 'calque_planta'
AND pid <> pg_backend_pid();

-- Copy existing database
CREATE DATABASE calque_planta_temp WITH TEMPLATE calque_planta OWNER adm;
