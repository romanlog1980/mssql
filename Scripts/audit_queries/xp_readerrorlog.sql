--select @@version

exec msdb.dbo.sp_help_job @enabled='1'


 if  9 =  (select substring(convert(char(12),serverproperty('productversion')), 1, 1))
     begin
EXEC master.dbo.xp_readerrorlog 0, 1, 'Run DBCC CHECK'--, NULL, NULL, NULL, N'desc'
     end
else select NULL 'LogDate',NULL 'ProcessInfo',NULL 'Text'



--select top 100 * from sys.messages where text like '%Run DBCC CHECK%'



if  9 =  (select substring(convert(char(12),serverproperty('productversion')), 1, 1))
     begin
		EXEC master.dbo.xp_readerrorlog 0, 1, 'VIRTUAL_DEVICE'--, NULL, NULL, NULL, N'desc'
		if @@rowcount=0  select '1990-0-0' as 'LogDate','A' as 'ProcessInfo','A' as 'Text' where 1=2
     end
else select '1990-0-0' as 'LogDate','A' as 'ProcessInfo','A' as 'Text' where 1=2