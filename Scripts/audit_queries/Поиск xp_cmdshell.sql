declare @pattern varchar (100)
declare @name sysname
declare @sql varchar(4000)
declare @isonline nvarchar (20)

select @pattern = '%xp_cmdshell%' 

 create table #spdbdesc
	(
	dbname sysname, --nvarchar(24),
    pattern nvarchar(100)
	, obj_id int
	, obj_name sysname --nvarchar(24)
	)
	declare ms_crs_c007 cursor for
	  select [name] from  master..sysdatabases 
		open ms_crs_c007
			FETCH NEXT FROM ms_crs_c007 into @name 
				while @@fetch_status = 0
				begin
				 select @isonline=cast(DATABASEPROPERTYEX(@name , 'STATUS') as nvarchar(20))
				if @isonline<>'OFFLINE' begin


                 set @sql='use ['+@name +']'+
				 ' insert into #spdbdesc (dbname, pattern, obj_id, obj_name) select  '''+@name+''','''+@pattern+''',o.id, o.name from dbo.sysobjects o
						where exists ( select 1 from syscomments c1 
                       left join syscomments c2
                       on c1.id = c2.id and c1.colid + 1 = c2.colid                    
                       WHERE c1.id = o.id  AND UPPER(right(c1.text, 2000) + left(isnull(c2.text, ''''), 2000)) like UPPER('''+@pattern+'''))
						order by o.name'
					--print @sql
                 exec(@sql)
				end
               fetch next from ms_crs_c007 into @name
               end
		CLOSE ms_crs_c007
    deallocate ms_crs_c007


select * from  #spdbdesc
drop table #spdbdesc
