CREATE PROCEDURE [dbo].[GetWaitStats]
AS 
BEGIN
     
     ;WITH ordered_set(
              row_order,
              wait_type,
              wait_category,
              runtime,
              waiting_tasks_count,
              wait_time_ms,
              max_wait_time_ms
          ) AS
          (
              SELECT ROW_NUMBER() OVER(PARTITION BY wait_type ORDER BY rownum),
                     wait_type,
                     wait_category,
                     runtime,
                     waiting_tasks_count,
                     wait_time_ms,
                     max_wait_time_ms
              FROM   dbo.tbl_OS_WAIT_STATS
             -- WHERE  runtime BETWEEN ISNULL('2015-04-20T05:51:21.000', '1/1/1900') AND ISNULL('2015-04-21T04:50:47.000', '12/31/9999')
          )

SELECT  e.runtime,
       
       b.wait_type,
       b.wait_category,
       b.runtime             AS START,
       e.runtime             AS endtime,
       DATEDIFF(ss, b.runtime, e.runtime) AS delta_seconds,
       CASE 
            WHEN e.max_wait_time_ms >= b.max_wait_time_ms THEN e.wait_time_ms - b.wait_time_ms
            ELSE NULL
       END                   AS delta_wait_time_ms,
       CASE 
            WHEN e.max_wait_time_ms >= b.max_wait_time_ms THEN ABS(e.wait_time_ms - b.wait_time_ms)
            ELSE NULL
       END / DATEDIFF(ss, b.runtime, e.runtime) AS wait_ms_per_sec,
	   CASE WHEN e.waiting_tasks_count >=b.waiting_tasks_count THEN e.waiting_tasks_count - b.waiting_tasks_count
	   ELSE NULL
	   END /DATEDIFF(ss, b.runtime, e.runtime) AS waiting_tasks_count_per_sec,
       CASE 
            WHEN e.waiting_tasks_count > b.waiting_tasks_count THEN (1.00000*(e.wait_time_ms - b.wait_time_ms)  / (e.waiting_tasks_count - b.waiting_tasks_count)) / DATEDIFF(ss, b.runtime, e.runtime)  
            ELSE 0
       END                   AS AVG_wait_ms_per_sec,
       CASE 
            WHEN e.waiting_tasks_count > b.waiting_tasks_count THEN e.waiting_tasks_count - b.waiting_tasks_count
            ELSE NULL
       END                   AS delta_waiting_tasks_count

FROM   ordered_set e
       LEFT JOIN ordered_set b
            ON  e.wait_type = b.wait_type
            AND e.row_order = b.row_order + 1
WHERE  1 = 1 
--AND e.wait_category = 'WRITELOG'
       AND b.runtime IS NOT     NULL
ORDER BY
       START,
       wait_type
END
GO


