/************************************************************
 * Code formatted by SoftTree SQL Assistant © v5.1.40
 * Time: 3/27/2011 8:54:04 AM
 ************************************************************/

DECLARE @Debug               BIT,
        @PartnerServer       SYSNAME,
        @MaxID               INT,
        @CurrID              INT,
        @SQL                 NVARCHAR(MAX),
        @LoginName           SYSNAME,
        @IsDisabled          INT,
        @Type                CHAR(1),
        @SID                 VARBINARY(85),
        @SIDString           NVARCHAR(100),
        @PasswordHash        VARBINARY(256),
        @PasswordHashString  NVARCHAR(300),
        @RoleName            SYSNAME,
        @Machine             SYSNAME,
        @PermState           NVARCHAR(60),
        @PermName            SYSNAME,
        @Class               TINYINT,
        @MajorID             INT,
        @ErrNumber           INT,
        @ErrSeverity         INT,
        @ErrState            INT,
        @ErrProcedure        SYSNAME,
        @ErrLine             INT,
        @ErrMsg              NVARCHAR(2048)

DECLARE @Logins              TABLE (
            LoginID INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
            [Name] SYSNAME NOT NULL,
            [SID] VARBINARY(85) NOT NULL,
            IsDisabled INT NOT NULL,
            [Type] CHAR(1) NOT NULL,
            PasswordHash VARBINARY(256) NULL
        )

DECLARE @Roles               TABLE (
            RoleID INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
            RoleName SYSNAME NOT NULL,
            LoginName SYSNAME NOT NULL
        )

DECLARE @Perms               TABLE (
            PermID INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
            LoginName SYSNAME NOT NULL,
            PermState NVARCHAR(60) NOT NULL,
            PermName SYSNAME NOT NULL,
            Class TINYINT NOT NULL,
            ClassDesc NVARCHAR(60) NOT NULL,
            MajorID INT NOT NULL,
            SubLoginName SYSNAME NULL,
            SubEndPointName SYSNAME NULL
        )

SET NOCOUNT ON;

SET @PartnerServer = 'UASIT-SD02'

IF CHARINDEX('\', @PartnerServer) > 0
BEGIN
    SET @Machine = LEFT(@PartnerServer, CHARINDEX('\', @PartnerServer) - 1);
END
ELSE
BEGIN
    SET @Machine = @PartnerServer;
END
PRINT @Machine



INSERT INTO @Logins
  (
    NAME,
    SID,
    IsDisabled,
    TYPE,
    PasswordHash
  )
SELECT P.name,
       P.sid,
       P.is_disabled,
       P.type,
       L.password_hash
FROM   MASTER.sys.server_principals P
       LEFT JOIN MASTER.sys.sql_logins L
            ON  L.principal_id = P.principal_id
WHERE  P.type IN ('U', 'G', 'S')
       AND P.name <> 'sa'
       AND P.name NOT LIKE '##%' 
     AND CHARINDEX('UASIT-SD02' + '\', P.name) = 0;

SELECT * FROM @Logins l



-- Get all roles from principal server

INSERT INTO @Roles
  (
    RoleName,
    LoginName
  )
SELECT RoleP.name,
       LoginP.name
FROM   MASTER.sys.server_role_members RM
       INNER JOIN MASTER.sys.server_principals RoleP
            ON  RoleP.principal_id = RM.role_principal_id
       INNER JOIN MASTER.sys.server_principals LoginP
            ON  LoginP.principal_id = RM.member_principal_id
WHERE  LoginP.type IN ('U', 'G', 'S')
       AND LoginP.name <> 'sa' 
       AND LoginP.name NOT LIKE '##%' 
       AND RoleP.type = 'R' 
      AND CHARINDEX(@Machine, LoginP.name) = 0;



-- Get all explicitly granted permissions

INSERT INTO @Perms
  (
    LoginName,
    PermState,
    PermName,
    Class,
    ClassDesc,
    MajorID,
    SubLoginName,
    SubEndPointName
  )
SELECT P.name COLLATE database_default,
       SP.state_desc,
       SP.permission_name,
       SP.class,
       SP.class_desc,
       SP.major_id,
       SubP.name COLLATE database_default,
       SubEP.name COLLATE database_default
FROM   MASTER.sys.server_principals P
       INNER JOIN MASTER.sys.server_permissions SP
            ON  SP.grantee_principal_id = P.principal_id
       LEFT JOIN MASTER.sys.server_principals SubP
            ON  SubP.principal_id = SP.major_id
            AND SP.class = 101
       LEFT JOIN MASTER.sys.endpoints SubEP
            ON  SubEP.endpoint_id = SP.major_id
            AND SP.class = 105
WHERE  P.type IN ('U', 'G', 'S')
       AND P.name <> 'sa'
       AND P.name NOT LIKE '##%'
       AND CHARINDEX(@Machine + '\', P.name) = 0;

SELECT @MaxID = MAX(LoginID),
       @CurrID = 1
FROM   @Logins;

WHILE @CurrID <= @MaxID
BEGIN
    SELECT @LoginName = NAME,
           @IsDisabled = IsDisabled,
           @Type = [Type],
           @SID = [SID],
           @PasswordHash = PasswordHash
    FROM   @Logins
    WHERE  LoginID = @CurrID;
    
    SET @SQL = 'Create Login ' + QUOTENAME(@LoginName)
    IF @Type IN ('U', 'G')
    BEGIN
        SET @SQL = @SQL + ' From Windows;'
    END
    ELSE
    BEGIN
        SET @PasswordHashString = '0x' +
            CAST('' AS XML).value(
                'xs:hexBinary(sql:variable("@PasswordHash"))',
                'nvarchar(300)'
            );
        
        SET @SQL = @SQL + ' With Password = ' + @PasswordHashString +
            ' HASHED, ';
        
        SET @SIDString = '0x' +
            CAST('' AS XML).value('xs:hexBinary(sql:variable("@SID"))', 'nvarchar(100)');
        SET @SQL = @SQL + 'SID = ' + @SIDString + ';';
        
        
        
        IF @IsDisabled = 1
        BEGIN
            SET @SQL = 'Alter Login ' + QUOTENAME(@LoginName) + ' Disable;'
            IF @Debug = 0
            BEGIN
                BEGIN TRY
                	PRINT @SQL;
                END TRY
                BEGIN CATCH
                	SET @ErrNumber = ERROR_NUMBER();
                	SET @ErrSeverity = ERROR_SEVERITY();
                	SET @ErrState = ERROR_STATE();
                	SET @ErrProcedure = ERROR_PROCEDURE();
                	SET @ErrLine = ERROR_LINE();
                	SET @ErrMsg = ERROR_MESSAGE();
                	RAISERROR(@ErrMsg, 1, 1);
                END CATCH
            END
            ELSE
            BEGIN
                PRINT @SQL;
            END
        END
    END
    PRINT @SQL
    
    SET @CurrID = @CurrID + 1;
END

SELECT @MaxID = MAX(RoleID),
       @CurrID = 1
FROM   @Roles;

WHILE @CurrID <= @MaxID
BEGIN
    SELECT @LoginName = LoginName,
           @RoleName = RoleName
    FROM   @Roles
    WHERE  RoleID = @CurrID;
    
    PRINT 'Exec sp_addsrvrolemember @rolename = ''' + @RoleName + ''',';
    PRINT '		@loginame = ''' + @LoginName + ''';';
    
    SET @CurrID = @CurrID + 1;
END

SELECT @MaxID = MAX(PermID),
       @CurrID = 1
FROM   @Perms;

WHILE @CurrID <= @MaxID
BEGIN
    SELECT @PermState = PermState,
           @PermName = PermName,
           @Class = Class,
           @LoginName = LoginName,
           @MajorID = MajorID,
           @SQL = PermState + SPACE(1) + PermName + SPACE(1) +
           CASE Class
                WHEN 101 THEN 'On Login::' + QUOTENAME(SubLoginName)
                WHEN 105 THEN 'On ' + ClassDesc + '::' + QUOTENAME(SubEndPointName)
                ELSE ''
           END +
           ' To ' + QUOTENAME(LoginName) + ';'
    FROM   @Perms
    WHERE  PermID = @CurrID;
    
    PRINT @SQL;
    
    SET @CurrID = @CurrID + 1;
END

SET NOCOUNT OFF;
