USE [Retail]
GO
/****** Object:  StoredProcedure [dbo].[X5_Web_AddTasks]    Script Date: 11.01.2023 23:30:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




ALTER PROCEDURE [dbo].[X5_Web_AddTasks]
	@ReportType VARCHAR(50),
	@StartDate DATE = '2022-01-01',
	@FinishDate DATE = '2022-01-14',
	@isArchive BIT = 0,
	@isCheck BIT = 0,
	@salesChannel VARCHAR(50) = 'ALL',
	@MaxPeriod TINYINT = 7,
	@IncludeCheck BIT = 0,
	@CheckPeriod INT = 14
AS
BEGIN
	DECLARE @tbl_reportTypes AS TABLE (ReportType VARCHAR(50))
	DECLARE @tbl_reportDates AS TABLE (StartDate DATE, FinishDate DATE)
	
	
	
	DECLARE @ReportDuration     INT,
	        @MiddleDate         DATE,
	        @NumWholeInt        INT,
	        @RemainderDays      INT,
	        @I                  INT,
	        @TmpStartDate DATE
	
	
	
	
	IF @ReportType IN ('SALES', 'INVENTORY', 'MOVEMENT', 'SHOP_DIRECTORY_V2', 
	                  'PRODUCT_DIRECTORY_V2','DEMAND')
	    INSERT INTO @tbl_reportTypes
	    SELECT @ReportType
	ELSE
	IF @ReportType = 'ALL'
	BEGIN
	    INSERT INTO @tbl_reportTypes
	    VALUES
	      (
	        'SALES'
	      ), ('INVENTORY'), ('MOVEMENT'), ('DEMAND')
	    INSERT INTO ADF_X5_Tasks
	    VALUES
	      (
	        'SHOP_DIRECTORY_V2',
	        FORMAT(@FinishDate, 'yyyy-MM-ddT00:00:00.000Z'), -- 24.06.2022
	        FORMAT(@FinishDate, 'yyyy-MM-ddT00:00:00.000Z'),
	        @isArchive,
	        @isCheck,
	        @salesChannel,
	        GETDATE(),
	        0,
	        NULL,
	        NULL
	      ),
	    (
	        'PRODUCT_DIRECTORY_V2',
	        FORMAT(@FinishDate, 'yyyy-MM-ddT00:00:00.000Z'),
	        FORMAT(@FinishDate, 'yyyy-MM-ddT00:00:00.000Z'),
	        @isArchive,
	        @isCheck,
	        @salesChannel,
	        GETDATE(),
	        0,
	        NULL,
	        NULL
	    )
	END
	ELSE
	IF @ReportType = 'DATA'
	BEGIN
	    INSERT INTO @tbl_reportTypes
	    VALUES
	      (
	        'SALES'
	      ), ('INVENTORY'), ('MOVEMENT'), ('DEMAND')
	END
	ELSE
	BEGIN
	    PRINT 'Report type is unrecognized'
	    RETURN ;
	END
	
	
	
	SELECT @ReportDuration = DATEDIFF(dd, @StartDate, @FinishDate)
	SELECT @RemainderDays = @ReportDuration%@MaxPeriod
	SELECT @NumWholeInt = @ReportDuration / @MaxPeriod
	
	IF @ReportDuration <= @MaxPeriod
	BEGIN
	    INSERT INTO @tbl_reportDates
	    SELECT @StartDate,
	           @FinishDate
	END
	ELSE
	BEGIN
	    SET @I = 1
	    SET @TmpStartDate = @StartDate
	    WHILE @I <= @NumWholeInt
	    BEGIN
	        SET @MiddleDate = DATEADD(dd, @MaxPeriod, @TmpStartDate)
	 
	        INSERT INTO @tbl_reportDates
	        SELECT @TmpStartDate,
	               @MiddleDate
	        
	        SET @I = @I + 1
	     
	        SET @TmpStartDate = @MiddleDate
	    END
	    
	    IF @RemainderDays <> 0
	        INSERT INTO @tbl_reportDates
	        SELECT @TmpStartDate,
	               DATEADD(dd, @RemainderDays, @TmpStartDate)
	END
	
	
	
	
	--SELECT * FROM @tbl_reportTypes
	--SELECT * FROM @tbl_reportDates
	
	INSERT INTO ADF_X5_Tasks
	SELECT ReportType,
	       FORMAT(StartDate, 'yyyy-MM-ddT00:00:00.000Z'),
	       FORMAT(FinishDate, 'yyyy-MM-ddT00:00:00.000Z'),
	       @isArchive,
	       @isCheck,
	       @salesChannel,
	       GETDATE(),
	       0,
	       NULL,
	       NULL
	FROM   @tbl_reportTypes
	       CROSS JOIN @tbl_reportDates
	
	
	
	IF @IncludeCheck = 1
	BEGIN
	    INSERT INTO ADF_X5_Tasks
	    SELECT ReportType,
	           FORMAT(DATEADD(DAY, -14, StartDate), 'yyyy-MM-ddT00:00:00.000Z'),
	           FORMAT(FinishDate, 'yyyy-MM-ddT00:00:00.000Z'),
	           @isArchive,
	           1,
	           @salesChannel,
	           GETDATE(),
	           0,
	           NULL,
	           NULL
	    FROM   @tbl_reportTypes
	           CROSS JOIN @tbl_reportDates
	    WHERE  ReportType IN ('SALES', 'INVENTORY', 'MOVEMENT', 'DEMAND')
	END
END