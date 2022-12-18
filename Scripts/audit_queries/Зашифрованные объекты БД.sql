 

DECLARE @name      SYSNAME
DECLARE @sql       VARCHAR(4000)
DECLARE @isonline  NVARCHAR(20)

CREATE TABLE #spdbdesc
(
	dbname     SYSNAME,
	obj_id     INT NULL,
	obj_name   SYSNAME NULL,
	Encrypted  BIT,
	XType      NVARCHAR(3)
)
DECLARE ms_crs_c007 CURSOR  
FOR
    SELECT [name]
    FROM   MASTER..sysdatabases
 
		OPEN ms_crs_c007
			FETCH NEXT FROM ms_crs_c007 INTO @name 
WHILE @@fetch_status = 0
BEGIN
    SELECT @isonline = CAST(DATABASEPROPERTYEX(@name, 'STATUS') AS NVARCHAR(20))
    IF @isonline <> 'OFFLINE'
    BEGIN
        SET @sql = 'use ' + @name +
            ' insert into #spdbdesc (dbname, obj_id, obj_name, Encrypted, XType) select '''
            + @name + 
            ''' as DBName, N.id, M.name, N.encrypted, M.xtype from syscomments N with (NOLock) inner join sysobjects M with (NOLock) on N.id=M.id where encrypted=1'
        --select DB_NAME (1) as DBName, N.id, M.name, N.encrypted, M.xtype from syscomments N with (NOLock) inner join sysobjects M with (NOLock) on N.id=M.id where encrypted=0
        PRINT @sql
        EXEC (@sql)
    END
    
    FETCH NEXT FROM ms_crs_c007 INTO @name
END
		CLOSE ms_crs_c007
    DEALLOCATE ms_crs_c007


SELECT *
FROM   #spdbdesc

DROP TABLE #spdbdesc

