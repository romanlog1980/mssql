--SELECT * FROM msdb.dbo.backupset b
SELECT T1.Name AS DatabaseName,
       COALESCE(
           CONVERT(VARCHAR(12), MAX(T2.backup_finish_date), 101),
           '---'
       ) AS LastBackUpTaken,
       COALESCE(CONVERT(VARCHAR(12), MAX(T2.user_name), 101), 'NA') AS UserName
FROM   sysdatabases T1
       LEFT  JOIN msdb.dbo.backupset T2
            ON  T2.database_name = T1.name
GROUP BY
       T1.Name
ORDER BY
       T1.Name
       
       
SELECT DB_NAME(),
       DATABASEPROPERTYEX(DB_NAME(), 'Recovery') recovery_mode,
       (
           SELECT DATEDIFF(dd, MAX(backup_finish_date), GETDATE())
           FROM   msdb.dbo.backupset
           WHERE  TYPE = N'D'
                  AND database_name = DB_NAME()
       ) AS days_from_last_full_backup,
       (
           SELECT DATEDIFF(dd, MAX(backup_finish_date), GETDATE())
           FROM   msdb.dbo.backupset
           WHERE  TYPE = N'L'
                  AND database_name = DB_NAME()
       ) AS days_from_last_log_backup,
       (
           SELECT SUM(SIZE) * 8
           FROM   sysfiles
           WHERE  groupid = 0
       ) AS log_size_KB,
       (
           SELECT cntr_value
           FROM   MASTER.dbo.sysperfinfo
           WHERE  counter_name = 'Percent Log Used'
                  AND instance_name = DB_NAME()
       ) AS Percent_Log_Used
