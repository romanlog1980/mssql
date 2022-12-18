/************************************************************
 * Code formatted by SoftTree SQL Assistant © v6.5.278
 * Time: 8/6/2019 11:08:14 AM
 ************************************************************/

SET NOCOUNT ON 
DECLARE @ExtendedDBInfo BIT = 1,
		@freespace_treashold      INT = 100,
        @growths_treashold        INT = 50000000


DECLARE @percent_free_space       INT,
        @amount_of_growth_ops     INT


SELECT @percent_free_space = CAST(100.00 * dovs.available_bytes / dovs.total_bytes AS INT),
       @amount_of_growth_ops = CASE 
                                    WHEN mf.is_percent_growth = 0 THEN CAST((dovs.available_bytes / (8 * mf.growth / 1024.00)) AS INT)
                                    WHEN mf.is_percent_growth = 1 THEN CAST(
                                             (
                                                 dovs.available_bytes / (0.01 * 8 * mf.size * mf.growth / 1024.00)
                                             ) AS INT
                                         )
                               END
FROM   sys.master_files AS mf
       CROSS APPLY sys.dm_os_volume_stats(database_id, FILE_ID) AS dovs
WHERE  dovs.database_id = DB_ID()
       AND TYPE = 1  
       
IF (@percent_free_space < @freespace_treashold)
   OR (@amount_of_growth_ops < @growths_treashold)
BEGIN
    DECLARE @AlertTitle VARCHAR(4000) = 'Свободное мессто на дисках с файлами БД',
            @DB SYSNAME,
            @AlertSubject VARCHAR(4000) = ' '
    
    
    DECLARE @MailBody NVARCHAR(MAX),
            @Body1 NVARCHAR(MAX),
            @Body2 NVARCHAR(MAX),
            @TableTail NVARCHAR(MAX),
            @TableHead NVARCHAR(MAX)
    

    
    
    IF OBJECT_ID('tempdb..#DBFilesInfo') IS NOT NULL
        DROP TABLE #DBFilesInfo
    
    CREATE TABLE #DBFilesInfo
    (
    	DBName              SYSNAME,
    	database_id         INT,
    	FILE_ID             INT,
    	type_desc           SYSNAME,
    	NAME                SYSNAME,
    	physical_name       NVARCHAR(1000),
    	FileSize_MB         NUMERIC(15, 2),
    	Used_MB             NUMERIC(15, 2),
    	FreeSpaceInFile     NUMERIC(15, 2)
    )
    
    INSERT INTO #DBFilesInfo
    EXEC sp_MSforeachdb 
         'USE ? SELECT ''?'', DB_ID(), file_id, type_desc, name, physical_name,        CAST(mf.[size] / 128.00 AS DECIMAL(15,2)) FileSize_MB, ROUND(CAST((FILEPROPERTY(mf.name, ''SpaceUsed'')) AS FLOAT) / 128, 2) AS Used_MB, ROUND( (CAST((mf.size) AS FLOAT) / 128) -(CAST((FILEPROPERTY(mf.name, ''SpaceUsed''))AS FLOAT) / 128), 2) AS SpaceUsed   FROM sys.database_files mf'
    
    --SELECT * FROM #DBFilesInfo
    
 SET @Body1 = (
    SELECT td = vs.volume_mount_point,
				'',
           td = CAST(AVG(total_bytes) / 1024.00 / 1024.00 AS NUMERIC(15, 2)), 
           '',
           td = CAST(AVG(available_bytes) / 1024.00 / 1024.00 AS NUMERIC(15, 2)), 
           '',
           td = CAST(AVG((100.00 * available_bytes / total_bytes)) AS NUMERIC(15, 2)),
           '',
           td = SUM(mf.FileSize_MB),
           '',
           td = SUM(mf.Used_MB),
           '',
           td = SUM(mf.FreeSpaceInFile)
    FROM   #DBFilesInfo             AS mf
           CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.[file_id]) vs
    GROUP BY
           vs.volume_mount_point
           FOR XML PATH('tr'),
                   ELEMENTS
 )
  
                   
       SET @TableTail = '</table></body><br /><br /></html>';
    SET @TableHead = '<html><head>' + '<style>'
        +
        'td {border: solid black;border-width: 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font: 11px arial} '
        + '</style>' + '</head>' + '<body>' + @AlertTitle + 
        ' по состоянию на: ' + CONVERT(VARCHAR(50), GETDATE(), 121) 
        + ' <br> <table cellpadding=0 cellspacing=0 border=0>' 
        + '<tr> '
        + '<td bgcolor=#0099FF><b>Диск</b></td>'
        + '<td bgcolor=#0099FF><b>Объем диска(МБ)</b></td>'
        + '<td bgcolor=#0099FF><b>Свободное место на диске(МБ)</b></td>'
        + '<td bgcolor=#0099FF><b>% свободного места на диске</b></td>'
        + '<td bgcolor=#0099FF><b>Суммарный объем файлов БД(МБ)</b></td>' 
        + '<td bgcolor=#0099FF><b>Используемый объем файлов БД(МБ)</b></td>'
        + '<td bgcolor=#0099FF><b>Объем свободного места в файлах БД(МБ)</b></td>'
        + '</tr>';
    
    SELECT @Body1 = @TableHead + REPLACE(REPLACE(@body1, '&lt;', '<'), '&gt;', '>') 
           +
           @TableTail

 IF @ExtendedDBInfo = 1
	BEGIN
    SET @TableHead = '<html><head>' + '<style>'
        +
        'td {border: solid black;border-width: 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font: 11px arial} '
        + '</style>' + '</head>' + '<body>' +
        'Информация по файлам БД по состоянию на: ' + CONVERT(VARCHAR(50), GETDATE(), 121) 
        + ' <br> <table cellpadding=0 cellspacing=0 border=0>' 
        + '<tr> '
        + '<td bgcolor=#0099FF><b>Имя БД</b></td>'
        + '<td bgcolor=#0099FF><b>File_id</b></td>'
        + '<td bgcolor=#0099FF><b>Тип</b></td>'
        + '<td bgcolor=#0099FF><b>Имя файла</b></td>'
        + '<td bgcolor=#0099FF><b>Путь</b></td>'
        + '<td bgcolor=#0099FF><b>Размер файла(МБ)</b></td>'
        + '<td bgcolor=#0099FF><b>Используемое место(МБ)</b></td>'
        + '<td bgcolor=#0099FF><b>Свободное место в файле(МБ)</b></td>'
        + '<td bgcolor=#0099FF><b>% Свободного места в файле</b></td>'
        + '</tr>';

    
 SET @Body2 = (   SELECT td = DFI.DBName,
		   '',
           td = DFI.[FILE_ID],
           '',
           td = DFI.type_desc,
           '',
           td = DFI.NAME,
           '',
           td = DFI.physical_name,
           '',
           td = ISNULL(DFI.FileSize_MB, 0),
           '',
           td = ISNULL(DFI.Used_MB, 0),
           '',
           td = ISNULL(DFI.FreeSpaceInFile, 0), 
           '',
          '<td' + CASE WHEN   CAST(ISNULL(100.00 * DFI.FreeSpaceInFile, 0) / ISNULL(DFI.FileSize_MB, 0) AS NUMERIC(15,1)) > 30 THEN  ' bgcolor=#E6E6FA">' 
                             + CONVERT(VARCHAR(100),CAST(ISNULL(100.00 * DFI.FreeSpaceInFile, 0) / ISNULL(DFI.FileSize_MB, 0) AS NUMERIC(15,1)))
                             ELSE    '>' + CONVERT(VARCHAR(100),CAST(ISNULL(100.00 * DFI.FreeSpaceInFile, 0) / ISNULL(DFI.FileSize_MB, 0) AS NUMERIC(15,1)))
                             END + ' </td>' 
    FROM   #DBFilesInfo DFI
                  ORDER BY DFI.FileSize_MB DESC
     FOR XML PATH('tr'),
                       ELEMENTS
)
                       
    SELECT @Body2 = @TableHead + REPLACE(REPLACE(@body2, '&lt;', '<'), '&gt;', '>') 
           +
           @TableTail
    
   END
    SET @MailBody = @Body1 + ISNULL(@Body2, '')
 
 /*   
    EXEC msdb.dbo.sp_send_dbmail
         @profile_name = 'XXX',
         @body = @Mailbody,
         @body_format = 'HTML',
         @recipients = 'XXXXXS',
         @subject = @AlertSubject;
*/

SELECT @MailBody
DROP TABLE #DBFilesInfo
END

 