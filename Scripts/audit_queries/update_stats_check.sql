

SELECT schemas.name               AS table_schema,
       tbls.name                  AS table_name,
       i.name                     AS index_name,
       i.id                       AS table_id,
       i.indid                    AS index_id,
       i.rowmodctr                AS modifiedRows,
       (
           SELECT MAX(rowcnt)
           FROM   sysindexes i2
           WHERE  i.id = i2.id
                  AND i2.indid < 2
       )                          AS rowcnt,
       CONVERT(
           DECIMAL(18, 8),
           CONVERT(DECIMAL(18, 8), i.rowmodctr) / CONVERT(
               DECIMAL(18, 8),
               (
                   SELECT MAX(rowcnt)
                   FROM   sysindexes i2
                   WHERE  i.id = i2.id
                          AND i2.indid < 2
               )
           )
       )                          AS ModifiedPercent,
       STATS_DATE(i.id, i.indid)  AS lastStatsUpdate
FROM   sysindexes i
       INNER JOIN sysobjects tbls
            ON  i.id = tbls.id
       INNER JOIN sysusers schemas
            ON  tbls.uid = schemas.uid
       INNER JOIN information_schema.tables tl
            ON  tbls.name = tl.table_name
            AND schemas.name = tl.table_schema
            AND tl.table_type = 'BASE TABLE'
WHERE  0 < i.indid
       AND i.indid < 255
       AND table_schema <> 'sys'
       AND i.rowmodctr <> 0
       AND i.status NOT IN (8388704, 8388672)
       AND (
               SELECT MAX(rowcnt)
               FROM   sysindexes i2
               WHERE  i.id = i2.id
                     AND i2.indid < 2
           ) > 0


		
	--	TRUNCATE T
	
	--sp_updatestats