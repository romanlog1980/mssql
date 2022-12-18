/************************************************************
 * Code formatted by SoftTree SQL Assistant © v6.5.278
 * Time: 12/26/2018 2:26:26 PM
 ************************************************************/

 
DECLARE @AlertTitle VARCHAR(4000) = 'Размер VersionStore',
        @DB SYSNAME,
        @AlertSubject VARCHAR(4000) = 'Alert: VersionStore '
    
    
DECLARE @MailBody      VARCHAR(MAX),
        @Body1         VARCHAR(MAX),
        @Body2         VARCHAR(MAX),
        @TableTail     VARCHAR(MAX),
        @TableHead     VARCHAR(MAX)
    
    
SET @Body1 = (
        SELECT td = dtasdt.session_id,
               '',
               td     = des1.[status],
               '',
               td     = dtasdt.is_snapshot,
               '',
               td     = ISNULL(dtasdt.commit_sequence_num, '') ,
               '',
               td     = dtasdt.transaction_sequence_num,
               '',
               td     = dtasdt.elapsed_time_seconds,
               '',
               td     = des1.program_name,
               '',
               td     = des1.login_name,
               '',
               td     = ISNULL(der.wait_type, ''),
               '',
               td     = ISNULL(der.wait_time, ''),
               '',
               td     = ISNULL(dest.[text], '')
        FROM   sys.dm_tran_active_snapshot_database_transactions AS dtasdt
               INNER JOIN sys.dm_exec_connections AS dec
                    ON  dec.session_id = dtasdt.session_id
               INNER JOIN sys.dm_exec_sessions AS des1
                    ON  des1.session_id = dec.session_id
               LEFT JOIN sys.dm_exec_requests AS der
                    ON  der.session_id = des1.session_id
               CROSS APPLY sys.dm_exec_sql_text(dec.most_recent_sql_handle) AS 
        dest
        ORDER BY
               dtasdt.elapsed_time_seconds DESC
               FOR XML PATH('tr'),
               ELEMENTS
    )
    
SET @TableTail = '</table></body><br /><br /></html>';
SET @TableHead = '<html><head>' + '<style>'
    +
    'td {border: solid black;border-width: 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font: 11px arial} '
    + '</style>' + '</head>' + '<body>' + @AlertTitle  +
    ' по состоянию на: ' + CONVERT(VARCHAR(50), GETDATE(), 121) 
    + ' <br> <table cellpadding=0 cellspacing=0 border=0>' 
    + '<tr> '
    + '<td bgcolor=#0099FF><b>session_id</b></td>'
    + '<td bgcolor=#0099FF><b>Status</b></td>'
    + '<td bgcolor=#0099FF><b>is_snapshot</b></td>'
    + '<td bgcolor=#0099FF><b>commit_sequence_num</b></td>'
    + '<td bgcolor=#0099FF><b>transaction_sequence_num</b></td>' 
    + '<td bgcolor=#0099FF><b>elapsed time (s)</b></td>'
    + '<td bgcolor=#0099FF><b>program_name</b></td>'
    + '<td bgcolor=#0099FF><b>login</b></td>'
    + '<td bgcolor=#0099FF><b>wait_type</b></td>'
    + '<td bgcolor=#0099FF><b>wait_time</b></td>'
    + '<td bgcolor=#0099FF><b>Last sql query</b></td>'
    + '</tr>';
    
 
SELECT @Body1 = @TableHead + REPLACE(REPLACE(@body1, '&lt;', '<'), '&gt;', '>') +  @TableTail
    
    

    
SET @TableHead = '<html><head>' + '<style>'
    +
    'td {border: solid black;border-width: 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font: 11px arial} '
    + '</style>' + '</head>' + '<body>' +
    'Распределение места в БД tempdb '  +
    ' по состоянию на: ' + CONVERT(VARCHAR(50), GETDATE(), 121) 
    + ' <br> <table cellpadding=0 cellspacing=0 border=0>' 
    + '<tr> '
    + '<td bgcolor=#0099FF><b>User objects reserved(MB)</b></td>'
    + '<td bgcolor=#0099FF><b>Internal objects reserved(MB)</b></td>'
    + '<td bgcolor=#0099FF><b>Versionstore reserved(MB)</b></td>'
    + '<td bgcolor=#0099FF><b>unallocated extents(MB)</b></td>'
    + '<td bgcolor=#0099FF><b>mixed extent(MB)</b></td>'
    + '</tr>';
    
    
SET @Body2 = (
        SELECT 
			   td = SUM(user_object_reserved_page_count) * 8 / 1024,
			   '',
               td = SUM(internal_object_reserved_page_count) * 8 / 1024,
               '',
               td = SUM(version_store_reserved_page_count) * 8 / 1024, 
               '',
               td = SUM(unallocated_extent_page_count) * 8 / 1024,
               '',
               td = SUM(mixed_extent_page_count) * 8 / 1024
        FROM   tempdb.sys.dm_db_file_space_usage
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
     @profile_name = 'XXX',
     @body = @Mailbody,
     @body_format = 'HTML',
     @recipients = 'XXXXXS',
     @subject = @AlertSubject;
 