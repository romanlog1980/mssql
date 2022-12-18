declare @version char(12);
set     @version =  convert(char(12),serverproperty('productversion'));

 if  '10' = (select substring(@version, 1, 2)) 
     select name from sys.sql_logins where is_policy_checked =1

 else
 
 if  9 = (select substring(@version, 1, 1))
      select name from sys.sql_logins where is_policy_checked =1
      
 else 

 if  8 = (select substring(@version, 1, 1))
      select NULL as name where 1=2
