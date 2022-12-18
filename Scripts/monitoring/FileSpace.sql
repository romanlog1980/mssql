    
       
IF OBJECT_ID('tempdb..#DBSpace') IS NOT NULL
    DROP TABLE #DBSpace

CREATE TABLE #DBSpace
(
	database_id     INT,
	FILE_ID         INT,
	SIZE            BIGINT,
	spaceused       BIGINT
)
    INSERT INTO #DBSpace
    EXEC  sp_MSforEachDB 'USE [?];SELECT DB_ID(), FILE_ID, SIZE, FILEPROPERTY(NAME, ''spaceused'')  FROM sys.database_files'  
    
    
    SELECT volume_mount_point,
           AVG(total_bytes) / 1024.00 / 1024.00 / 1024.00 'volume size',
           AVG(available_bytes) / 1024.00 / 1024.00 / 1024.00 'Free space',
           AVG(100 * available_bytes / total_bytes) 'Percent free space',
           SUM(mf.size * 8 / 1024.00 / 1024.00) 'Total DB files size(GB)',
           SUM(mf.spaceused * 8 / 1024.00 / 1024.00) 'Used DB files size(GB)',
           SUM(mf.size * 8 / 1024.00 / 1024.00) - SUM(mf.spaceused * 8 / 1024.00 / 1024.00) 
           'Free space in DB files(GB)',
           100.00 * (
               AVG(available_bytes) / 1024.00 / 1024.00 / 1024.00 + SUM(mf.size * 8 / 1024.00 / 1024.00) 
               - SUM(mf.spaceused * 8 / 1024.00 / 1024.00)
           ) / (AVG(total_bytes) / 1024.00 / 1024.00 / 1024.00)  'Percent free space include DB files'
    FROM   #DBSpace AS mf
           CROSS APPLY sys.dm_os_volume_stats(database_id, FILE_ID) AS dovs
    GROUP BY
           volume_mount_point  
    
    
 