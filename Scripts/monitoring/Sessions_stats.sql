DECLARE @AlertTitle VARCHAR(4000) = 'Статистика по сессиям',
        @DB SYSNAME,
        @AlertSubject VARCHAR(4000)
		

DECLARE @MailBody         VARCHAR(MAX),
        @Body1            VARCHAR(MAX),
        @Body2            VARCHAR(MAX),
        @TableTail        VARCHAR(MAX),
        @TableHeader1     VARCHAR(MAX),
        @TableHeader2     VARCHAR(MAX),
        @CPU NUMERIC(7,3)
        
SELECT @CPU = CAST(
       CASE 
            WHEN perfBase.cntr_value = 0 THEN 0
            ELSE (CAST(perfCount.cntr_value AS FLOAT) / perfBase.cntr_value) *
                 100
       END AS NUMERIC(7, 3) ) 
FROM   (
           SELECT *
           FROM   sys.dm_os_performance_counters
           WHERE  OBJECT_NAME           = 'MSSQL$SQL2016:Workload Group Stats'
                  AND counter_name      = 'CPU usage %'
                  AND instance_name     = 'default'
       ) perfCount
       INNER JOIN (
                SELECT *
                FROM   sys.dm_os_performance_counters
                WHERE  OBJECT_NAME           = 'MSSQL$SQL2016:Workload Group Stats'
                       AND counter_name      = 'CPU usage % base'
                       AND instance_name     = 'default'
            ) perfBase
            ON  perfCount.Object_name = perfBase.object_name
            AND perfBase.instance_name = perfCount.instance_name
 SELECT @AlertSubject = 'Alert: Нагрузка на CPU SQL Server: ' + CONVERT(VARCHAR(7), @CPU) + '%, сводка по сессиям SQL Server'
 SELECT @AlertSubject

SET @TableTail = '</table></body><br /><br /></html>';
SET @TableHeader1 = '<html><head>' + '<style>'
    +
    'td {border: solid black;border-width: 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font: 11px arial} '
    + '</style>' + '</head>' + '<body>' + @AlertTitle +
    ' по состоянию на: ' + CONVERT(VARCHAR(50), GETDATE(), 121) 
    + ' <br> <table cellpadding=0 cellspacing=0 border=0>' 
    + '<tr> '
    + '<td bgcolor=#0099FF><b>Статус</b></td>'
    + '<td bgcolor=#0099FF><b>Кол-во сессий</b></td>'
    + '<td bgcolor=#0099FF><b>Среднее время ожидания</b></td>'
    + '<td bgcolor=#0099FF><b>Максимальное время ожидания</b></td>'
    + '</tr>';


SET @Body1 = (
        SELECT td = ISNULL(der.wait_type, der.STATUS),
               '',
               td     = COUNT(*),
               '',
               td     = AVG(der.wait_time),
               '',
               td     = MAX(der.wait_time)
        FROM   sys.dm_exec_requests AS der
               INNER JOIN sys.dm_exec_sessions AS des1
                    ON  der.session_id = des1.session_id
        WHERE  des1.is_user_process = 1
        GROUP BY
               ISNULL(der.wait_type, der.STATUS)
        ORDER BY
               COUNT(*) DESC
               FOR XML PATH('tr'),
               ELEMENTS
    )

SELECT @Body1 = @TableHeader1 + REPLACE(REPLACE(@Body1, '&lt;', '<'), '&gt;', '>') 
       + @TableTail

--SELECT @Body1

SET @TableHeader2 = '<html><head>' + '<style>'
    +
    'td {border: solid black;border-width: 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font: 11px arial} '
    + '</style>' + '</head>' + '<body>' +
    'Список выполнявшихся запросов по состоянию на: ' + CONVERT(VARCHAR(50), GETDATE(), 121) 
    + ' <br> <table cellpadding=0 cellspacing=0 border=0>' 
    + '<tr> '
    + '<td bgcolor=#0099FF><b>sql handle</b></td>'
    + '<td bgcolor=#0099FF><b>Кол-во процессов</b></td>'
    + '<td bgcolor=#0099FF><b>Суммарное время CPU</b></td>'
    + '<td bgcolor=#0099FF><b>БД</b></td>'
    + '<td bgcolor=#0099FF><b>Текст запроса</b></td>'
    + '</tr>';

SET @Body2 = (
        SELECT td = '0x' + CONVERT(VARCHAR(MAX), sql_handle, 2),
               '',
               td     = A.Amount,
               '',
               td     = A.SumCPU,
               '',
               td     = ISNULL(DB_NAME(dest.dbid), '-'),
               '',
               td     = ISNULL(LEFT(dest.[text], 200), '-')
        FROM   (
                   SELECT sql_handle,
                          SUM(der.cpu_time) AS SumCPU,
                          COUNT(*) AS Amount
                   FROM   sys.dm_exec_requests AS der
                          CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS dest
                   GROUP BY
                          der.sql_handle
               ) A
               CROSS APPLY sys.dm_exec_sql_text(A.sql_handle) AS dest
        FOR XML PATH('tr'),
               ELEMENTS
    )

SELECT @Body2 = @TableHeader2 + REPLACE(REPLACE(@Body2, '&lt;', '<'), '&gt;', '>') 
       + @TableTail
       
SELECT @MailBody = @Body1 + @Body2
 

EXEC msdb.dbo.sp_send_dbmail
     @profile_name = 'MAIL',
     @body = @Mailbody,
     @body_format = 'HTML',
     @recipients = 'khakimovav@polyus.com',
     @subject = @AlertSubject;