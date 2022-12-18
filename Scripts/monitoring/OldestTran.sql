/************************************************************
 * Code formatted by SoftTree SQL Assistant © v6.5.278
 * Time: 2017-03-30 9:54:32 AM
 ************************************************************/

DECLARE @AlertTitle VARCHAR(4000) = 'Старейшая активная транзакция',
        @DB SYSNAME,
        @AlertSubject VARCHAR(4000) = 'Alert: Журнал транзакций '
		

DECLARE @MailBody VARCHAR(MAX),
        @Body1 VARCHAR(MAX),
        @Body2 VARCHAR(MAX),
        @TableTail VARCHAR(MAX),
        @TableHead VARCHAR(MAX)

DECLARE @OpenTran TABLE 
        (field VARCHAR(30), FValue VARCHAR(256))

INSERT INTO @OpenTran
EXEC ('DBCC OPENTRAN WITH TABLERESULTS')

SELECT @DB = DB_NAME()

SET @Body1 = (
        SELECT td = s.session_id,
               '',
               td                   = (
                   SELECT FValue
                   FROM   @OpenTran
                   WHERE  field     = 'OLDACT_STARTTIME'
               ),
               '',
               td                   = (
                   SELECT FValue
                   FROM   @OpenTran
                   WHERE  field     = 'OLDACT_NAME'
               ),
               '',
               td                   = (
                   SELECT FValue
                   FROM   @OpenTran
                   WHERE  field     = 'OLDACT_LSN'
               ),
               '',
               td = DB_NAME(s.database_id),
               '',
               td                   = s.program_name,
               '',
               td                   = s.host_name,
               '',
               td                   = s.login_name,
               '',
               td                   = s.status,
               '',
               td                   = TEXT
        FROM   sys.dm_exec_sessions s
               INNER JOIN sys.dm_exec_connections c
                    ON  s.session_id = c.session_id
               CROSS APPLY sys.dm_exec_sql_text(most_recent_sql_handle)
        WHERE  s.session_id = (
                   SELECT FValue
                   FROM   @OpenTran
                   WHERE  field = 'OLDACT_SPID'
               )
               FOR XML PATH('tr'),
               ELEMENTS
    )

SET @TableTail = '</table></body><br /><br /></html>';
SET @TableHead = '<html><head>' + '<style>'
    +
    'td {border: solid black;border-width: 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font: 11px arial} '
    + '</style>' + '</head>' + '<body>' + @AlertTitle + 'в БД ' + @DB +
    ' по состоянию на: ' + CONVERT(VARCHAR(50), GETDATE(), 121) 
    + ' <br> <table cellpadding=0 cellspacing=0 border=0>' 
    + '<tr> '
    + '<td bgcolor=#0099FF><b>session_id</b></td>'
    + '<td bgcolor=#0099FF><b>Tran start time</b></td>'
    + '<td bgcolor=#0099FF><b>Tran type</b></td>'
    + '<td bgcolor=#0099FF><b>LSN</b></td>'
    + '<td bgcolor=#0099FF><b>DB name</b></td>'    
    + '<td bgcolor=#0099FF><b>Program name</b></td>'
    + '<td bgcolor=#0099FF><b>Host name</b></td>'
    + '<td bgcolor=#0099FF><b>Login</b></td>'
    + '<td bgcolor=#0099FF><b>session status</b></td>'
    + '<td bgcolor=#0099FF><b>Last sql query</b></td>'
    + '</tr>';

SELECT @Body1 = @TableHead + REPLACE(REPLACE(@body1, '&lt;', '<'), '&gt;', '>') 
       +
       @TableTail

--PRINT @Body1


SET @TableHead = '<html><head>' + '<style>'
    +
    'td {border: solid black;border-width: 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font: 11px arial} '
    + '</style>' + '</head>' + '<body>' +
    'Свободное место на дисках с файлами журнала тразакций БД ' + @DB +
    ' по состоянию на: ' + CONVERT(VARCHAR(50), GETDATE(), 121) 
    + ' <br> <table cellpadding=0 cellspacing=0 border=0>' 
    + '<tr> '
    + '<td bgcolor=#0099FF><b>Disk</b></td>'
    + '<td bgcolor=#0099FF><b>Total size</b></td>'
    + '<td bgcolor=#0099FF><b>Free space</b></td>'
    + '<td bgcolor=#0099FF><b>% Free</b></td>'
    + '<td bgcolor=#0099FF><b>Growth</b></td>'
    + '<td bgcolor=#0099FF><b>Available growth Num</b></td>'
    + '<td bgcolor=#0099FF><b>Max Size</b></td>'
    + '</tr>';


SET @Body2 = (
        SELECT td = dovs.volume_mount_point,
               '',
               td     = CAST(
                   dovs.total_bytes / 1024.0 / 1024.0 / 1024.0 AS NUMERIC(15, 2)
               ),
               '',
               td     = CAST(
                   dovs.available_bytes / 1024.0 / 1024.0 / 1024.0 AS NUMERIC(15, 2)
               ),
               '',
               td     = CAST(
                   100.00 * dovs.available_bytes / dovs.total_bytes AS NUMERIC(15, 2)
               ),
               '',
               '<td ' +
               CASE 
                    WHEN mf.is_percent_growth = 1 THEN ' bgcolor=#E6E6FA">' + 
                         CONVERT(VARCHAR(12), mf.growth) 
                         + '%'
                    ELSE '>' + CONVERT(
                             VARCHAR(12),
                             CAST((8 * mf.growth / 1024.00) AS NUMERIC(15, 2))
                         ) + 'MB'
               END + ' </td>',
               '',
               td     = CASE 
                         WHEN mf.is_percent_growth = 0 THEN CAST(
                                  (dovs.available_bytes / (8 * mf.growth / 1024.00)) 
                                  AS NUMERIC(15, 0)
                              )
                         WHEN mf.is_percent_growth = 1 THEN CAST(
                                  (
                                      dovs.available_bytes / (0.01 * 8 * mf.size * mf.growth / 1024.00)
                                  ) AS NUMERIC(15, 0)
                         )
                         END,
                         '',
                         '<td ' + CASE WHEN mf.max_size NOT IN (-1, 268435456) THEN ' bgcolor=#E6E6FA">' +  CONVERT(VARCHAR(30), CAST((8 * mf.max_size/1024.00/1024) AS NUMERIC(15, 2))) + ' Gb'
                         ELSE '> Unlim'
                         END +   ' </td>',
                         ''
        FROM   sys.master_files AS mf
               CROSS APPLY sys.dm_os_volume_stats(database_id, FILE_ID) AS dovs
        WHERE  dovs.database_id = DB_ID()
               AND TYPE = 1
                   FOR XML PATH('tr'),
                   ELEMENTS
    )

SELECT @Body2 = @TableHead + REPLACE(REPLACE(@body2, '&lt;', '<'), '&gt;', '>') 
       +
       @TableTail

SET @MailBody = @Body1 + @Body2

SET @AlertSubject = @AlertSubject + @DB 

PRINT @MailBody

EXEC msdb.dbo.sp_send_dbmail
     @profile_name = 'Foris-DBMail',
     @body = @Mailbody,
     @body_format = 'HTML',
     @recipients = 'xxxx',	-- replace with your email address
     @subject = @AlertSubject;