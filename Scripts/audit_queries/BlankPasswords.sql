set nocount on
declare @version char(12)

set     @version =  convert(char(12),serverproperty('productversion'));

 if  8 =  (select substring(@version, 1, 1))
     begin

        select  distinct serverproperty('machinename')                               as 'Server_Name',
                isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance_Name',
                a.name                                                               as 'Login_With_Blank_Password'
        from    master.dbo.syslogins a
        join    master.dbo.sysxlogins b
        on      a.sid = b.sid
        where   a.isntuser !=1
        and     a.isntgroup !=1
        and     b.password is null
        and     a.name !='distributor_admin'
        and     b.srvid IS NULL
        order by a.name
        option (maxdop 1)



     end


 if  9 = (select substring(@version, 1, 1))
     begin

        select  serverproperty('machinename')                                        as 'Server_Name',
                isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance_Name',  
                name                                                                 as 'Login_With_Blank_Password'
        from    master.sys.sql_logins
        where   pwdcompare('',password_hash)=1
        order by name
        option (maxdop 1)
        
     end
     
     
  if  '10' = (select substring(@version, 1, 2))  -- CR 375891
     begin

        select  serverproperty('machinename')                                        as 'Server_Name',
                isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance_Name',  
                name                                                                 as 'Login_With_Blank_Password'
        from    master.sys.sql_logins
        where   pwdcompare('',password_hash)=1
        order by name
        option (maxdop 1)
        
     end