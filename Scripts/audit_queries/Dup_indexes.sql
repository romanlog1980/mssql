/************************************************************
 * Code formatted by SoftTree SQL Assistant © v6.5.278
 * Time: 2017-12-28 3:05:26 PM
 ************************************************************/

;
WITH IndexColumns AS(
         SELECT DISTINCT SCHEMA_NAME(o.schema_id) AS 'SchemaName',
                OBJECT_NAME(o.object_id)  AS TableName,
                i.Name                    AS IndexName,
                o.object_id,
                i.index_id,
                i.type,
                (
                    SELECT CASE key_ordinal
                                WHEN 0 THEN NULL
                                ELSE '[' + COL_NAME(k.object_id, column_id) + 
                                     '] ' + CASE 
                                                 WHEN is_descending_key = 1 THEN 
                                                      'Desc'
                                                 ELSE 'Asc'
                                            END
                           END AS [data()]
                    FROM   sys.index_columns (NOLOCK) AS k
                    WHERE  k.object_id = i.object_id
                           AND k.index_id = i.index_id
                    ORDER BY
                           key_ordinal,
                           column_id
                           
                           FOR XML PATH('')
                )                         AS cols,
                CASE 
                     WHEN i.index_id = 1 THEN (
                              SELECT '[' + NAME + ']' AS [data()]
                              FROM   sys.columns (NOLOCK) AS c
                              WHERE  c.object_id = i.object_id
                                     AND c.column_id NOT IN (SELECT column_id
                                                             FROM   sys.index_columns (NOLOCK) AS 
                                                                    kk
                                                             WHERE  kk.object_id = 
                                                                    i.object_id
                                                                    AND kk.index_id = 
                                                                        i.index_id)
                              ORDER BY
                                     column_id
                                     
                                     FOR XML PATH('')
                          )
                     ELSE (
                              SELECT '[' + COL_NAME(k.object_id, column_id) + 
                                     ']' AS [data()]
                              FROM   sys.index_columns (NOLOCK) AS k
                              WHERE  k.object_id = i.object_id
                                     AND k.index_id = i.index_id
                                     AND is_included_column = 1
                                     AND k.column_id NOT IN (SELECT column_id
                                                             FROM   sys.index_columns 
                                                                    kk
                                                             WHERE  k.object_id = 
                                                                    kk.object_id
                                                                    AND kk.index_id = 
                                                                        1)
                              ORDER BY
                                     key_ordinal,
                                     column_id
                                     
                                     FOR XML PATH('')
                          )
                END                       AS inc
         FROM   sys.indexes (NOLOCK)      AS i
                INNER JOIN sys.objects o(NOLOCK)
                     ON  i.object_id = o.object_id
                INNER JOIN sys.index_columns ic(NOLOCK)
                     ON  ic.object_id = i.object_id
                     AND ic.index_id = i.index_id
                INNER JOIN sys.columns c(NOLOCK)
                     ON  c.object_id = ic.object_id
                     AND c.column_id = ic.column_id
         WHERE  o.type = 'U'
                AND i.index_id <> 0
                AND i.type <> 3
                AND i.type <> 5
                AND i.type <> 6
                AND i.type <> 7
         GROUP BY
                o.schema_id,
                o.object_id,
                i.object_id,
                i.Name,
                i.index_id,
                i.type
     ),
     
     DuplicatesTable AS
     
     (
         SELECT ic1.SchemaName,
                ic1.TableName,
                ic1.IndexName,
                ic1.object_id,
                ic2.IndexName  AS DuplicateIndexName,
                CASE 
                     WHEN ic1.index_id = 1 THEN ic1.cols + ' (Clustered)'
                     WHEN ic1.inc = '' THEN ic1.cols
                     WHEN ic1.inc IS NULL THEN ic1.cols
                     ELSE ic1.cols + ' INCLUDE ' + ic1.inc
                END            AS IndexCols,
                ic1.index_id
         FROM   IndexColumns ic1
                JOIN IndexColumns ic2
                     ON  ic1.object_id = ic2.object_id
                     AND ic1.index_id < ic2.index_id
                     AND ic1.cols = ic2.cols
                     AND (
                             ISNULL(ic1.inc, '') = ISNULL(ic2.inc, '')
                             OR ic1.index_id = 1
                         )
     )

SELECT SchemaName,
       TableName,
       IndexName,
       DuplicateIndexName,
       IndexCols,
       index_id,
       OBJECT_ID,
       0                AS IsXML
FROM   DuplicatesTable     dt
ORDER BY
       1,
       2,
       3

USE the below T -SQL script TO generate the complete list OF duplicate XML 
indexes IN a given DATABASE :;
WITH XMLTable AS (
         SELECT OBJECT_NAME(x.object_id)  AS 'TableName',
                SCHEMA_NAME(o.schema_id)  AS SchemaName,
                x.object_id,
                x.name,
                x.index_id,
                x.using_xml_index_id,
                x.secondary_type,
                CONVERT(NVARCHAR(MAX), x.secondary_type_desc) AS secondary_type_desc,
                ic.column_id
         FROM   sys.xml_indexes x(NOLOCK)
                JOIN sys.objects o(NOLOCK)
                     ON  x.object_id = o.object_id
                JOIN sys.index_columns (NOLOCK) ic
                     ON  x.object_id = ic.object_id
                     AND x.index_id = ic.index_id
     ),
     
     DuplicatesXMLTable AS(
         SELECT x1.SchemaName,
                x1.TableName,
                x1.name                 AS IndexName,
                x2.name                 AS DuplicateIndexName,
                x1.secondary_type_desc  AS IndexType,
                x1.index_id,
                x1.object_id,
                ROW_NUMBER() OVER(ORDER BY x1.SchemaName, x1.TableName, x1.name, x2.name) AS 
                seq1,
                ROW_NUMBER() OVER(
                    ORDER BY x1.SchemaName DESC,
                    x1.TableName DESC,
                    x1.name DESC,
                    x2.name DESC
                )                       AS seq2,
                NULL                    AS inc
         FROM   XMLTable x1
                JOIN XMLTable x2
                     ON  x1.object_id = x2.object_id
                     AND x1.index_id < x2.index_id
                     AND x1.using_xml_index_id = x2.using_xml_index_id
                     AND x1.secondary_type = x2.secondary_type
     )

SELECT SchemaName,
       TableName,
       IndexName,
       DuplicateIndexName,
       IndexType COLLATE      SQL_Latin1_General_CP1_CI_AS,
       index_id,
       OBJECT_ID,
       1                   AS IsXML
FROM   DuplicatesXMLTable     dtxml
ORDER BY
       1,
       2,
       3