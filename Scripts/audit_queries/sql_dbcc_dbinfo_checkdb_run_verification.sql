declare @version char(12);
set     @version =  convert(char(12),serverproperty('productversion'));

declare @dbid    int
declare @maxdbid int
declare @string  nvarchar(4000)
declare @dbname  sysname 

create table  #dbinfo_table (server_name   nvarchar(255), 
                           instance_name nvarchar(255), 
                           database_name nvarchar(255), 
                           database_id   int, 
                           value         nvarchar(255))

create table #dbinfo_2000(ParentObject  varchar(255),
                              Object        varchar(255),
                              Field         varchar(255),
                              value         varchar(255))

 if  '10' = (select substring(@version, 1, 2))  -- CR 375891
     begin
          set quoted_identifier off
          set nocount on 

          set @dbid    = 1
          set @maxdbid = (select max(dbid) from master..sysdatabases)

          while @dbid <= @maxdbid
                begin
                     if  null = (select db_name(@dbid))
                         set @dbid = @dbid + 1
                     else if lower(db_name(@dbid)) = N'tempdb'
						 set @dbid = @dbid + 1
                     else if N'ONLINE' <> (select state_desc from sys.databases where database_id = @dbid)
                         set @dbid = @dbid + 1
                     else 
                         begin 
                              set @dbname = db_name(@dbid)

                              set @string = "INSERT INTO #dbinfo_2000 EXEC('DBCC DBINFO(''" + rtrim(ltrim(@dbname)) + "'') WITH TABLERESULTS, NO_INFOMSGS')";
 
                              execute sp_executesql @string

                              insert into #dbinfo_table
                              select distinct  -- distinct added in CR 375891
                                     convert(sysname,(serverproperty('machinename'))),
                                     isnull((convert(sysname,(serverproperty('instancename')))),convert(sysname,(serverproperty('machinename')))),
                                     db_name(@dbid),
                                     @dbid,
                                     value
                                from #dbinfo_2000
                               where Field = 'dbi_dbccLastKnownGood'

                              delete from #dbinfo_2000

							  set @dbid = @dbid + 1

                         end
                end

                select server_name                      as 'Server_Name',                                           
                       instance_name                    as 'Instance_Name', 
                       database_name                    as 'Database_Name',
                       database_id                      as 'Database_ID',
                       CASE value
						WHEN N'1900-01-01 00:00:00.000' THEN 'Never'
						ELSE value
                       END								as 'Date_of_last_DBCC_CHECKDB',
                       CASE value
						WHEN N'1900-01-01 00:00:00.000' THEN 'Never'
                        ELSE CONVERT(nvarchar(10),DATEDIFF(day,convert(datetime,([value])),GETDATE()))
					   END								as 'Days_Since_Last_DBCC_CHECKDB'
                  from #dbinfo_table
                 where DATEDIFF(day,convert(datetime,([value])),GETDATE()) > 7
                 order by 'Server_Name','Instance_Name','Database_Name'

                set quoted_identifier on
     end
 else -- CR 375891
 if  9 = (select substring(@version, 1, 1))
     begin
          set quoted_identifier off
          set nocount on 

          set @dbid    = 1
          set @maxdbid = (select max(dbid) from master..sysdatabases)

          while @dbid <= @maxdbid
                begin
                     if  null = (select db_name(@dbid))
                         set @dbid = @dbid + 1
                     else if lower(db_name(@dbid)) = N'tempdb'
						 set @dbid = @dbid + 1
                     else if N'ONLINE' <> (select state_desc from sys.databases where database_id = @dbid)
                         set @dbid = @dbid + 1
                     else 
                         begin 
                              set @dbname = db_name(@dbid)

                              set @string = "INSERT INTO #dbinfo_2000 EXEC('DBCC DBINFO(''" + rtrim(ltrim(@dbname)) + "'') WITH TABLERESULTS, NO_INFOMSGS')";
 
                              execute sp_executesql @string

                              insert into #dbinfo_table
                              select convert(sysname,(serverproperty('machinename'))),
                                     isnull((convert(sysname,(serverproperty('instancename')))),convert(sysname,(serverproperty('machinename')))),
                                     db_name(@dbid),
                                     @dbid,
                                     value
                                from #dbinfo_2000
                               where Field = 'dbi_dbccLastKnownGood'

                              delete from #dbinfo_2000

							  set @dbid = @dbid + 1

                         end
                end

                select server_name                      as 'Server_Name',                                           
                       instance_name                    as 'Instance_Name', 
                       database_name                    as 'Database_Name',
                       database_id                      as 'Database_ID',
                       CASE value
						WHEN N'1900-01-01 00:00:00.000' THEN 'Never'
						ELSE value
                       END								as 'Date_of_last_DBCC_CHECKDB',
                       CASE value
						WHEN N'1900-01-01 00:00:00.000' THEN 'Never'
                        ELSE CONVERT(nvarchar(10),DATEDIFF(day,convert(datetime,([value])),GETDATE()))
					   END								as 'Days_Since_Last_DBCC_CHECKDB'
                  from #dbinfo_table
                 where DATEDIFF(day,convert(datetime,([value])),GETDATE()) > 7
                 order by 'Server_Name','Instance_Name','Database_Name'

                set quoted_identifier on
     end
 else 
     if  8 =  (select substring(@version, 1, 1))
         begin
               select ''  as 'Server_Name',                                           
                      ''  as 'Instance_Name', 
                      ''  as 'Database_Name',
                      ''  as 'Database_ID',
                      ''  as 'Date_of_last_DBCC_CHECKDB',
                      ''  as 'Days_Since_Last_DBCC_CHECKDB'
               where 1=2
              /*Need to determine if there is a viable way to determine this programatically within SQL 2000 */
         end

drop table #dbinfo_table
drop table #dbinfo_2000