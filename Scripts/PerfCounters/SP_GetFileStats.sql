CREATE PROCEDURE [dbo].[GetFileStats]
AS
BEGIN

WITH CTE AS (
         SELECT fs.runtime,
                fs.DbId,
                fs.FileId,
                fs.[database],
                fs.type_desc,
                fs.[file],
                fs.NumberReads,
                fs.NumberWrites,
                fs.BytesRead,
                fs.BytesWritten,
                fs.IoStallReadMS,
                fs.IoStallWriteMS,
                ROW_NUMBER() OVER(PARTITION BY fs.dbid, fs.FileId ORDER BY fs.runtime) AS 
                RowNum
         FROM   tbl_FileStats AS fs
                --  WHERE  fs.DbId = 2
     )


 
SELECT CONVERT(DATETIME, b.runtime, 121)  AS runtime,
       --DATEPART(YEAR, b.runtime)          AS YEAR,
       --DATEPART(MONTH, b.runtime)         AS MONTH,
       --DATEPART(DAY, b.runtime)           AS DAY,
       --DATEPART(hour, b.runtime)          AS Hour,
       --DATEPART(minute, b.runtime)        AS minute,
       --DATEPART(ss, b.runtime)            AS Sec,
     
       a.Dbid,
	   a.fileid,
	   df.Database_name,
	   df.name AS FileName,
	   LEFT(df.physical_name, 1) Drive,

       a.type_desc,
       NumReads = (b.NumberReads - a.NumberReads),
       NumWrites = (b.NumberWrites - a.NumberWrites),
       AvgMBReads = CASE 
                         WHEN (b.NumberReads - a.NumberReads) = 0 THEN 0
                         ELSE ((b.BytesRead - a.BytesRead) / 1024.0 / 1024.0) / (b.NumberReads - a.NumberReads)
                    END,
       AvgMBWrites = CASE 
                          WHEN (b.NumberWrites - a.NumberWrites) 
                               = 0 THEN 0
                          ELSE ((b.BytesWritten - a.BytesWritten) / 1024.0 / 1024.0) 
                               / (b.NumberWrites - a.NumberWrites)
                     END,
       AvgBytesReadsPerSec = CASE 
                                  WHEN DATEDIFF(ss, a.runtime, b.runtime) 
                                       = 0 THEN 0
                                  ELSE (b.BytesRead - a.BytesRead) 
                                       / DATEDIFF(ss, a.runtime, b.runtime)
                             END,
       AvgBytesWritesPerSec = CASE 
                                   WHEN DATEDIFF(ss, a.runtime, b.runtime) 
                                        = 0 THEN 0
                                   ELSE (b.BytesWritten - a.BytesWritten) 
                                        / DATEDIFF(ss, a.runtime, b.runtime)
                              END,
       AvgIOReadStallMS = CASE 
                               WHEN (b.NumberReads - a.NumberReads) 
                                    =
                                    0 THEN 0
                               ELSE (b.IoStallReadMS - a.IoStallReadMS) 
                                    / (b.NumberReads - a.NumberReads)
                          END,
       AvgIOWriteStallMS = CASE 
                                WHEN (b.NumberWrites - a.NumberWrites) 
                                     =
                                     0 THEN 0
                                ELSE (b.IoStallWriteMS - a.IoStallWriteMS) 
                                     / (b.NumberWrites - a.NumberWrites)
                           END
FROM   CTE a
       LEFT JOIN CTE b
            ON  b.RowNum = a.RowNum + 1
            AND b.fileid = a.fileid
            AND b.dbid = a.dbid
		INNER JOIN tbl_DatabaseFiles df
			ON a.DbId = df.database_id
			AND a.FileId = df.file_id
WHERE  b.runtime IS NOT   NULL  
 

END
GO


