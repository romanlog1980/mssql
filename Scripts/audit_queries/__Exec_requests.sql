 

SELECT qs.session_id, ex.login_time, ex.[host_name], ex.program_name,
       qs.database_id, qs.command,
       qs.STATUS,
       qs.wait_type,
       qs.wait_time,
       qs.wait_resource,
       qs.total_elapsed_time / 1000 AS total_elapsed_time,
       qs.cpu_time,
       qs.reads,
       qs.writes,
       [Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, 
         (CASE WHEN qs.statement_end_offset = -1 
            THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
          ELSE qs.statement_end_offset END - qs.statement_start_offset)/2)
,[Parent Query] = qt.text
FROM   sys.dm_exec_requests qs
       CROSS APPLY sys.dm_exec_sql_text(sql_handle) qt
	   INNER JOIN sys.dm_exec_sessions ex
	   ON ex.session_id = qs.session_id
	
WHERE  qs.database_id = 43
ORDER BY
       qs.session_id