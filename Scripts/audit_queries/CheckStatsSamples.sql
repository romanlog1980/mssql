DECLARE @Cnt            INT = 1,
        @StatsCount     INT,
        @DBCC           NVARCHAR(500)                 


IF OBJECT_ID('tempdb..#DBCCShowStats') IS NOT NULL
    DROP TABLE #DBCCShowStats

CREATE TABLE #DBCCShowStats
(
	NAME                 SYSNAME,
	Updated              DATETIME,
	[Rows]               INT,
	[RowsSampled]        INT,
	Steps                INT,
	Density              INT,
	AvgKeyLength         INT,
	StringIndex          CHAR(3),
	FilterExpression     NVARCHAR(100),
	UnfilteredRows       INT
)


IF OBJECT_ID('tempdb..#StatsInfo') IS NOT NULL
    DROP TABLE #StatsInfo

CREATE TABLE #StatsInfo
(
	ID             INT IDENTITY(1, 1),
	SchemaName     NVARCHAR(20),
	TableName      NVARCHAR(100),
	StatsName      NVARCHAR(100),
	StatsType      NVARCHAR(10),
	StatsDate      DATETIME,
)			

INSERT INTO #StatsInfo
  (
    SchemaName,
    TableName,
    StatsName,
    StatsType,
    StatsDate
  )
SELECT SCHEMA_NAME(o.schema_id)     SchemaName,
       o.name                    AS TableName,
       s.name                    AS StatsName,
       CASE 
            WHEN s.user_created = 1 THEN 'USER'
            WHEN s.auto_created = 1 THEN 'AUTO'
            WHEN s.auto_created = 0
                 AND s.user_created = 0 THEN 'INDEX'
            ELSE 'UNKNOWN'
       END                       AS StatisticsType,
       STATS_DATE(s.[object_id], s.stats_id)
FROM   sys.stats s
       INNER JOIN sys.objects o
            ON  o.object_id = s.object_id
       INNER JOIN sys.schemas sh
            ON  sh.schema_id = o.schema_id
       INNER JOIN sys.stats_columns sc
            ON  sc.stats_id = s.stats_id
            AND sc.object_id = s.object_id
       INNER JOIN sys.columns c
            ON  c.object_id = sc.object_id
            AND c.column_id = sc.column_id
WHERE  o.type IN ('U', 'V')  

SELECT @StatsCount = MAX(id)
FROM   #StatsInfo 

WHILE @Cnt < @StatsCount
BEGIN
    SELECT @DBCC = 'DBCC SHOW_STATISTICS ([' + SchemaName + '.' + TableName + 
           '],' + StatsName + ')  WITH STAT_HEADER'
    FROM   #StatsInfo si
    WHERE  si.ID = @Cnt
    
    PRINT @DBCC
    INSERT INTO #DBCCShowStats
      (
        NAME,
        Updated,
        [Rows],
        RowsSampled,
        Steps,
        Density,
        AvgKeyLength,
        StringIndex,
        FilterExpression,
        UnfilteredRows
      )
    EXEC sp_executesql @DBCC
    
    SET @Cnt = @Cnt + 1
END
      
SELECT *
FROM   #DBCCShowStats ds
WHERE  ROWS <> RowsSampled
      