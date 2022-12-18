/************************************************************
 * Code formatted by SoftTree SQL Assistant © v5.1.10
 * Time: 26.08.2010 17:27:42
 ************************************************************/

DECLARE @pattern   VARCHAR(100)
DECLARE @name      SYSNAME
DECLARE @sql       VARCHAR(4000)
DECLARE @isonline  NVARCHAR(20)

SELECT @pattern = '%order by%' 
CREATE TABLE #spdbdesc
(
	dbname    SYSNAME,	--nvarchar(24),
	pattern   NVARCHAR(100),
	obj_id    INT,
	obj_name  SYSNAME --nvarchar(24)
)
--select * from  master..sysdatabases
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
        SET @sql = 'use [' + @name + ']' +
            ' insert into #spdbdesc (dbname, pattern, obj_id, obj_name) select  '''
            + @name + ''',''' + @pattern + 
            ''',o.id, o.name from dbo.sysobjects o
						where exists ( select 1 from syscomments c1 
                       left join syscomments c2
                       on c1.id = c2.id and c1.colid + 1 = c2.colid                    
                       WHERE c1.id = o.id AND OBJECTPROPERTY(o.id, N''IsView'') = 1 AND UPPER(right(c1.text, 2000) + left(isnull(c2.text, ''''), 2000)) like UPPER('''
            + @pattern + '''))
						order by o.name'
        --print @sql
        EXEC (@sql)
    END
    
    FETCH NEXT FROM ms_crs_c007 INTO @name
END
		CLOSE ms_crs_c007
    DEALLOCATE ms_crs_c007


SELECT *
FROM   #spdbdesc

DROP TABLE #spdbdesc
