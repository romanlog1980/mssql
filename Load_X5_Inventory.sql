USE [Retail]
GO
/****** Object:  StoredProcedure [dbo].[Load_X5_Inventory]    Script Date: 12.01.2023 9:47:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Load_X5_Inventory]
		@CloudStocks [dbo].[tt_X5_Inventory] READONLY
AS 
BEGIN
	MERGE X5_Inventory_Stage  AS trg
	       USING (
	           SELECT *
	           FROM   @CloudStocks
	       )               AS Src
	            ON  (
					trg.StockDate = src.StockDate 
				AND trg.X5_ShopId = src.X5_ShopId
				AND trg.X5_SkuId =	src.X5_SkuId
				)

	WHEN MATCHED THEN
	UPDATE 
	SET    trg.Amount = src.Amount,
	       trg.StockType = src.StockType

	WHEN NOT MATCHED BY TARGET THEN
	INSERT 
	  (
		StockDate,
		X5_ShopId,
		X5_SkuId,
		Amount,
		StockType
	)
	VALUES
	  (
		src.StockDate,
		src.X5_ShopId,
		src.X5_SkuId,
		src.Amount,
		src.StockType
	  );


END