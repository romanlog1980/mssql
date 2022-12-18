use master
go
select o.name, user_name(o.uid), o.crdate, xtype=convert(nchar(2), o.xtype), o.id, OBJECTPROPERTY(o.id, N'IsMSShipped') from 
dbo.sysobjects o with (NOLock) where (OBJECTPROPERTY(o.id, N'IsProcedure') = 1 or OBJECTPROPERTY(o.id, N'IsExtendedProc') = 1 or OBJECTPROPERTY(o.id, 
N'IsReplProc') = 1 or OBJECTPROPERTY(o.id, N'IsTable') = 1 or OBJECTPROPERTY(o.id, N'IsView') = 1 or
OBJECTPROPERTY(o.id, N'IsTableFunction') = 1) and OBJECTPROPERTY(o.id, N'IsMSShipped') = 0 and o.name not like N'#%%' order by o.name
Go

use tempdb
go
select o.name, user_name(o.uid), o.crdate, xtype=convert(nchar(2), o.xtype), o.id, OBJECTPROPERTY(o.id, N'IsMSShipped') from 
dbo.sysobjects o with (NOLock) where (OBJECTPROPERTY(o.id, N'IsProcedure') = 1 or OBJECTPROPERTY(o.id, N'IsExtendedProc') = 1 or OBJECTPROPERTY(o.id, 
N'IsReplProc') = 1 or OBJECTPROPERTY(o.id, N'IsTable') = 1 or OBJECTPROPERTY(o.id, N'IsView') = 1 or
OBJECTPROPERTY(o.id, N'IsTableFunction') = 1) and OBJECTPROPERTY(o.id, N'IsMSShipped') = 0 and o.name not like N'#%%' order by o.name
Go

use msdb 
go
select o.name, user_name(o.uid), o.crdate, xtype=convert(nchar(2), o.xtype), o.id, OBJECTPROPERTY(o.id, N'IsMSShipped') from 
dbo.sysobjects o with (NOLock) where (OBJECTPROPERTY(o.id, N'IsProcedure') = 1 or OBJECTPROPERTY(o.id, N'IsExtendedProc') = 1 or OBJECTPROPERTY(o.id, 
N'IsReplProc') = 1 or OBJECTPROPERTY(o.id, N'IsTable') = 1 or OBJECTPROPERTY(o.id, N'IsView') = 1 or
OBJECTPROPERTY(o.id, N'IsTableFunction') = 1) and OBJECTPROPERTY(o.id, N'IsMSShipped') = 0 and o.name not like N'#%%' order by o.name
