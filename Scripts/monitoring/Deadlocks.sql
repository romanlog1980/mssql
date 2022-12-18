

DECLARE @AlertTitle NVARCHAR(4000) = N'Взаимная блокировка',
        @DB SYSNAME,
        @AlertSubject NVARCHAR(4000) = N'Alert: Взаимная блокировка  '
		

DECLARE @MailBody NVARCHAR(MAX),
        @Body1 NVARCHAR(MAX),
        @Body2 NVARCHAR(MAX),
        @TableTail NVARCHAR(MAX),
        @TableHead NVARCHAR(MAX)


DECLARE @SessionName SYSNAME 

SELECT @SessionName = 'system_health'


IF OBJECT_ID('tempdb..#Events') IS NOT NULL
BEGIN
    DROP TABLE #Events
END

DECLARE @Target_File              NVARCHAR(1000),
        @Target_Dir               NVARCHAR(1000),
        @Target_File_WildCard     NVARCHAR(1000)

SELECT @Target_File = CAST(t.target_data AS XML).value('EventFileTarget[1]/File[1]/@name', 'NVARCHAR(256)')
FROM   sys.dm_xe_session_targets t
       INNER JOIN sys.dm_xe_sessions s
            ON  s.address = t.event_session_address
WHERE  s.name = @SessionName
       AND t.target_name = 'event_file'

SELECT @Target_Dir = LEFT(
           @Target_File,
           LEN(@Target_File) - CHARINDEX('\', REVERSE(@Target_File))
       ) 

SELECT @Target_File_WildCard = @Target_Dir + '\' + @SessionName + '_*.xel'

--Keep this as a separate table because it's called twice in the next query.  You don't want this running twice.
SELECT DeadlockGraph = CAST(event_data AS XML),
       DeadlockID = ROW_NUMBER() OVER(ORDER BY FILE_NAME, file_offset)
       INTO #Events
FROM   sys.fn_xe_file_target_read_file(@Target_File_WildCard, NULL, NULL, NULL) AS 
       F
WHERE  event_data LIKE '<event name="xml_deadlock_report%';;
WITH Victims AS
     (
         SELECT VictimID = Deadlock.Victims.value('@id', 'varchar(50)'),
                e.DeadlockID
         FROM   #Events e
                CROSS APPLY e.DeadlockGraph.nodes('/event/data/value/deadlock/victim-list/victimProcess') AS 
         Deadlock(Victims)
     )
     , DeadlockObjects AS
     (
         SELECT DISTINCT e.DeadlockID,
                ObjectName = Deadlock.Resources.value('@objectname', 'nvarchar(256)')
         FROM   #Events e
                CROSS APPLY e.DeadlockGraph.nodes('/event/data/value/deadlock/resource-list/*') AS 
         Deadlock(Resources)
     )

SELECT * INTO     #Deadlocks
FROM   (
           SELECT e.DeadlockID,
                  TransactionTime     = Deadlock.Process.value('@lasttranstarted', 'datetime'),
                  DeadlockObjects     = SUBSTRING(
                      (
                          SELECT (', ' + o.ObjectName)
                          FROM   DeadlockObjects o
                          WHERE  o.DeadlockID = e.DeadlockID
                          ORDER BY
                                 o.ObjectName
                                 FOR XML PATH('')
                      ),
                      3,
                      4000
                  ),
                  sqlhandle = Deadlock.Process.value('executionStack[1]/frame[1]/@sqlhandle[1]', 'varchar(200)'),
                  Victim = CASE 
                                WHEN v.VictimID IS NOT NULL THEN 1
                                ELSE 0
                           END,
                  SPID = Deadlock.Process.value('@spid', 'int'),
                  ProcedureName = Deadlock.Process.value('executionStack[1]/frame[1]/@procname[1]', 'varchar(200)'),
                  LockMode = Deadlock.Process.value('@lockMode', 'char(1)'),
                  Code = Deadlock.Process.value('executionStack[1]/frame[1]', 'varchar(1000)'),
                  ClientApp = CASE LEFT(Deadlock.Process.value('@clientapp', 'varchar(100)'), 29)
                                   WHEN 'SQLAgent - TSQL JobStep (Job ' THEN 
                                        'SQLAgent Job: ' + (
                                            SELECT NAME
                                            FROM   msdb..sysjobs sj
                                            WHERE  SUBSTRING(
                                                       Deadlock.Process.value('@clientapp', 'varchar(100)'),
                                                       32,
                                                       32
                                                   ) = (SUBSTRING(sys.fn_varbintohexstr(sj.job_id), 3, 100))
                                        ) + ' - ' + SUBSTRING(
                                            Deadlock.Process.value('@clientapp', 'varchar(100)'),
                                            67,
                                            LEN(Deadlock.Process.value('@clientapp', 'varchar(100)'))
                                            -67
                                        )
                                   ELSE Deadlock.Process.value('@clientapp', 'varchar(100)')
                              END,
                  HostName = Deadlock.Process.value('@hostname', 'varchar(20)'),
                  LoginName = Deadlock.Process.value('@loginname', 'varchar(20)'),
                  INPUTBUFFER = Deadlock.Process.value('inputbuf[1]', 'varchar(1000)')
           FROM   #Events e
                  CROSS APPLY e.DeadlockGraph.nodes('/event/data/value/deadlock/process-list/process') AS 
           Deadlock(Process)
           LEFT JOIN Victims v
                       ON  v.DeadlockID = e.DeadlockID
                       AND v.VictimID = Deadlock.Process.value('@id', 'varchar(50)')
           WHERE  e.deadlockID = (
                      SELECT MAX(DeadlockId)
                      FROM   #Events
                  )
       )          X
WHERE DeadlockID = (SELECT MAX(DeadlockId) FROM #Events)


SET @Body1 = (
        SELECT tr = deadlockID,
               '',
               tr     = TransactionTime,
               '',
               tr     = DeadlockObjects,
               '',
               tr     = sqlhandle,
               '',
               tr     = Victim,
               '',
               tr     = SPID,
               '',
               tr     = ProcedureName,
               '',
               tr     = LockMode,
               '',
               tr     = Code,
               '',
               tr     = ClientApp,
               '',
               tr     = HostName,
               '',
               tr     = LoginName,
               '',
               tr     = INPUTBUFFER,
               ''
        FROM   #Deadlocks
               FOR XML PATH('tr'),
               ELEMENTS
    )

SET @TableTail = '</table></body><br /><br /></html>';
SET @TableHead = '<html><head>' + '<style>'
    +
    'td {border: solid black;border-width: 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font: 11px arial} '
    + '</style>' + '</head>' + '<body>' + @AlertTitle +
    N' в: ' + CONVERT(VARCHAR(50), GETDATE(), 121) 
    + ' <br> <table cellpadding=0 cellspacing=0 border=0>' 
    + '<tr> '
    + '<td bgcolor=#0099FF><b>deadlock id</b></td>'
    + '<td bgcolor=#0099FF><b>Tran time</b></td>'
    + '<td bgcolor=#0099FF><b>Object</b></td>'
    + '<td bgcolor=#0099FF><b>sqlhandle</b></td>'
    + '<td bgcolor=#0099FF><b>Victim</b></td>' 
    + '<td bgcolor=#0099FF><b>SPID</b></td>'
    + '<td bgcolor=#0099FF><b>Proc name</b></td>'
    + '<td bgcolor=#0099FF><b>Lock mode</b></td>'
    + '<td bgcolor=#0099FF><b>Code</b></td>'
    + '<td bgcolor=#0099FF><b>Client app</b></td>'
    + '<td bgcolor=#0099FF><b>Host</b></td>'
    + '<td bgcolor=#0099FF><b>Login</b></td>'
    + '<td bgcolor=#0099FF><b>Input buffer</b></td>'
    + '</tr>';

SELECT @MailBody = @TableHead + REPLACE(REPLACE(@body1, '&lt;', '<'), '&gt;', '>') 
       +
       @TableTail
       
       
       

SET @AlertSubject = @AlertSubject + @DB 

PRINT @MailBody

EXEC msdb.dbo.sp_send_dbmail
     @profile_name = '',
     @body = @Mailbody,
     @body_format = 'HTML',
     @recipients = 'xxxx',	-- 
     @subject = @AlertSubject;
