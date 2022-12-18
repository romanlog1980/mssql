set nocount on

declare @version char(12)

set     @version =  convert(char(12),serverproperty('productversion'));



 if  8 =  (select substring(@version, 1, 1))
     begin

        select  serverproperty('machinename')                                        as 'Server_Name',
                isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance_Name',
                lgn.name                                                             as 'Sysadmins'
        from    master.dbo.spt_values spv
        join    master.dbo.sysxlogins lgn
        on      spv.number & lgn.xstatus = spv.number
		where   spv.low = 0
		and     spv.type = 'SRV'
		and     lgn.srvid IS NULL
        and     spv.name = 'sysadmin'
        and     lgn.name not in ('sa','NT AUTHORITY\SYSTEM')
        order by lgn.name
        option (maxdop 1)



 
     end
else

 if  9 = (select substring(@version, 1, 1))
     begin


        select  distinct serverproperty('machinename')                                        as 'Server_Name',
                isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance_Name',
                lgn.name                                                             as 'Sysadmins'
        from    sys.server_role_members rm
        join    sys.server_principals lgn
        on      rm.member_principal_id           = lgn.principal_id
        and     rm.role_principal_id             >=3
        and     rm.role_principal_id             <=10
        and     SUSER_NAME(rm.role_principal_id) = 'sysadmin'
        and     lgn.name                         not in ('sa','NT AUTHORITY\SYSTEM')
        order by lgn.name
        option (maxdop 1)

     end

else

 if  10 = (select substring(@version, 1, 2))  -- CR 375891
     begin


        select  distinct serverproperty('machinename')                                        as 'Server_Name',
                isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance_Name',
                lgn.name                                                             as 'Sysadmins'
        from    sys.server_role_members rm
        join    sys.server_principals lgn
        on      rm.member_principal_id           = lgn.principal_id
        and     rm.role_principal_id             >=3
        and     rm.role_principal_id             <=10
        and     SUSER_NAME(rm.role_principal_id) = 'sysadmin'
        and     lgn.name                         not in ('sa','NT AUTHORITY\SYSTEM')
        order by lgn.name
        option (maxdop 1)

     end
