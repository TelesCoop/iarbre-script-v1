SELECT 
    pid
    ,datname
    ,usename
    ,application_name
    ,client_hostname
    ,client_port
    ,backend_start
    ,query_start
    ,query  
FROM pg_stat_activity
WHERE state <> 'idle'
AND pid<>pg_backend_pid();