--Signature="4365702A5E7B6966" 


--/**************************************************************************************************************/
--/**************************************************************************************************************/
--/****    Microsoft SQL Server Risk Assesment Program                                                       ****/
--/****                                                                                                      ****/
--/****    Display all known suspect pages                                                                   ****/
--/****                                                                                                      ****/
--/****    Updated 01 Dec 2008 (wardp): CR 257260                                                            ****/
--/****    djaiswal 17 Sep 2009 - Addded SQL2K8 Validation Ref - CR 375891                                                                                               ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****                                                                                                      ****/
--/****    Copyright � Microsoft Corporation. All rights reserved.                                           ****/
--/**************************************************************************************************************/
--/**************************************************************************************************************/


declare @version char(12);
set     @version =  convert(char(12),serverproperty('productversion'));

if  '10' = (select substring(@version, 1, 2))
     begin
         select distinct serverproperty('machinename')                               as 'Server_Name',                                           
                isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance_Name',
                db_name(database_id)                                                 as 'Database_Name',
                file_id                                                              as 'File_Id',
                page_id                                                              as 'Page_Id',
                CASE event_type
                    WHEN 1 THEN '823 or non-specific 824 error'
                    WHEN 2 THEN 'Bad checksum'
                    WHEN 3 THEN 'Torn page'
                    ELSE NULL
                END                                                                  as 'Event_Type',
                error_count                                                          as 'Error_Count',
                last_update_date                                                     as 'Last_Update_Date'
           from msdb..suspect_pages
           where event_type in (1,2,3) 
     end
 else 
 if  9 = (select substring(@version, 1, 1))
     begin
         select distinct serverproperty('machinename')                               as 'Server_Name',                                           
                isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance_Name',
                db_name(database_id)                                                 as 'Database_Name',
                file_id                                                              as 'File_Id',
                page_id                                                              as 'Page_Id',
                CASE event_type
                    WHEN 1 THEN '823 or non-specific 824 error'
                    WHEN 2 THEN 'Bad checksum'
                    WHEN 3 THEN 'Torn page'
                    ELSE NULL
                END                                                                  as 'Event_Type',
                error_count                                                          as 'Error_Count',
                last_update_date                                                     as 'Last_Update_Date'
           from msdb..suspect_pages
           where event_type in (1,2,3) 
     end
 else 
     if  8 =  (select substring(@version, 1, 1))
         begin

         select distinct serverproperty('machinename')                               as 'Server_Name',                                           
                isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance_Name',
                ''                                                                   as 'Database_Name',
                ''                                                                   as 'File_Id',
                ''                                                                   as 'Page_Id',
                ''                                                                   as 'Event_Type',
                ''                                                                   as 'Error_Count',
                ''                                                                   as 'Last_Update_Date'
          where 1 = 2
         end;




