/************************************************************
 * Code formatted by SoftTree SQL Assistant © v6.0.28
 * Time: 7/7/2011 4:24:28 PM
 ************************************************************/

 WITH ByWaitTypes(
                     [“ип ожидани€],
                     [ожидани€ сигнала %],
                     [ожидани€ ресурса %],
                     [ожидани€ ms]
                 ) AS
(
    SELECT TOP 20 wait_type,
           CAST(
               100.0 * SUM(signal_wait_time_ms) / SUM(wait_time_ms) AS NUMERIC(20, 2)
           ),
           CAST(
               100.0 * SUM(wait_time_ms - signal_wait_time_ms) / SUM(wait_time_ms) 
               AS NUMERIC(20, 2)
           ),
           SUM(wait_time_ms)
    FROM   sys.dm_os_wait_stats
    WHERE  wait_time_ms <> 0
    GROUP BY
           wait_type
    ORDER BY
           SUM(wait_time_ms) DESC
)
SELECT TOP 1 '“ип ожидани€' = N'BCE!',
       'ожидани€ сигнала %' = (
           SELECT CAST(
                      100.0 * SUM(signal_wait_time_ms) /
                      SUM(wait_time_ms) AS NUMERIC(20, 2)
                  )
           FROM   sys.dm_os_wait_stats
       ),
       'ожидани€ ресурса %' = (
           SELECT CAST(
                      100.0 * SUM(wait_time_ms - signal_wait_time_ms) /
                      SUM(wait_time_ms) AS NUMERIC(20, 2)
                  )
           FROM   sys.dm_os_wait_stats
       ),
       'ожидани€ ms' = (
           SELECT SUM(wait_time_ms)
           FROM   sys.dm_os_wait_stats
       )
FROM   sys.dm_os_wait_stats
UNION
SELECT [“ип ожидани€],
       [ожидани€ сигнала %],
       [ожидани€ ресурса %],
       [ожидани€ ms]
FROM   ByWaitTypes
ORDER BY
       'ожидани€ ms' DESC