use master
GO
IF OBJECT_ID('dbo.pDeadlockInfo') IS NOT NULL DROP PROC dbo.pDeadlockInfo
GO
CREATE PROC dbo.pDeadlockInfo
	@top INT = 1  -- сколько последних файлов считывать

AS
SET NOCOUNT ON

DECLARE
	 @Target_File	NVARCHAR(1000)
	,@Target_Dir	NVARCHAR(1000)
	,@file			NVARCHAR(1000)
	,@cmd			NVARCHAR(1000)
	,@f				NVARCHAR(1000)
	,@i				INT = 0

CREATE TABLE #Events (
	 [DeadlockGraph] [xml] NULL
	,[DeadlockID] [bigint] NULL
	)
CREATE TABLE #T (i INT IDENTITY, n NVARCHAR(999))
CREATE TABLE #F (i INT IDENTITY, f NVARCHAR(200))

SELECT @Target_File = CAST(t.target_data as XML).value('EventFileTarget[1]/File[1]/@name', 'NVARCHAR(256)')
FROM sys.dm_xe_session_targets t
INNER JOIN sys.dm_xe_sessions s ON s.address = t.event_session_address
WHERE s.name = 'system_health'
  AND t.target_name = 'event_file'

SET @Target_Dir = LEFT(@Target_File, Len(@Target_File) - CHARINDEX('\', REVERSE(@Target_File)))
SET @cmd = 'dir ' + @Target_Dir + '\system_health_*.xel'
INSERT #T (n) EXEC xp_cmdshell @cmd

INSERT #F (f)
SELECT TOP (@top)SUBSTRING(SUBSTRING(n, CHARINDEX('system_health', n), 999999999), 1, CHARINDEX('.xel', SUBSTRING(n, CHARINDEX('system_health', n) - 10, 999999999)))
FROM #T
WHERE n LIKE '%system_health%.xel'
ORDER BY 1 DESC

WHILE EXISTS (select * from #F) BEGIN

	select TOP 1 @f = f, @i = i
	from #F
	ORDER BY i
	SET @file = @Target_Dir + '\'  + @f
	PRINT @file

	INSERT #Events
	SELECT DeadlockGraph = CAST(event_data AS XML)
		, DeadlockID = Row_Number() OVER(ORDER BY file_name, file_offset)
	FROM sys.fn_xe_file_target_read_file(@file, null, null, null) AS F
	WHERE event_data like '<event name="xml_deadlock_report%'

	DELETE #F WHERE i = @i
END

;WITH Victims AS (
	SELECT VictimID = Deadlock.Victims.value('@id', 'varchar(50)')
		,e.DeadlockID
	FROM #Events e
		CROSS APPLY e.DeadlockGraph.nodes('/event/data/value/deadlock/victim-list/victimProcess') as Deadlock(Victims)
	)
	,DeadlockObjects AS (
	SELECT DISTINCT e.DeadlockID
		,ObjectName = Deadlock.Resources.value('@objectname', 'nvarchar(256)')
	FROM #Events e
	CROSS APPLY e.DeadlockGraph.nodes('/event/data/value/deadlock/resource-list/*') as Deadlock(Resources)
	)
SELECT
	 DeadlockID
	,TransactionTime
	,DeadlockGraph = CONVERT(xml, SUBSTRING(SUBSTRING(DL, CHARINDEX('<deadlock>', DL), 999999999), 1, CHARINDEX('</deadlock>', SUBSTRING(DL, CHARINDEX('<deadlock>', DL) - 10, 999999999))))
	,DeadlockObjects
	,Victim
	,SPID
	,ProcedureName
	,LockMode
	,Code
	,ClientApp
	,HostName
	,LoginName
	,InputBuffer
FROM (
	SELECT e.DeadlockID
		, TransactionTime = Deadlock.Process.value('@lasttranstarted', 'datetime')
		, DL = CONVERT(VARCHAR(MAX), DeadlockGraph)
		, DeadlockObjects = substring((SELECT (', ' + o.ObjectName)
							FROM DeadlockObjects o
							WHERE o.DeadlockID = e.DeadlockID
							ORDER BY o.ObjectName
							FOR XML PATH ('')
							), 3, 4000)
		, Victim = CASE WHEN v.VictimID IS NOT NULL
							THEN 1
						ELSE 0
						END
		, SPID = Deadlock.Process.value('@spid', 'int')
		, ProcedureName = Deadlock.Process.value('executionStack[1]/frame[1]/@procname[1]', 'varchar(200)')
		, LockMode = Deadlock.Process.value('@lockMode', 'char(1)')
		, Code = Deadlock.Process.value('executionStack[1]/frame[1]', 'varchar(1000)')
		, ClientApp = CASE LEFT(Deadlock.Process.value('@clientapp', 'varchar(100)'), 29)
						WHEN 'SQLAgent - TSQL JobStep (Job '
							THEN 'SQLAgent Job: ' + (SELECT name FROM msdb.dbo.sysjobs sj WHERE substring(Deadlock.Process.value('@clientapp', 'varchar(100)'),32,32)=(substring(sys.fn_varbintohexstr(sj.job_id),3,100))) + ' - ' + SUBSTRING(Deadlock.Process.value('@clientapp', 'varchar(100)'), 67, len(Deadlock.Process.value('@clientapp', 'varchar(100)'))-67)
						ELSE Deadlock.Process.value('@clientapp', 'varchar(100)')
						END
		, HostName = Deadlock.Process.value('@hostname', 'varchar(20)')
		, LoginName = Deadlock.Process.value('@loginname', 'varchar(20)')
		, InputBuffer = Deadlock.Process.value('inputbuf[1]', 'varchar(1000)')
	FROM #Events e
		CROSS APPLY e.DeadlockGraph.nodes('/event/data/value/deadlock/process-list/process') as Deadlock(Process)
		LEFT JOIN Victims v ON v.DeadlockID = e.DeadlockID AND v.VictimID = Deadlock.Process.value('@id', 'varchar(50)')
	) X
ORDER BY DeadlockID DESC
GO
