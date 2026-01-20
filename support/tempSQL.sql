use AQMDB
go

if (select object_id('Air_Temp_Mark')) is null
begin
CREATE TABLE Air_Temp_Mark (
 
    Id            INT      IDENTITY(1,1) NOT NULL  ,

    PollutantCode VARCHAR( 5 ),
    Mark          VARCHAR( 255 ) ,

constraint[pk_Air_Temp_Mark] primary key([Id])

);

end
go

if (select object_id('Instrument_State_Record')) is null
begin
create table Instrument_State_Record(

Id INT IDENTITY(1,1) NOT NULL,

StartDateTime datetime,
EndDateTime datetime,
Instrument varchar(10),

State varchar(20),
Operator varchar(20),

constraint[pk_Instrument_State_Record] primary key([Id])
)

end
go

if (select object_id('QC_Arrange')) is null
begin
  create table QC_Arrange
(

id INT IDENTITY(1,1) NOT NULL,

start_time datetime not null,

mission_group_name varchar(100) not null,

mission_name varchar(100) not null,
state char(1) not null,    -- 1 �� �ȴ� ��2 �� ������

source char(1) not null,   --1 �� ���� ��2�� ��ʱ 

overtime int not null ,

constraint[pk_QC_Arrange] primary key([id])
);
end
go


if (select object_id('QC_History')) is null
begin
create table QC_History
(

id INT IDENTITY(1,1) NOT NULL,

real_start_time datetime not null,
  
start_time datetime not null,

end_time datetime not null,

mission_group_name varchar(100) not null,

mission_name varchar(100) not null,
result  tinyint not null,
 
send_field_split int null,

send_field text null,
source char(1) not null,  --1 �� ��ʱ ��2 �� �ֳ� ��3 �� ����  *****����Ϊ 1 �� ���� ��2�� ��ʱ 3 �� �ֳ� 4�� �ֶ�******

document_name varchar(100) null,

constraint[pk_QC_History] primary key([id])
);
end
go


if (select object_id('QC_State_Record')) is null
begin
create table QC_State_Record(

Id INT IDENTITY(1,1) NOT NULL,

StartDateTime datetime,

EndDateTime datetime,
QCObject varchar(10),

QCType varchar(20),
Result tinyint,

Operator varchar(20),

constraint [pk_QC_State_Record] primary key([Id])
);
end
go


if (select object_id('ResendCommand_History')) is null
begin
CREATE TABLE ResendCommand_History (
 
    Id            INT         IDENTITY(1,1) NOT NULL,

    StartDateTime DATETIME        NOT NULL,

    EndDateTime   DATETIME        NOT NULL,

    ReceiveIP     VARCHAR( 15 )   NOT NULL,

    FailTick      INT         ,

    SendTime      DATETIME,

    IsSuccess     INT         NOT NULL,

    Type          VARCHAR( 5 )    NOT NULL,

    PollutantCode VARCHAR( 5 )    NOT NULL,
    Detail        VARCHAR( 100 ) ,

constraint [pk_ResendCommand_History] primary key([Id])
);
end
go



if (select object_id('ResendCommand_Waiting')) is null
begin
CREATE TABLE ResendCommand_Waiting (
 
    Id            INT    IDENTITY(1,1) NOT NULL,

    StartDateTime DATETIME        NOT NULL,

    EndDateTime   DATETIME        NOT NULL,

    ReceiveIP     VARCHAR( 15 )   NOT NULL,

    FailTick      INT       ,

    Type          VARCHAR( 5 )    NOT NULL,

    PollutantCode VARCHAR( 5 )    NOT NULL,

    Detail        VARCHAR( 100 ) ,

constraint [pk_ResendCommand_Waiting] primary key([Id])
);
end
go


if (select object_id('ManualQCEvent')) is null
begin
    CREATE TABLE ManualQCEvent (
 
    Id            INT       IDENTITY(1,1) NOT NULL,

    PollutantCode VARCHAR( 5 )    NOT NULL,

    StartTime     DATETIME        NOT NULL,

    EndTime       DATETIME        NOT NULL,

    EditeTime     DATETIME        NOT NULL,

    Operator      VARCHAR( 50 )   NOT NULL,

    Remark        VARCHAR( 100 )  NULL ,

	Task          VARCHAR( 50  )  NULL ,

constraint [pk_ManuanlQCEvent] primary key([Id])
);
end
go



--���ݴ洢�����Ҫ�滻��Ӧ������


                        
if (select object_id('Air_1m_2014_5_Src')) is null
begin
CREATE TABLE Air_1m_2014_5_Src (

                            Id             INT IDENTITY(1,1) NOT NULL,

                            StationCode     varchar(20)     NOT NULL,

                            TimePoint       datetime        NOT NULL,

                            PollutantCode   varchar(5)      NOT NULL,

                            MonValue        decimal(10,3)   NOT NULL,

                            Mark            varchar(255)    NOT NULL,

constraint [pk_Air_1m_2014_5_Src] primary key([Id]));

end
go

if (select object_id('Air_5m_2014_5_Src')) is null
begin                        
CREATE TABLE Air_5m_2014_5_Src (

                            Id             INT IDENTITY(1,1) NOT NULL,

                            StationCode     varchar(20)     NOT NULL,

                            TimePoint       datetime        NOT NULL,

                            PollutantCode   varchar(5)      NOT NULL,

                            MonValue        decimal(10,3)   NOT NULL,

                            Mark            varchar(255)    NOT NULL,

constraint [pk_Air_5m_2014_5_Src] primary key([Id]));
end
go


if (select object_id('Air_30s_2014_Src')) is null
begin						
                        
CREATE TABLE Air_30s_2014_Src (

                            Id             INT IDENTITY(1,1) NOT NULL,

                            StationCode     varchar(20)     NOT NULL,

                            TimePoint       datetime        NOT NULL,

                            PollutantCode   varchar(5)      NOT NULL,

                            MonValue        decimal(10,3)   NOT NULL,

                            Mark            varchar(255)    NOT NULL,

constraint [pk_Air_30s_2014_Src] primary key([Id]));

  
end
go                      

if (select object_id('Air_1h_2014_Src')) is null
begin
CREATE TABLE Air_1h_2014_Src (

                            Id              INT      IDENTITY(1,1) NOT NULL,

                            StationCode     varchar(20)     NOT NULL,

                            TimePoint       datetime        NOT NULL,

                            PollutantCode   varchar(5)      NOT NULL,

                            MonValue        decimal(10,3)   NOT NULL,

                            Mark            varchar(255)    NOT NULL,

constraint [pk_Air_1h_2014_Src] primary key([Id]));

 
end
go

if (select object_id('Air_1d_aqi_2014_Src')) is null
begin                       
CREATE TABLE Air_1d_aqi_2014_Src (

                            Id              INT    IDENTITY(1,1) NOT NULL,

                            StationCode     varchar(20)     NOT NULL,

                            TimePoint       datetime        NOT NULL,

                            PollutantCode   varchar(5)      NOT NULL,

                            MonValue        decimal(10,3)   NOT NULL,

                            Mark            varchar(255)    NOT NULL,

constraint [pk_Air_1d_aqi_2014_Src] primary key([Id]));
end
go


if (select object_id('Air_1d_api_2014_Src')) is null
begin
                        
CREATE TABLE Air_1d_api_2014_Src (

                            Id              INT     IDENTITY(1,1) NOT NULL,

                            StationCode     varchar(20)     NOT NULL,

                            TimePoint       datetime        NOT NULL,

                            PollutantCode   varchar(5)      NOT NULL,

                            MonValue        decimal(10,3)   NOT NULL,

                            Mark            varchar(255)    NOT NULL,

constraint [pk_Air_1d_api_2014_Src] primary key([Id]));

end
go						
                        