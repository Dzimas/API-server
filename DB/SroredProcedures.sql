-- get list of supported languafes
CREATE OR REPLACE FUNCTION GetLanguagesList() 
RETURNS TABLE (lan_name varchar) AS $$
BEGIN
	RETURN QUERY SELECT name FROM Languages;
END; $$
LANGUAGE PLPGSQL;

-- get info for language
CREATE OR REPLACE FUNCTION GetLanguage(Language varchar(100)) 
RETURNS TABLE(lan_layout json) AS $$
BEGIN
	RETURN QUERY SELECT layout FROM Languages where name=Language;
END; $$
LANGUAGE PLPGSQL;

-- Set user login data - used for first user adding and updating login\pass data
CREATE OR REPLACE FUNCTION SetLoginData(
    par_Login        varchar(100),
    par_LastChangeTimeUTC timestamp,
    par_Status             varchar(40) DEFAULT NULL,
    par_Email        varchar(40) DEFAULT NULL,
    par_PassHash     varchar(500) DEFAULT NULL,
    par_Token        varchar(500) DEFAULT NULL,
    par_TokenLives   timestamp DEFAULT NULL) 
RETURNS varchar(40) AS $$
DECLARE 
	Stat integer;
	id bigint;
	prev_change timestamp;
	prev_Email        varchar(40);
	prev_PassHash     varchar(500);
	prev_Token        varchar(500);
	prev_TokenLives   timestamp;
	Changed        varchar(40);
BEGIN
	set time zone utc;
	
	SELECT UAAIID,  LastChangeTimeUTC, Email, PassHash, Token, TokenLives, StatusID
	INTO id, prev_change, prev_Email, prev_PassHash, prev_Token, prev_TokenLives, Stat 
	FROM UserAimAccount WHERE Login=par_Login;
	
	IF (id ISNULL) THEN
		INSERT INTO UserAimAccount (Login, StatusID, Email, PassHash, Token, TokenLives, LastChangeTimeUTC, UpdateDate, LastLogin, CreationDate)
		Values
		(par_Login, (SELECT StatusID FROM Status WHERE name=par_Status), par_Email, par_PassHash, par_Token, par_TokenLives, par_LastChangeTimeUTC, current_timestamp, current_timestamp, current_timestamp)
		RETURNING UAAIID INTO id;
		RETURN 'new:' || ID;
	ELSIF (prev_change < par_LastChangeTimeUTC) THEN
		UPDATE UserAimAccount 
		SET Email = (SELECT CASE WHEN par_Email ISNULL THEN prev_Email ELSE par_Email END),  
		PassHash = (SELECT CASE WHEN par_PassHash ISNULL THEN prev_PassHash ELSE par_PassHash END),  
		Token = (SELECT CASE WHEN par_Token ISNULL THEN prev_Token ELSE par_Token END),  
		TokenLives = (SELECT CASE WHEN par_TokenLives ISNULL THEN prev_TokenLives ELSE par_TokenLives END),
		StatusID = (SELECT CASE WHEN par_Status ISNULL THEN Stat ELSE (SELECT StatusID FROM Status WHERE name=par_Status) END),
		LastChangeTimeUTC = par_LastChangeTimeUTC,
		UpdateDate = current_timestamp,
		LastLogin = current_timestamp
		WHERE Login=par_Login;
		RETURN 'was updated';
	END IF;
	RETURN 'has not changed';
END; $$
LANGUAGE PLPGSQL;

-- Get user login data
CREATE OR REPLACE FUNCTION GetLoginData(
    par_Login        varchar(100))
RETURNS TABLE(ID   bigint,
    r_Email          varchar(40),
    r_LastLogin    timestamp,
    r_PassHash     varchar(500),
    r_Token        varchar(500),
    r_TokenLives   timestamp,
    r_CreationDate timestamp,
    r_name         varchar(40)) AS $$
BEGIN
	RETURN QUERY SELECT a.UAAIID, a.Email, a.LastLogin, a.PassHash, a.Token, a.TokenLives, a.CreationDate, s.Name FROM UserAimAccount a
	INNER JOIN  Status s
	ON a.StatusID=s.StatusID
	WHERE a.Login=par_Login;
END; $$
LANGUAGE PLPGSQL;

-- Set user accoutn data
CREATE OR REPLACE FUNCTION SetAccauntData(
    par_Login        varchar(100),
    par_LastChangeTimeUTC timestamp,
    par_FirstName    varchar(40) DEFAULT NULL,
    par_LastName     varchar(40) DEFAULT NULL,
    par_BirthDate    timestamp DEFAULT NULL,
    par_AutoFill     boolean DEFAULT true,
    par_Gender       boolean DEFAULT NULL,  
    par_SleepTime    timestamp DEFAULT NULL,
    par_WakeUp       timestamp DEFAULT NULL,
    par_TasksPerDay  smallint DEFAULT 5,
    par_RestDays     smallint DEFAULT 0,
    par_LanguageID   integer DEFAULT NULL,
    par_Settings     json DEFAULT NULL) 
RETURNS varchar(40) AS $$
DECLARE 
	id bigint;
	prev_change timestamp;
	prev_FirstName    varchar(40);
	prev_LastName     varchar(40);
	prev_BirthDate    timestamp;
	prev_AutoFill     boolean;
	prev_Gender       boolean; 
	prev_SleepTime    timestamp;
	prev_WakeUp       timestamp;
	prev_TasksPerDay  smallint;
	prev_RestDays     smallint;
	prev_LanguageID   integer;
	prev_Settings     json;
BEGIN
	set time zone utc;
	
	SELECT  UAAIID,  
		LastChangeTimeUTC, 
		FirstName ,
		LastName ,
		BirthDate ,
		AutoFill ,
		Gender ,  
		SleepTime  ,
		WakeUp  ,
		TasksPerDay  ,
		RestDays  ,
		LanguageID ,
		Settings
	INTO    id, 
		prev_change, 
		prev_FirstName ,
		prev_LastName ,
		prev_BirthDate ,
		prev_AutoFill ,
		prev_Gender ,  
		prev_SleepTime  ,
		prev_WakeUp  ,
		prev_TasksPerDay  ,
		prev_RestDays  ,
		prev_LanguageID ,
		prev_Settings
	FROM UserAimAccount WHERE Login=par_Login;
	IF (id ISNULL) THEN
		RETURN 'there is no such account';
	ELSIF (prev_change < par_LastChangeTimeUTC) THEN
		UPDATE UserAimAccount 
		SET 
			FirstName = par_FirstName,
			LastName = par_LastName,
			BirthDate = par_BirthDate,
			AutoFill = par_AutoFill,
			Gender = par_Gender,  
			SleepTime  = par_SleepTime,
			WakeUp = par_WakeUp,
			TasksPerDay = par_TasksPerDay,
			RestDays = par_RestDays,
			LanguageID = par_LanguageID,
			Settings = (SELECT CASE WHEN par_Settings ISNULL THEN prev_Settings ELSE par_Settings END),
			LastChangeTimeUTC = par_LastChangeTimeUTC,
			UpdateDate = current_timestamp
		WHERE Login=par_Login;
		
		RETURN 'was updated';
	END IF;
	RETURN 'has not changed';
END; $$
LANGUAGE PLPGSQL;

-- Get user accoutn data
CREATE OR REPLACE FUNCTION GetAccauntData(
    par_Login        varchar(100))
RETURNS TABLE(ID   bigint,
    r_FirstName    varchar(40),
    r_LastName     varchar(40),
    r_BirthDate    timestamp,
    r_AutoFill     boolean,
    r_Gender       boolean,  
    r_SleepTime    timestamp,
    r_WakeUp       timestamp,
    r_TasksPerDay  smallint,
    r_RestDays     smallint,
    r_Settings     json,
    r_Language     varchar(100)) AS $$
BEGIN
	RETURN QUERY SELECT  a.UAAIID,  
		a.FirstName ,
		a.LastName ,
		a.BirthDate ,
		a.AutoFill ,
		a.Gender ,  
		a.SleepTime  ,
		a.WakeUp  ,
		a.TasksPerDay  ,
		a.RestDays  ,
		a.Settings,
		l.name
	FROM UserAimAccount a
	LEFT JOIN  Languages l
	ON a.LanguageID = l.LanguageID
	WHERE Login = par_Login;
END; $$
LANGUAGE PLPGSQL;

-- Get user logins - used for user account creation
CREATE OR REPLACE FUNCTION GetLogins(
    par_LoginTemplate varchar(100) DEFAULT NULL)
RETURNS TABLE(r_Logins varchar(100)) AS $$
DECLARE TempString    varchar(101);
BEGIN
	IF (par_LoginTemplate != '') OR ((par_LoginTemplate IS NOT NULL)) THEN
		TempString := par_LoginTemplate || '%';
		RETURN QUERY SELECT  DISTINCT ON (Login) Login as Logins FROM UserAimAccount WHERE Login LIKE TempString;
	ELSE
		RETURN QUERY SELECT  DISTINCT ON (Login) Login as Logins FROM UserAimAccount;
	END IF;
END; $$
LANGUAGE PLPGSQL;

-- Set filder for user
CREATE OR REPLACE FUNCTION SetFolder(
    par_Login        varchar(100),
    FolderName       varchar(60),
    ParentFolderiD   integer DEFAULT NULL,
    id               integer DEFAULT NULL) 
RETURNS varchar(40) AS $$
DECLARE 
	newfolderid integer;
	i        integer; 
	userid   bigint;
	FolderLevel smallint;
	ParentFolderLevel smallint;
BEGIN
	IF (FolderName='') AND (id ISNULL) THEN
		RETURN 'folder must have name';
	END IF;
	
	SELECT  UAAIID INTO userid FROM UserAimAccount WHERE Login=par_Login;
	
	IF (userid ISNULL) THEN
		RETURN 'there is no such account';
	END IF;
	
	IF (ParentFolderiD IS NOT NULL) THEN
		SELECT FolderID, level INTO ParentFolderiD, ParentFolderLevel FROM Folders WHERE UAAIID=userid AND FolderID=ParentFolderiD;
		IF (ParentFolderiD ISNULL) THEN
			RETURN 'there is no such folder';
		END IF;
		FolderLevel:=ParentFolderLevel + 1;
	ELSE
		FolderLevel:=0;
	END IF;	
	
	IF ((SELECT FolderID FROM Folders WHERE UAAIID=userid AND Name=FolderName AND level=FolderLevel) IS NOT NULL) THEN
		RETURN 'such folder already exists';
	END IF;

	IF (id IS NOT NULL) THEN
		UPDATE Folders 
		SET 
			Name=FolderName,
			ParentID=ParentFolderiD,
			Level=FolderLevel
		WHERE UAAIID=userid AND FolderID=id;
		RETURN 'folder was updated';
	END IF;

	INSERT INTO Folders (Name, ParentID, Level, UAAIID)
	Values
	(FolderName, ParentFolderiD, FolderLevel, userid)
	RETURNING FolderID INTO id;

	RETURN 'new folderid:' || id;
END; $$
LANGUAGE PLPGSQL;

select GetLanguagesList();
select GetLanguage('en');
select SetLoginData('adimas233357','1999-01-08 07:05:29','active','email');
select GetLoginData('adimas233357');
select SetAccauntData('dimas23335','1999-01-08 07:05:32');
--	RAISE NOTICE 'Calling cs_create_job(%)', id;
select GetAccauntData('dimas23335')
select GetLogins ('d')
SELECT SetFolder ('dimas23335', 'HUINIA10',2)




