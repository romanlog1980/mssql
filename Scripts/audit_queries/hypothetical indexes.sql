--Signature="5E7C1E5D9861CCC7" 


--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****   Enumerate any hypothetical indexes                                                                 ****/
--/****                                                                                                      ****/
--/****   Updated 2009.Apr.14 (wardp)  bug 343764                                                            ****/
--/****   Updated 2009.Jul.16 (wardp)  CR 375891                                                             ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright (c) Microsoft Corporation. All rights reserved.                                         ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/

create table #pfe_table (c1 sql_variant,c2 sql_variant,c13 sql_variant,c4 sql_variant,c5 sql_variant,c6 sql_variant,)



declare @version char(12);
set     @version =  convert(char(12),serverproperty('productversion'));

 if  '10' = (select substring(@version, 1, 2))  -- CR 375891
     begin
         
         EXECUTE sp_MSforeachdb
         'USE [?] ; insert into #pfe_table select serverproperty(''machinename'')                                        as ''Server Name'',                                           
                isnull(serverproperty(''instancename''),serverproperty(''machinename'')) as ''Instance Name'',  
                db_name()                                                            as ''Database Name'', 
                su.name                                                              as ''Owner Name'',  
                object_name(so.object_id)                                            as ''Object Name'',       
                si.name                                                              as ''Index Name''
           from sys.indexes si
           join sys.objects so
             on so.object_id = si.object_id 
           join sys.schemas su 
             on su.schema_id = so.schema_id
          where so.type = ''U''
		  and so.is_ms_shipped = 0
          and so.object_id not in (select major_id from sys.extended_properties where name = N''microsoft_database_tools_support'')		  
		  and indexproperty(so.object_id, si.name, ''IsHypothetical'') = 1
          order by  ''Owner Name'',''Object Name'',''Index Name'''
        
     end
 else -- CR 375891
 if  9 = (select substring(@version, 1, 1))
     begin
     EXECUTE sp_MSforeachdb 
         'USE [?] ; insert into #pfe_table select serverproperty(''machinename'')                                        as ''Server Name'',                                           
                isnull(serverproperty(''instancename''),serverproperty(''machinename'')) as ''Instance Name'',  
                db_name()                                                            as ''Database Name'', 
                su.name                                                              as ''Owner Name'',  
                object_name(so.object_id)                                            as ''Object Name'',       
                si.name                                                              as ''Index Name''
           from sys.indexes si
           join sys.objects so
             on so.object_id = si.object_id 
           join sys.schemas su 
             on su.schema_id = so.schema_id
          where so.type = ''U''
		  and so.is_ms_shipped = 0
          and so.object_id not in (select major_id from sys.extended_properties where name = N''microsoft_database_tools_support'')		  
		  and indexproperty(so.object_id, si.name, ''IsHypothetical'') = 1
          order by  ''Owner Name'',''Object Name'',''Index Name'''
     end
 else 
     begin
     EXECUTE sp_MSforeachdb 
         'USE [?] ; insert into #pfe_table select serverproperty(''machinename'')                                        as ''Server Name'',                                           
                isnull(serverproperty(''instancename''),serverproperty(''machinename'')) as ''Instance Name'',  
                db_name()                                                            as ''Database Name'', 
                user_name(so.uid)                                                    as ''Owner Name'',  
                object_name(so.id)                                                   as ''Object Name'',       
                si.name                                                              as ''Index Name''
           from sysindexes si
           join sysobjects so
             on so.id = si.id 
           where so.xtype != ''S''
		  and OBJECTPROPERTYEX(so.id, ''IsMSShipped'') = 0
          and so.id not in (
			select object_id(objname)
			from   ::fn_listextendedproperty (''microsoft_database_tools_support'', default, default, default, default, NULL, NULL)
			where value = 1)
		  and indexproperty(so.id, si.name, ''IsHypothetical'') = 1
          order by  ''Owner Name'',''Object Name'',''Index Name''  '
     end      





select * from #pfe_table
drop table #pfe_table