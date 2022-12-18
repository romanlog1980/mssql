/************************************************************
 * Code formatted by SoftTree SQL Assistant © v6.2.112
 * Time: 8/7/2012 3:46:49 PM
 ************************************************************/

SELECT DB_NAME(),
       fg.groupid,
       fg.groupname,
       fileid,
       CONVERT(DECIMAL(12, 2), ROUND(s.size / 128.000, 2)) AS file_size,
       CONVERT(
           DECIMAL(12, 2),
           ROUND(FILEPROPERTY(s.name, 'SpaceUsed') / 128.000, 2)
       )  AS space_used,
       CONVERT(
           DECIMAL(12, 2),
           ROUND(
               (s.size -FILEPROPERTY(s.name, 'SpaceUsed')) / 
               128.000,
               2
           )
       )  AS free_space,
       s.name,
       s.filename
FROM   sys.sysfiles s
       LEFT OUTER JOIN sys.sysfilegroups fg
            ON  s.groupid = fg.groupid
WHERE fg.groupid IS NOT NULL