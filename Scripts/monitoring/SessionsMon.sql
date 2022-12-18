

DECLARE @AlertTitle              VARCHAR(500) =
        'Cессии с временем выполнения более 15 минут ',
        @DurationTreshold_ms     INT = 900000,
        @Kill_after_alert        BIT = 0 -- 0 - не убивать, 1 - убивать

IF OBJECT_ID('tempdbdb.. #SessionStats') IS NOT NULL
    DROP TABLE #SessionStats
 
CREATE TABLE #SessionStats
(
	session_id               SMALLINT,
	program_name             NVARCHAR(128),
	start_time               DATETIME,
	STATUS                   NVARCHAR(30),
	blocking_session_id      SMALLINT,
	wait_type                NVARCHAR(60),
	wait_time                INT,
	wait_resource            NVARCHAR(256),
	cpu_time                 INT,
	total_elapsed_time       INT,
	logical_reads            BIGINT,
	writes                   BIGINT,
	query_hash               BINARY(8),
	query_plan_hash          BINARY(8),
	granted_query_memory     INT,
	plan_handle              VARBINARY(64),
	QueryText                NVARCHAR(MAX)
)

INSERT INTO #SessionStats
SELECT er.session_id,
       des1.program_name,
       er.start_time,
       er.[status],
       er.blocking_session_id,
       er.wait_type,
       er.wait_time,
       er.wait_resource,
       er.cpu_time,
       er.total_elapsed_time,
       er.logical_reads,
       er.writes,
       er.query_hash,
       er.query_plan_hash,
       er.granted_query_memory,
       er.plan_handle,
       SUBSTRING(
           qt.text,
           er.statement_start_offset / 2 + 1,
           (
               CASE 
                    WHEN er.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) 
                         * 2
                    ELSE er.statement_end_offset
               END -
               er.statement_start_offset
           ) / 2
       )                                AS 'QueryText'
FROM   sys.dm_exec_sessions es
       INNER JOIN sys.dm_exec_requests er
            ON  es.session_id = er.session_id
       INNER JOIN sys.dm_exec_sessions  AS des1
            ON  des1.session_id = er.session_id
       CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS qt
WHERE  1 = 1
       AND des1.is_user_process = 1
       AND er.total_elapsed_time > @DurationTreshold_ms

IF EXISTS(
       SELECT TOP 1 session_id
       FROM   #SessionStats
   )
BEGIN
    DECLARE @Body1           VARCHAR(MAX),
            @TableTail       VARCHAR(MAX) = '</table></body><br /><br /></html>',
            @TableHead       VARCHAR(MAX),
            @MailSubject     VARCHAR(500),
            @KillCommand     VARCHAR(MAX)  
    
    SET @MailSubject = 'Alert: ' + @AlertTitle 
    SET @TableHead = '<html><head>' + '<style>'
        +
        'td {border: solid black;border-width: 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font: 11px arial} '
        + '</style>' + '</head>' + '<body>' + @AlertTitle +
        ' по состоянию на: ' + CONVERT(VARCHAR(50), GETDATE(), 121) 
        + ' <br> <table cellpadding=0 cellspacing=0 border=0>' 
        + '<tr> '
        + '<td bgcolor=#0099FF><b>session_id</b></td>'
        + '<td bgcolor=#0099FF><b>program_name</b></td>'
        + '<td bgcolor=#0099FF><b>start_time</b></td>'
        + '<td bgcolor=#0099FF><b>STATUS</b></td>'
        + '<td bgcolor=#0099FF><b>blocking_session_id</b></td>' 
        + '<td bgcolor=#0099FF><b>wait_type</b></td>'
        + '<td bgcolor=#0099FF><b>wait_time</b></td>'
        + '<td bgcolor=#0099FF><b>wait_resource</b></td>'
        + '<td bgcolor=#0099FF><b>cpu_time</b></td>'
        + '<td bgcolor=#0099FF><b>total_elapsed_time</b></td>'
        + '<td bgcolor=#0099FF><b>logical_reads</b></td>'
        + '<td bgcolor=#0099FF><b>writes</b></td>'
        + '<td bgcolor=#0099FF><b>query_hash</b></td>'
        + '<td bgcolor=#0099FF><b>query_plan_hash</b></td>'
        + '<td bgcolor=#0099FF><b>granted_query_memory</b></td>'
        + '<td bgcolor=#0099FF><b>plan_handle</b></td>'
        + '<td bgcolor=#0099FF><b>QueryText</b></td>'
        + '</tr>';
    
    SET @Body1 = (
            SELECT td = session_id,
                   '',
                   td     = program_name,
                   '',
                   td     = start_time,
                   '',
                   td     = STATUS,
                   '',
                   td     = blocking_session_id,
                   '',
                   td     = ISNULL(wait_type, '-'),
                   '',
                   td     = wait_time,
                   '',
                   td     = wait_resource,
                   '',
                   td     = cpu_time,
                   '',
                   td     = total_elapsed_time,
                   '',
                   td     = logical_reads,
                   '',
                   td     = writes,
                   '',
                   td     = '0x' + CONVERT(VARCHAR(MAX), query_hash, 2),
                   '',
                   td     = '0x' + CONVERT(VARCHAR(MAX), query_plan_hash, 2),
                   '',
                   td     = granted_query_memory,
                   '',
                   td     = '0x' + CONVERT(VARCHAR(MAX), plan_handle, 2),
                   '',
                   td     = LEFT(QueryText, 300)
            FROM   #SessionStats 
                   FOR XML PATH('tr'),
                   ELEMENTS
        )
    
    IF (@Kill_after_alert = 1)
    BEGIN
        SELECT @KillCommand = (
                   SELECT 'KILL ' + CAST(session_id AS VARCHAR(4)) + ';'
                   FROM   #SessionStats
                   WHERE  session_id <> @@SPID FOR XML PATH(''),
                          ELEMENTS
               )
        
        EXEC (@Killcommand)
    END
    
    PRINT @KillCommand
    SELECT @Body1 = @TableHead + REPLACE(REPLACE(@body1, '&lt;', '<'), '&gt;', '>') 
           +
           @TableTail
    
    
    
    EXEC msdb.dbo.sp_send_dbmail
         @profile_name = 'Casepro admin', --имя профиля в DB Mail
         @body = @Body1,
         @body_format = 'HTML',
         @recipients = 'xxxx',   --почта, через запятую
         @subject = @MailSubject
END

DROP TABLE #SessionStats


