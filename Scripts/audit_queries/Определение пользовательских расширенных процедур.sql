-- Внимание! 32-разрядные расширенные процедуры не будут работать на IA64 архитектуре.

USE master
GO
		SELECT	o.name, 
				user_name(o.uid), 
				o.crdate, 
				xtype=convert(nchar(2), o.xtype), 
				o.id, OBJECTPROPERTY(o.id, N'IsMSShipped') 
		FROM dbo.sysobjects o WITH (NOLOCK) 
		WHERE		OBJECTPROPERTY(o.id, N'IsExtendedProc') = 1 
				AND OBJECTPROPERTY(o.id, N'IsMSShipped') = 0 
				AND o.name not like N'#%%' 
		ORDER BY o.name
