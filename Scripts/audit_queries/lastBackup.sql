select db_name(),databasepropertyex (db_name(),'Recovery') recovery_mode,
(select DATEDIFF (dd, max(backup_finish_date), GETDATE())
from msdb.dbo.backupset
where type =N'D' and database_name=db_name()) as days_from_last_full_backup,
(select DATEDIFF (dd, max(backup_finish_date), GETDATE()) 
from msdb.dbo.backupset
where type =N'L' and database_name=db_name()) as days_from_last_log_backup,
(select sum(size)*8 from sysfiles where groupid=0) as log_size_KB,
(select cntr_value from master.dbo.sysperfinfo 
where counter_name='Percent Log Used' and instance_name=db_name() ) as Percent_Log_Used