/************************************************************
 * Code formatted by SoftTree SQL Assistant � v6.5.278
 * Time: 6/4/2019 4:50:00 AM
 ************************************************************/

SELECT query_hash_signed,
       SUM(duration)/1000000.00  AS [��������� ������������(�)], 
       AVG(duration)/1000000.00  AS [������� ������������(�)],
       MAX(duration)/1000000.00  AS [������������ ������������(�)],
       AVG(logical_reads)  AS [������� ���-�� ������],
       COUNT(*) AS [���-�� ��������],
       CAST(
           100. * SUM(duration) / SUM(SUM(duration)) OVER() AS NUMERIC(5, 2)
       )              AS [% ����],
       (
           SELECT TOP(1)       replace(replace(replace(LEFT(statement, 60),char(10),''),char(13),''), CHAR(9), ' ')
           FROM   Trace_20190827_Diasoft_4  AS Q2
           WHERE  Q2.query_hash_signed = Q1.query_hash_signed
       )              AS [������ �������]
FROM   Trace_20190827_Diasoft_4       AS Q1
WHERE 1=1 
--AND NAME = 'sp_statement_completed'
  AND Q1.query_plan_hash_signed <> 0
GROUP BY
       query_hash_signed, Q1.[object_id]
ORDER BY
       SUM(duration) DESC;
       
       
