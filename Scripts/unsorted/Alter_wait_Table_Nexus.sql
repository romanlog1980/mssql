DROP INDEX [cidx] ON [dbo].[tbl_OS_WAIT_STATS] WITH ( ONLINE = OFF )
GO

ALTER TABLE tbl_OS_WAIT_STATS DROP COLUMN [wait_category]
GO
ALTER TABLE tbl_OS_WAIT_STATS ADD 
	[wait_category]           AS (
	    CASE 
	         WHEN [wait_type] LIKE 'LCK%' THEN 'Locks'
	         WHEN [wait_type] LIKE 'PAGEIO%' THEN 'Page I/O Latch'
	         WHEN [wait_type] LIKE 'PAGELATCH%' THEN 'Page Latch (non-I/O)'
	         WHEN [wait_type] LIKE 'LATCH%' THEN 'Latch (non-buffer)'
	         WHEN [wait_type] LIKE 'IO_COMPLETION' THEN 'I/O Completion'
	         WHEN [wait_type] LIKE 'ASYNC_NETWORK_IO' THEN 
	              'Network I/O (client fetch)'
	         WHEN [wait_type] = 'CMEMTHREAD'
	    OR [wait_type] = 'SOS_RESERVEDMEMBLOCKLIST'
	    OR [wait_type] = 'RESOURCE_SEMAPHORE' THEN 'Memory' WHEN [wait_type] 
	       LIKE 'RESOURCE_SEMAPHORE_%' THEN 'Compilation' WHEN [wait_type] LIKE 
	       'MSQL_XP' THEN 'XProc' WHEN [wait_type] LIKE 'WRITELOG' THEN 
	       'Writelog' WHEN [wait_type] = 'SP_SERVER_DIAGNOSTICS_SLEEP'
	    OR [wait_type] = 'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP'
	    OR [wait_type] = 'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP'
	    OR [wait_type] = 'DIRTY_PAGE_POLL'
	    OR [wait_type] = 'HADR_FILESTREAM_IOMGR_IOCOMPLETION'
	    OR [wait_type] = 'DISPATCHER_QUEUE_SEMAPHORE'
	    OR [wait_type] = 'FT_IFTS_SCHEDULER_IDLE_WAIT'
	    OR [wait_type] = 'WAITFOR'
	    OR [wait_type] = 'FT_IFTSHC_MUTEX'
	    OR [wait_type] = 'EXECSYNC'
	    OR [wait_type] = 'SQLTRACE_INCREMENTAL_FLUSH_SLEEP'
	    OR [wait_type] = 'XE_TIMER_EVENT'
	    OR [wait_type] = 'XE_DISPATCHER_WAIT'
	    OR [wait_type] = 'WAITFOR_TASKSHUTDOWN'
	    OR [wait_type] = 'WAIT_FOR_RESULTS'
	    OR [wait_type] = 'SQLTRACE_BUFFER_FLUSH'
	    OR [wait_type] = 'SNI_HTTP_ACCEPT'
	    OR [wait_type] = 'SLEEP_TEMPDBSTARTUP'
	    OR [wait_type] = 'SLEEP_TASK'
	    OR [wait_type] = 'SLEEP_SYSTEMTASK'
	    OR [wait_type] = 'SLEEP_MSDBSTARTUP'
	    OR [wait_type] = 'SLEEP_DCOMSTARTUP'
	    OR [wait_type] = 'SLEEP_DBSTARTUP'
	    OR [wait_type] = 'SLEEP_BPOOL_FLUSH'
	    OR [wait_type] = 'SERVER_IDLE_CHECK'
	    OR [wait_type] = 'RESOURCE_QUEUE'
	    OR [wait_type] = 'REQUEST_FOR_DEADLOCK_SEARCH'
	    OR [wait_type] = 'ONDEMAND_TASK_QUEUE'
	    OR [wait_type] = 'LOGMGR_QUEUE'
	    OR [wait_type] = 'LAZYWRITER_SLEEP'
	    OR [wait_type] = 'KSOURCE_WAKEUP'
	    OR [wait_type] = 'FSAGENT'
	    OR [wait_type] = 'CLR_MANUAL_EVENT'
	    OR [wait_type] = 'CLR_AUTO_EVENT'
	    OR [wait_type] = 'CHKPT'
	    OR [wait_type] = 'CHECKPOINT_QUEUE'
	    OR [wait_type] = 'BROKER_TO_FLUSH'
	    OR [wait_type] = 'BROKER_TASK_STOP'
	    OR [wait_type] = 'BROKER_TRANSMITTER'
	    OR [wait_type] = 'BROKER_RECEIVE_WAITFOR'
	    OR [wait_type] = 'BROKER_EVENTHANDLER'
	    OR [wait_type] = 'DBMIRROR_EVENTS_QUEUE'
	    OR [wait_type] = 'DBMIRROR_DBM_EVENT'
	    OR [wait_type] = 'DBMIRRORING_CMD'
		 OR [wait_type] = 'CLR_SEMAPHORE'
		 OR [wait_type] = 'PREEMPTIVE_XE_DISPATCHER'
		 OR [wait_type] = 'CXCONSUMER'
	    OR [wait_type] = 'HADR_WORK_QUEUE'
	    OR [wait_type] = 'HADR_LOGCAPTURE_WAIT'
	    OR [wait_type] = 'HADR_NOTIFICATION_DEQUEUE'
		 OR [wait_type] = 'REDO_THREAD_PENDING_WORK'
	    
	    	    OR [wait_type] = 'HADR_CLUSAPI_CALL'
	    	     	    OR [wait_type] = 'HADR_TIMER_TASK'
	    	     	OR [wait_type] = 'QDS_SHUTDOWN_QUEUE'
					OR [wait_type] = 'PWAIT_EXTENSIBILITY_CLEANUP_TASK'
					OR [wait_type] = 'VDI_CLIENT_OTHER'

	    
	    OR [wait_type] = 'PARALLEL_REDO_WORKER_WAIT_WORK'
		OR [wait_type] = 'SOS_WORK_DISPATCHER'
	    OR [wait_type] = 'DBMIRROR_WORKER_QUEUE' THEN 'IGNORABLE' ELSE 
	       [wait_type] END
	)
 

GO

CREATE CLUSTERED INDEX [cidx] ON [dbo].[tbl_OS_WAIT_STATS]
(
	[runtime] ASC,
	[wait_category] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO

