/************************************************************
 * Code formatted by SoftTree SQL Assistant © v6.5.278
 * Time: 2017-12-28 3:04:20 PM
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
                                     ']'
                           END AS [data()]
                    FROM   sys.index_columns (NOLOCK) AS k
                    WHERE  k.object_id = i.object_id
                           AND k.index_id = i.index_id
                    ORDER BY
                           key_ordinal,
                           column_id
                           
                           FOR XML PATH('')
                )                         AS cols,
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
                )                         AS colsWithSortOrder,
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
                                     column_id FOR XML PATH('')
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
                                     column_id FOR XML PATH('')
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
     ), ResultTable AS
     
     (
         SELECT ic1.SchemaName,
                ic1.TableName,
                ic1.IndexName,
                ic1.object_id,
                ic2.IndexName  AS RedundantIndexName,
                CASE 
                     WHEN ic1.index_id = 1 THEN ic1.colsWithSortOrder + 
                          ' (Clustered)'
                     WHEN ic1.inc = '' THEN ic1.colsWithSortOrder
                     WHEN ic1.inc IS NULL THEN ic1.colsWithSortOrder
                     ELSE ic1.colsWithSortOrder + ' INCLUDE ' + ic1.inc
                END            AS IndexCols,
                CASE 
                     WHEN ic2.index_id = 1 THEN ic2.colsWithSortOrder + 
                          ' (Clustered)'
                     WHEN ic2.inc = '' THEN ic2.colsWithSortOrder
                     WHEN ic2.inc IS NULL THEN ic2.colsWithSortOrder
                     ELSE ic2.colsWithSortOrder + ' INCLUDE ' + ic2.inc
                END            AS RedundantIndexCols,
                ic1.index_id,
                ic1.cols          col1,
                ic2.cols          col2
         FROM   IndexColumns ic1
                JOIN IndexColumns ic2
                     ON  ic1.object_id = ic2.object_id
                     AND ic1.index_id <> ic2.index_id
                     AND NOT (
                             ic1.colsWithSortOrder = ic2.colsWithSortOrder
                             AND ISNULL(ic1.inc, '') = ISNULL(ic2.inc, '')
                         )
                     AND NOT (ic1.index_id = 1 AND ic1.cols = ic2.cols)
                     AND ic1.cols LIKE REPLACE (ic2.cols, '[', '[[]') + '%'
     )

SELECT SchemaName,
       TableName,
       IndexName,
       IndexCols,
       RedundantIndexName,
       RedundantIndexCols,
       OBJECT_ID,
       index_id
FROM   ResultTable
ORDER BY
       1,
       2,
       3,
       5