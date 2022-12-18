USE [Xevents]
GO

/****** Object:  Table [dbo].[XEvents]    Script Date: 18.12.2022 13:56:29 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[XEvents](
	[Event_TimeStamp] [datetimeoffset](7) NULL,
	[activity_id] [uniqueidentifier] NULL,
	[event_sequence] [int] NULL,
	[Name] [varchar](50) NULL,
	[session_id] [int] NULL,
	[client_app_name] [varchar](300) NULL,
	[client_hostname] [varchar](300) NULL,
	[username] [varchar](300) NULL,
	[database_name] [sysname] NULL,
	[database_id] [int] NULL,
	[object_id] [int] NULL,
	[object_name] [sysname] NULL,
	[object_type] [varchar](100) NULL,
	[offset] [int] NULL,
	[offset_end] [int] NULL,
	[nest_level] [int] NULL,
	[CPU] [bigint] NULL,
	[Duration] [bigint] NULL,
	[physical_reads] [bigint] NULL,
	[logical_reads] [bigint] NULL,
	[writes] [bigint] NULL,
	[spills] [int] NULL,
	[row_count] [bigint] NULL,
	[statement] [varchar](max) NULL,
	[batch_text] [varchar](max) NULL,
	[SQLText] [varchar](max) NULL,
	[plan_handle] [varbinary](max) NULL,
	[query_hash_signed] [bigint] NULL,
	[query_plan_hash_signed] [bigint] NULL,
	[result] [varchar](100) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO


