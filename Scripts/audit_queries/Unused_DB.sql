sp_msforeachdb 'Select @@Servername As Servername, ''?'' AS DBName,
IsSystemDatabase,
      MAX(last_user_lookup) last_user_lookup,
      MAX(last_user_scan) last_user_scan,
      MAX(last_user_seek) last_user_seek,
      MAX(last_user_update) last_user_update
from [?].sys.dm_db_index_usage_stats
INNER JOIN 
(
      SELECT dtb.name, CAST(case when dtb.name in (''master'',''model'',''msdb'',''tempdb'') then 1 else dtb.is_distributor end AS bit) IsSystemDatabase
      FROM master.sys.databases AS dtb
) systemdatabases
ON systemdatabases.name = ''?''
GROUP BY IsSystemDatabase'
