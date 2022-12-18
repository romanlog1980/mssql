DECLARE  
        @AlertSubject VARCHAR(4000)
		

DECLARE @MailBody         VARCHAR(MAX),
        @Body1            VARCHAR(MAX),
        @TableTail        VARCHAR(MAX),
        @TableHeader     VARCHAR(MAX)


SET @TableTail = '</table></body><br /><br /></html>';
SET @TableHeader = '<html><head>' + '<style>'
    +
    'td {border: solid black;border-width: 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font: 11px arial} '
    + '</style>' + '</head>' + '<body>'  +
    N'Сводка Memory Grants по состоянию на: ' + CONVERT(VARCHAR(50), GETDATE(), 121) 
    + ' <br> <table cellpadding=0 cellspacing=0 border=0>' 
    + '<tr> '
		+ '<td bgcolor=#0099FF><b>session_id</b></td>'
		+ '<td bgcolor=#0099FF><b>dop</b></td>'
		+ '<td bgcolor=#0099FF><b>Request time</b></td>'
		+ '<td bgcolor=#0099FF><b>grant_time</b></td>'
		+ '<td bgcolor=#0099FF><b>Requested memory(KB)</b></td>'
		+ '<td bgcolor=#0099FF><b>Granted memory(KB)</b></td>'
		+ '<td bgcolor=#0099FF><b>Used memory(KB)</b></td>'
        + '<td bgcolor=#0099FF><b>Max used memory(KB)</b></td>'
    	+ '<td bgcolor=#0099FF><b>Query cost</b></td>'
        + '<td bgcolor=#0099FF><b>Query text</b></td>'



    + '</tr>';

SET @Body1 = (
        SELECT TOP 10
			   td = deqmg.session_id,
			   '',
               td = deqmg.dop,
               '',
               td = deqmg.request_time,
               '',
               td = deqmg.grant_time,
               '',
               td = deqmg.requested_memory_kb,
               '',
               td = deqmg.granted_memory_kb,
               '',
               td = deqmg.used_memory_kb,
               '',
               td = deqmg.max_used_memory_kb,
               '',
               td = CAST(deqmg.query_cost AS numeric(10,3)),
               '',
               td = ISNULL(LEFT(dest.text, 200), '-')
        FROM   sys.dm_exec_query_memory_grants AS deqmg
               CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS dest
        ORDER BY
               deqmg.granted_memory_kb DESC
               FOR XML PATH('tr'),
               ELEMENTS
)

SELECT @Mailbody = @TableHeader + REPLACE(REPLACE(ISNULL(@Body1, ''), '&lt;', '<'), '&gt;', '>') 
       + @TableTail
 
 SELECT @MailBody      
SELECT @AlertSubject = N'Alert: Memory Grants Pending выше 0, сводка по процессам'

	--EXEC msdb.dbo.sp_send_dbmail
	--	 @profile_name = 'MAIL',
	--	 @body = @Mailbody,
	--	 @body_format = 'HTML',
	--	 @recipients = 'khakimovav@polyus.com',
	--	 @subject = @AlertSubject;
