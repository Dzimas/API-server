
--DROP USER AimAPIUser;

DROP INDEX IF EXISTS UserInd;
DROP INDEX IF EXISTS TagInd;
DROP INDEX IF EXISTS FolderInd;
DROP INDEX IF EXISTS TaskInd;

DROP TABLE IF EXISTS MapTag;
DROP TABLE IF EXISTS Requests;
DROP TABLE IF EXISTS RequestTypes;
DROP TABLE IF EXISTS Applications;
DROP TABLE IF EXISTS Sprint;
DROP TABLE IF EXISTS RANGE;
DROP TABLE IF EXISTS Tasks;
DROP TABLE IF EXISTS Folders;
DROP TABLE IF EXISTS Tags;
DROP TABLE IF EXISTS ServiceTypes;
DROP TABLE IF EXISTS UserAimAccount;
DROP TABLE IF EXISTS Status;
DROP TABLE IF EXISTS TaskTypes;
DROP TABLE IF EXISTS Languages;

--CREATE USER AimAPIUser WITH LOGIN PASSWORD 'AimAPIUser';

--contains list of universal statuses
CREATE TABLE Status (
    StatusID       SERIAL PRIMARY KEY,
    Name           varchar(40) NOT NULL,
    Description    varchar(200)
);
INSERT INTO Status (Name, Description)
VALUES
('active','Active'),
('completed','Task was successfully completed'),
('queued','Record is in the queue'),
('moved','Task was not done - moved'),
('cancelled','Task was cancelled as was not done'),
('deleted','User was deleted'),
('blocked','User or Application were blocked'),
('closed', 'Task was closed by user');

--language is saved in json format
CREATE TABLE Languages (
    LanguageID   SERIAL PRIMARY KEY,
    Name         varchar(100) UNIQUE NOT NULL, 
    Layout       json NOT NULL
);

--contains lists of user accounts with some additional info
CREATE TABLE UserAimAccount (
    UAAIID       SERIAL PRIMARY KEY,
    Login        varchar(100) NOT NULL, 
    FirstName    varchar(40),
    LastName     varchar(40),
    Email        varchar(40) NOT NULL,
    BirthDate    time,
    AutoFill     bit,
    Gender       bit,  
    UpdateDate   time,
    LastUpdate   time,
    SleepTime    time,
    WakeUp       time,
    TasksPerDay  smallint,
    RestDays     smallint,
    CreationDate time,
    StatusID     integer REFERENCES Status (StatusID) ON DELETE RESTRICT,
    LanguageID   integer REFERENCES Languages (LanguageID) ON DELETE RESTRICT,
    Settings     json,
    PassHash     varchar(500),
    Token        varchar(500),
    TokenLives   time
);

--information about task types
CREATE TABLE TaskTypes (
    TypeID         SERIAL PRIMARY KEY,
    Name           varchar(40) NOT NULL,
    Description    varchar(200)
);
INSERT INTO TaskTypes (Name, Description)
VALUES
('simple','simple'),
('repeatable','repeatable'),
('training','training');

--information about task types
CREATE TABLE ServiceTypes (
    STypeID         SERIAL PRIMARY KEY,
    Name           varchar(40) NOT NULL,
    Description    varchar(200)
);
INSERT INTO ServiceTypes (Name, Description)
VALUES
('site','site'),
('android','android'),
('ios','ios');

--Folders contains folder structure (level- position in tree(def=0))
CREATE TABLE Folders (
    FolderID     SERIAL PRIMARY KEY,
    UAAIID       bigint REFERENCES UserAimAccount (UAAIID) ON DELETE RESTRICT,
    Level        smallint,
    ParentID     bigint,
    Name         varchar(60) NOT NULL
);

--Tags per user
CREATE TABLE Tags (
    TagID        SERIAL PRIMARY KEY,
    UAAIID       bigint REFERENCES UserAimAccount (UAAIID) ON DELETE RESTRICT,
    UsedTimes    bigint,
    Name         varchar(60) NOT NULL,
    UNIQUE (Name, UAAIID)
);

--Tasks contains all tasks info (Tries - number tries to manage with task, Complexity - supressed (1-3), 
--Priority - position in backlog, Reminder - Remind if task was not done, Times - how many times repeat this task
CREATE TABLE Tasks (
    TaskID       SERIAL PRIMARY KEY,
    UAAIID       bigint REFERENCES UserAimAccount (UAAIID) ON DELETE RESTRICT,
    Summary      varchar(200) NOT NULL, 
    Description  varchar, 
    Attachment   varchar(500),
    NotificationTime time,
    Complexity   smallint,
    Priority     bigint,
    Reminder     bit,  
    TasksPerDay  smallint,
    TaskDays     smallint,
    Times        smallint,
    TimesDone    smallint,
    AddressedDate time,
    UpdateDate   time,
    CreationDate time,
    Tries        smallint,
    StatusID     integer REFERENCES Status (StatusID) ON DELETE RESTRICT,
    FolderID     integer REFERENCES Folders (FolderID) ON DELETE RESTRICT,   
    TypeID       integer REFERENCES TaskTypes (TypeID) ON DELETE RESTRICT,  
    IgnoreRest   bit
);

--contains information for 1 day (ChangesMade-one of tasks was changed),
CREATE TABLE Sprint (
    SprintID     SERIAL PRIMARY KEY,
    Day          date,
    UAAIID       bigint REFERENCES UserAimAccount (UAAIID) ON DELETE RESTRICT,
    TaskID       bigint REFERENCES Tasks (TaskID) ON DELETE RESTRICT,
    ChangesMade  bit, 
    StatusID     integer REFERENCES Status (StatusID) ON DELETE RESTRICT,
    UpdateDate   time,
    UNIQUE (TaskID, UAAIID)
);

--tag per task mapping
CREATE TABLE MapTag (
    MTID         SERIAL PRIMARY KEY,
    UAAIID       bigint REFERENCES UserAimAccount (UAAIID) ON DELETE RESTRICT,
    TaskID       bigint REFERENCES Tasks (TaskID) ON DELETE RESTRICT,
    TagID        integer REFERENCES Tags (TagID) ON DELETE RESTRICT,
    UNIQUE (TaskID, TagID, UAAIID)
);

--Time range for tasks
CREATE TABLE Range (
    RangeID      SERIAL PRIMARY KEY,
    FromTime     time,
    ToTime       time,
    TaskID       bigint REFERENCES Tasks (TaskID) ON DELETE RESTRICT,
    UNIQUE (TaskID)
);

--Applications
CREATE TABLE Applications (
    AppID        SERIAL PRIMARY KEY,
    Name         varchar(40) NOT NULL,
    Description  varchar(200),
    Private      bit,
    STypeID      integer REFERENCES ServiceTypes (STypeID) ON DELETE RESTRICT,
    StatusID     integer REFERENCES Status (StatusID) ON DELETE RESTRICT,
    UAAIID       bigint REFERENCES UserAimAccount (UAAIID) ON DELETE RESTRICT
);

--Request types
CREATE TABLE RequestTypes (
    RTypeID      SERIAL PRIMARY KEY,
    Name         varchar(40) NOT NULL,
    Template     varchar(200),
    StatusID     integer REFERENCES Status (StatusID) ON DELETE RESTRICT
);

--Requests
CREATE TABLE Requests (
    ReqID        SERIAL PRIMARY KEY,
    Name         varchar(40) NOT NULL,
    Description  varchar(200),
    RTypeID      integer REFERENCES RequestTypes (RTypeID) ON DELETE RESTRICT,
    StatusID     integer REFERENCES Status (StatusID) ON DELETE RESTRICT,
    AppID        bigint REFERENCES Applications (AppID) ON DELETE RESTRICT,
    UpdateDate   time,
    FrequencyMS  bigint NOT NULL
);

--Indexes
CREATE INDEX UserInd
ON UserAimAccount (Login, UAAIID);
CREATE INDEX TagInd
ON Tags (UAAIID, TagID);
CREATE INDEX FolderInd
ON Folders (UAAIID, FolderID);
CREATE INDEX TaskInd
ON Tasks (UAAIID, StatusID, TaskID);








