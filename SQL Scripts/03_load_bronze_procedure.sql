CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN

	DECLARE @start_time DATETIME, @end_time DATETIME;
	BEGIN TRY

		PRINT '--------------------------------------------------';
		PRINT 'Loading Bronze Layer';
		PRINT '--------------------------------------------------';

		
		-- 1. INTERACTIONS TABLE
		PRINT '--------------------------------------------------';
		PRINT 'Loading Interaction Table Columns';
		PRINT '--------------------------------------------------';

		SET @start_time = GETDATE( );
		PRINT '>> Truncating Table: Bronze.interaction_info';
		TRUNCATE TABLE Bronze.interaction_info;

		PRINT '>> Inserting Data Into: Bronze.interaction_info';
		BULK INSERT Bronze.interaction_info
		FROM "D:\SQL, Power BI & Kobo Toolbox\SQL & Power BI Portfolio\raw_data\interactions.csv"
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\n',
			TABLOCK
		);
		SET @end_time = GETDATE( );
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';


		-- 2. PRODUCTS TABLE
		PRINT '--------------------------------------------------';
		PRINT 'Loading Product Table Columns';
		PRINT '--------------------------------------------------';

		SET @start_time = GETDATE( );
		PRINT '>> Truncating Table: Bronze.product_info';
		TRUNCATE TABLE Bronze.product_info;

		PRINT '>> Inserting Data Into: Bronze.product_info';
		BULK INSERT Bronze.product_info
		FROM "D:\SQL, Power BI & Kobo Toolbox\SQL & Power BI Portfolio\raw_data\products.csv"
		WITH (
			FORMAT = 'CSV',
			FIRSTROW = 2,
			FIELDQUOTE = '"',
			ROWTERMINATOR = '\n',
			TABLOCK
		);
		SET @end_time = GETDATE( );
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';


		-- 3. PURCHASES TABLE
		PRINT '--------------------------------------------------';
		PRINT 'Loading Purchase Table Columns';
		PRINT '--------------------------------------------------';

		SET @start_time = GETDATE( );
		PRINT '>> Truncating Table: Bronze.purchase_info';
		TRUNCATE TABLE Bronze.purchase_info;
	
		PRINT '>> Inserting Data Into: Bronze.purchase_info';
		BULK INSERT Bronze.purchase_info
		FROM "D:\SQL, Power BI & Kobo Toolbox\SQL & Power BI Portfolio\raw_data\purchases.csv"
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\n',
			TABLOCK
		);
		SET @end_time = GETDATE( );
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';


		-- 4. REVIEWS TABLE
		PRINT '--------------------------------------------------';
		PRINT 'Loading Review Table Columns';
		PRINT '--------------------------------------------------';

		SET @start_time = GETDATE( );
		PRINT '>> Truncating Table: Bronze.review_info';
		TRUNCATE TABLE Bronze.review_info;
	
		PRINT '>> Inserting Data Into: Bronze.review_info';
		BULK INSERT Bronze.review_info
		FROM "D:\SQL, Power BI & Kobo Toolbox\SQL & Power BI Portfolio\raw_data\reviews.csv"
		WITH (
			FORMAT = 'CSV',
			FIRSTROW = 2,
			FIELDQUOTE = '"',
			ROWTERMINATOR = '\n',
			TABLOCK
		);
		SET @end_time = GETDATE( );
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

		
		-- 5. SESSIONS TABLE
		PRINT '--------------------------------------------------';
		PRINT 'Loading Session Table Columns';
		PRINT '--------------------------------------------------';

		SET @start_time = GETDATE( );
		PRINT '>> Truncating Table: Bronze.session_info';
		TRUNCATE TABLE Bronze.session_info;
	
		PRINT '>> Inserting Data Into: Bronze.session_info';
		BULK INSERT Bronze.session_info
		FROM "D:\SQL, Power BI & Kobo Toolbox\SQL & Power BI Portfolio\raw_data\sessions.csv"
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\n',
			TABLOCK
		);
		SET @end_time = GETDATE( );
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';


		-- 6. USERS TABLE
		PRINT '--------------------------------------------------';
		PRINT 'Loading User Table Columns';
		PRINT '--------------------------------------------------';

		SET @start_time = GETDATE( );
		PRINT '>> Truncating Table: Bronze.user_info';
		TRUNCATE TABLE Bronze.user_info;
	
		PRINT '>> Inserting Data Into: Bronze.user_info';
		BULK INSERT Bronze.user_info
		FROM "D:\SQL, Power BI & Kobo Toolbox\SQL & Power BI Portfolio\raw_data\users.csv"
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '\n',
			TABLOCK
		);
		SET @end_time = GETDATE( );
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

	END TRY

	BEGIN CATCH
		PRINT '--------------------------------------------------';
		PRINT 'ERROR OCCURRED DURING LOADING BRONZE LAYER';
		PRINT 'Error Message: ' + ERROR_MESSAGE( );
		PRINT 'Error Message: ' + CAST (ERROR_NUMBER( ) AS NVARCHAR (10));
		PRINT 'Error Message: ' + CAST (ERROR_STATE( ) AS NVARCHAR(10));
		PRINT '--------------------------------------------------';
	END CATCH

END


-- Execute the procedure to load everything
EXEC bronze.load_bronze;