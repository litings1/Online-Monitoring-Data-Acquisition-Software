IF (SELECT OBJECT_ID('Air_1m_$YEAR$_$MON$_Src')) IS  NULL
                        CREATE TABLE Air_1m_$YEAR$_$MON$_Src (
                            Id             INT IDENTITY(1,1) NOT NULL,
                            StationCode     varchar(20)     NOT NULL,
                            TimePoint       datetime        NOT NULL,
                            PollutantCode   varchar(20)      NOT NULL,
                            MonValue        decimal(10,3)   NOT NULL,
                            Mark            varchar(255)    NOT NULL,
                            ConditionType   int   not null default(0),
constraint [pk_Air_1m_$YEAR$_$MON$_Src] primary key([Id])
                        ); 
IF (SELECT OBJECT_ID('Air_2m_$YEAR$_$MON$_Src')) IS  NULL
                        CREATE TABLE Air_2m_$YEAR$_$MON$_Src (
                            Id             INT IDENTITY(1,1) NOT NULL,
                            StationCode     varchar(20)     NOT NULL,
                            TimePoint       datetime        NOT NULL,
                            PollutantCode   varchar(20)      NOT NULL,
                            MonValue        decimal(10,3)   NOT NULL,
                            Mark            varchar(255)    NOT NULL,
                            ConditionType   int   not null default(0),
constraint [pk_Air_2m_$YEAR$_$MON$_Src] primary key([Id])
                        ); 
IF (SELECT OBJECT_ID('Air_10m_$YEAR$_$MON$_Src')) IS  NULL
                        CREATE TABLE Air_10m_$YEAR$_$MON$_Src (
                            Id             INT IDENTITY(1,1) NOT NULL,
                            StationCode     varchar(20)     NOT NULL,
                            TimePoint       datetime        NOT NULL,
                            PollutantCode   varchar(20)      NOT NULL,
                            MonValue        decimal(10,3)   NOT NULL,
                            Mark            varchar(255)    NOT NULL,
                            ConditionType   int   not null default(0),
constraint [pk_Air_10m_$YEAR$_$MON$_Src] primary key([Id])
                        );
IF (SELECT OBJECT_ID('Air_5m_$YEAR$_$MON$_Src')) IS  NULL
                        CREATE TABLE Air_5m_$YEAR$_$MON$_Src (
                            Id             INT IDENTITY(1,1) NOT NULL,
                            StationCode     varchar(20)     NOT NULL,
                            TimePoint       datetime        NOT NULL,
                            PollutantCode   varchar(20)      NOT NULL,
                            MonValue        decimal(10,3)   NOT NULL,
                            Mark            varchar(255)    NOT NULL,
                            ConditionType   int   not null default(0),
constraint [pk_Air_5m_$YEAR$_$MON$_Src] primary key([Id])                        
                        );
                        |
IF (SELECT OBJECT_ID('Air_30s_$YEAR$_Src')) IS  NULL
                        CREATE TABLE Air_30s_$YEAR$_Src (
                            Id             INT IDENTITY(1,1) NOT NULL,
                            StationCode     varchar(20)     NOT NULL,
                            TimePoint       datetime        NOT NULL,
                            PollutantCode   varchar(20)      NOT NULL,
                            MonValue        decimal(10,3)   NOT NULL,
                            Mark            varchar(255)    NOT NULL,
                            ConditionType   int   not null default(0),
constraint [pk_Air_30s_$YEAR$_Src] primary key([Id])           
                        );
IF (SELECT OBJECT_ID('Air_1h_$YEAR$_Src')) IS  NULL
                        CREATE TABLE Air_1h_$YEAR$_Src (
                            Id              INT      IDENTITY(1,1) NOT NULL,
                            StationCode     varchar(20)     NOT NULL,
                            TimePoint       datetime        NOT NULL,
                            PollutantCode   varchar(20)      NOT NULL,
                            MonValue        decimal(10,3)   NOT NULL,
                            Mark            varchar(255)    NOT NULL,
                            ConditionType   int   not null default(0),
constraint [pk_Air_1h_$YEAR$_Src] primary key([Id])        

                        );
IF (SELECT OBJECT_ID('Air_1d_aqi_$YEAR$_Src')) IS  NULL
                        CREATE TABLE Air_1d_aqi_$YEAR$_Src (
                            Id              INT    IDENTITY(1,1) NOT NULL,
                            StationCode     varchar(20)     NOT NULL,
                            TimePoint       datetime        NOT NULL,
                            PollutantCode   varchar(20)      NOT NULL,
                            MonValue        decimal(10,3)   NOT NULL,
                            Mark            varchar(255)    NOT NULL,
                            ConditionType   int   not null default(0),
constraint [pk_Air_1d_aqi_$YEAR$_Src] primary key([Id])        
                        );
IF (SELECT OBJECT_ID('Air_1d_api_$YEAR$_Src')) IS  NULL
                        CREATE TABLE Air_1d_api_$YEAR$_Src (
                            Id              INT     IDENTITY(1,1) NOT NULL,
                            StationCode     varchar(20)     NOT NULL,
                            TimePoint       datetime        NOT NULL,
                            PollutantCode   varchar(20)      NOT NULL,
                            MonValue        decimal(10,3)   NOT NULL,
                            Mark            varchar(255)    NOT NULL,
                            ConditionType   int   not null default(0),
constraint [pk_Air_1d_api_$YEAR$_Src] primary key([Id])        
                        );
IF (SELECT OBJECT_ID('Ins_1h_$YEAR$')) IS  NULL
                       CREATE TABLE Ins_1h_$YEAR$( 
                            Id        INT     IDENTITY(1,1) NOT NULL,
                            StationCode     varchar(20)     NOT NULL,
                            TimePoint       datetime        NOT NULL,
                            Brand           varchar(20)     NOT NULL,
                            Series          varchar(20)     NOT NULL,
                            StatusName      varchar(50)     NOT NULL,
                            PollutantCode   varchar(20)      NOT NULL,
                            Value           varchar(50)   NOT NULL,
                            Mark            varchar(255)    NOT NULL,
                            Units            varchar(20)    NULL,
constraint [pk_Ins_1h_$YEAR$] primary key([Id]));
IF (SELECT OBJECT_ID('Ins_Live_$YEAR$')) IS  NULL  
                            CREATE TABLE Ins_Live_$YEAR$( 
                            Id        INT     IDENTITY(1,1) NOT NULL,
                            StationCode     varchar(20)     NOT NULL,
                            TimePoint       datetime        NOT NULL,
                            Brand           varchar(20)     NOT NULL,
                            Series          varchar(20)     NOT NULL,
                            StatusName      varchar(50)     NOT NULL,
                            PollutantCode   varchar(20)      NOT NULL,
                            Value           varchar(50)   NOT NULL,
                            Mark            varchar(255)    NOT NULL,
                            Units            varchar(20)    NULL,
constraint [pk_Ins_Live_$YEAR$_Src] primary key([Id])  
);
                        |
IF (SELECT OBJECT_ID('QC_History')) IS  NULL
                        CREATE TABLE  QC_History
                        (
                        id INT IDENTITY(1,1) NOT NULL,
                        real_start_time datetime not null,  
                        start_time datetime not null,
                        end_time datetime not null,
                        mission_group_name varchar(100) not null,
                        mission_name varchar(100) not null,
                        result varchar(250) not null, 
                        send_field_split int null,
                        send_field text null,
                        source char(1) not null,  --1 是 定时 ；2 是 现场 ；3 是 网络  *****更改为 1 是 网络 ；2是 定时 3 是 现场******
                        document_name varchar(250) null,
                        record_time datetime not null,
constraint [pk_QC_History] primary key([Id])       
                        ); 
                        | 
IF (SELECT OBJECT_ID('Air_2m_$YEAR$_$MON$_Src')) IS  NULL
                        CREATE TABLE Air_2m_$YEAR$_$MON$_Src (
                            Id             INT IDENTITY(1,1) NOT NULL,
                            StationCode     varchar(20)     NOT NULL,
                            TimePoint       datetime        NOT NULL,
                            PollutantCode   varchar(20)      NOT NULL,
                            MonValue        decimal(10,3)   NOT NULL,
                            Mark            varchar(255)    NOT NULL,
                            ConditionType   int   not null default(0),
constraint [pk_Air_2m_$YEAR$_$MON$_Src] primary key([Id])
                        ); 
IF (SELECT OBJECT_ID('Air_10m_$YEAR$_$MON$_Src')) IS  NULL
                        CREATE TABLE Air_10m_$YEAR$_$MON$_Src (
                            Id             INT IDENTITY(1,1) NOT NULL,
                            StationCode     varchar(20)     NOT NULL,
                            TimePoint       datetime        NOT NULL,
                            PollutantCode   varchar(20)      NOT NULL,
                            MonValue        decimal(10,3)   NOT NULL,
                            Mark            varchar(255)    NOT NULL,
                            ConditionType   int   not null default(0),
constraint [pk_Air_10m_$YEAR$_$MON$_Src] primary key([Id])
                         ); 