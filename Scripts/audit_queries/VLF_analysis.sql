
IF OBJECT_ID('tempdb..#VLFs') IS NOT NULL
    DROP TABLE #VLFs

CREATE TABLE #VLFs
(
	db_names        VARCHAR(100),
	fileID          INT,
	FileSize        INT,
	StartOffset     BIGINT,
	FSeqNo          INT,
	STATUS          INT,
	Parity          INT,
	CreateLSN       NUMERIC(30)
)

DECLARE @database_name       VARCHAR(100),
        @LOGINFO_Command     VARCHAR(200)
 
DECLARE VLFCount CURSOR  
FOR
    SELECT NAME
    FROM   sys.databases WHERE [state] = 0
			
OPEN VLFCount
FETCH NEXT FROM  VLFCount INTO @database_name
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @LOGINFO_Command = 'DBCC LOGINFO([' + @database_name + '])'
    PRINT @LOGINFO_Command 
    INSERT INTO #VLFs
      (
        --db_names,
        fileID,
        FileSize,
        StartOffset,
        FSeqNo,
        [STATUS],
        Parity,
        CreateLSN
      )
    EXEC (@LOGINFO_Command)
    
    UPDATE #VLFs
    SET    db_names = @database_name
    WHERE  db_names IS NULL
    
    FETCH NEXT FROM VLFCount INTO @database_name
END
CLOSE VLFCount
DEALLOCATE VLFCount


SELECT db_names,
       COUNT(*)         AS 'Amount of VLFs',
       MIN(v.FileSize)  AS 'Min VLF Size',
       MAX(v.FileSize)  AS 'Max VLF Size',
       mf.[size] * 8       Size_KB,
       CASE 
            WHEN mf.is_percent_growth = 1 THEN ((mf.growth * 8) * mf.growth / 100)
            ELSE (mf.growth * 8)
       END 'Growth_Kb',
       mf.is_percent_growth
FROM   #VLFs v
       INNER JOIN sys.master_files mf
            ON  v.fileID = mf.[file_id]
            AND v.db_names = DB_NAME(mf.database_id)
GROUP BY
       v.db_names,
       mf.[size],
       mf.growth,
       mf.is_percent_growth
ORDER BY
       'Amount of VLFs' DESC
       
DROP TABLE #VLFs

