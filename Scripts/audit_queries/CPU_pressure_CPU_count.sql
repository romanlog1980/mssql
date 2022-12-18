SELECT ROUND(
           (
               (CONVERT(FLOAT, ws.wait_time_ms) / ws.waiting_tasks_count) / si.os_quantum 
               * scheduler_count
           ),
           2
       ) AS Additional_Sockets_Necessary
FROM   sys.dm_os_wait_stats ws
       CROSS APPLY sys.dm_os_sys_info si
WHERE  ws.wait_type = 'SOS_SCHEDULER_YIELD'