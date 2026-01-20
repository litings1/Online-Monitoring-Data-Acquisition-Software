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



if (select object_id('QC_Arrange')) is null
begin
  create table QC_Arrange
(

id INT IDENTITY(1,1) NOT NULL,

start_time datetime not null,

mission_group_name varchar(100) not null,

mission_name varchar(100) not null,

state char(1) not null,    -- 1 是 等待 ；2 是 运行中

source char(1) not null,   --1 是 网络 ；2是 定时 

overtime int not null ,

record_time datetime not null,
constraint[pk_QC_Arrange] primary key([id])
);
end
go

if (select object_id('QC_OverTime')) is null
begin
  create table QC_OverTime(

id INT IDENTITY(1,1) NOT NULL,

start_time datetime not null,

mission_group_name varchar(100) not null,

mission_name varchar(100) not null,

record_time datetime not null,
source char(1) not null,   --1 是 网络 ；2是 定时 

overtime int not null ,

constraint[pk_QC_OverTime] primary key([id])
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

source char(1) not null,  --1 是 定时 ；2 是 现场 ；3 是 网络  *****更改为 1 是 网络 ；2是 定时 3 是 现场 4是 手动******

document_name varchar(100) null,

record_time datetime not null,
constraint[pk_QC_History] primary key([id])
);
end
go


--if (select object_id('QC_State_Record')) is null
--begin
--create table QC_State_Record(

--Id INT IDENTITY(1,1) NOT NULL,

--StartDateTime datetime,

--EndDateTime datetime,
--QCObject varchar(10),

--QCType varchar(20),
--Result tinyint,

--Operator varchar(20),

--constraint [pk_QC_State_Record] primary key([Id])
--);
--end
--go


if(select object_id('ResendCommand')) is null
begin
CREATE TABLE ResendCommand( 
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[StartTime] [datetime] NOT NULL,
	[EndTime] [datetime] NOT NULL,
	[MaxID] [int] NOT NULL,
	[ReceiveIP] [varchar](30) NOT NULL,--请求来源ip:port
	[SourcePlatform] [tinyint] NOT NULL,--平台，使用QCSource枚举
	[FailTick] [tinyint] NOT NULL,--失败次数
	[SendTime] [datetime]  NULL,--最后一次更新时间
	[State] [tinyint] NOT NULL,--是否已经成功发送，使用CommandState枚举
	[Type] [varchar](4) NOT NULL,--数据类型代码，ResendCommandTool的Convert2Type方法。
	[PollutantCode] [varchar](5) NOT NULL,--监测污染物
	[RecordTime] [datetime] NOT NULL,--记录时间
PRIMARY KEY CLUSTERED 
(
	[StartTime] ASC,
	[EndTime] ASC,
	[ReceiveIP] ASC,
	[Type] ASC,
	[PollutantCode] ASC,
	[RecordTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY];
end
go

if(select object_id('InsBrandInfo')) is null
begin
CREATE TABLE [dbo].[InsBrandInfo](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Brand] [varchar](10) NOT NULL,
	[Series] [varchar](15) NOT NULL,
	[PollutantCode] [varchar](10) NOT NULL,
	[ShowName] [varchar](50) NULL,
	[StatusName] [varchar](50) NOT NULL,
	[LowLimit] [decimal](10, 3) NULL,
	[TopLimit] [decimal](10, 3) NULL,
	[OriUnit] [varchar](10) NULL,
	[TargetUnit] [varchar](10) NULL,
	[ConvertUnit] [decimal](10, 3) NULL,
	[IsShow] [tinyint] NULL,
	[IsStorage] [tinyint] NOT NULL,
 CONSTRAINT [InsBrandInfo1] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[InsBrandInfo] ADD  CONSTRAINT [DF_InsBrandInfo_LowLimit]  DEFAULT ((0)) FOR [LowLimit]
ALTER TABLE [dbo].[InsBrandInfo] ADD  CONSTRAINT [DF_InsBrandInfo_TopLimit]  DEFAULT ((0)) FOR [TopLimit]
ALTER TABLE [dbo].[InsBrandInfo] ADD  CONSTRAINT [DF_InsBrandInfo_IsShow]  DEFAULT ((0)) FOR [IsShow]
ALTER TABLE [dbo].[InsBrandInfo] ADD  CONSTRAINT [DF_InsBrandInfo_IsStorage]  DEFAULT ((1)) FOR [IsStorage]
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

	[RepeatCircle] [int]  NULL CONSTRAINT [DF_ManualQCEvent_RepeatCircle]  DEFAULT ((0)),
	[RepeatId] [int]  NULL CONSTRAINT [DF_ManualQCEvent_RepeatId]  DEFAULT ((-1)),

constraint [pk_ManuanlQCEvent] primary key([Id])
);
end
go



--数据存储表，需要替换相应的年月


                        
if (select object_id('Air_1m_$YEAR$_$MON$_Src')) is null
begin
CREATE TABLE Air_1m_$YEAR$_$MON$_Src (

                            Id             INT IDENTITY(1,1) NOT NULL,

                            StationCode     varchar(20)     NOT NULL,

                            TimePoint       datetime        NOT NULL,

                            PollutantCode   varchar(5)      NOT NULL,

                            MonValue        decimal(10,3)   NOT NULL,

                            Mark            varchar(255)    NOT NULL,

constraint [pk_Air_1m_$YEAR$_$MON$_Src] primary key([Id]));

end
go

if (select object_id('Air_5m_$YEAR$_$MON$_Src')) is null
begin                        
CREATE TABLE Air_5m_$YEAR$_$MON$_Src (

                            Id             INT IDENTITY(1,1) NOT NULL,

                            StationCode     varchar(20)     NOT NULL,

                            TimePoint       datetime        NOT NULL,

                            PollutantCode   varchar(5)      NOT NULL,

                            MonValue        decimal(10,3)   NOT NULL,

                            Mark            varchar(255)    NOT NULL,

constraint [pk_Air_5m_$YEAR$_$MON$_Src] primary key([Id]));
end
go


if (select object_id('Air_30s_$YEAR$_Src')) is null
begin						
                        
CREATE TABLE Air_30s_$YEAR$_Src (

                            Id             INT IDENTITY(1,1) NOT NULL,

                            StationCode     varchar(20)     NOT NULL,

                            TimePoint       datetime        NOT NULL,

                            PollutantCode   varchar(5)      NOT NULL,

                            MonValue        decimal(10,3)   NOT NULL,

                            Mark            varchar(255)    NOT NULL,

constraint [pk_Air_30s_$YEAR$_Src] primary key([Id]));

  
end
go                      

if (select object_id('Air_1h_$YEAR$_Src')) is null
begin
CREATE TABLE Air_1h_$YEAR$_Src (

                            Id              INT      IDENTITY(1,1) NOT NULL,

                            StationCode     varchar(20)     NOT NULL,

                            TimePoint       datetime        NOT NULL,

                            PollutantCode   varchar(5)      NOT NULL,

                            MonValue        decimal(10,3)   NOT NULL,

                            Mark            varchar(255)    NOT NULL,

constraint [pk_Air_1h_$YEAR$_Src] primary key([Id]));

 
end
go

if (select object_id('Air_1d_aqi_$YEAR$_Src')) is null
begin                       
CREATE TABLE Air_1d_aqi_$YEAR$_Src (

                            Id              INT    IDENTITY(1,1) NOT NULL,

                            StationCode     varchar(20)     NOT NULL,

                            TimePoint       datetime        NOT NULL,

                            PollutantCode   varchar(5)      NOT NULL,

                            MonValue        decimal(10,3)   NOT NULL,

                            Mark            varchar(255)    NOT NULL,

constraint [pk_Air_1d_aqi_$YEAR$_Src] primary key([Id]));
end
go


if (select object_id('Air_1d_api_$YEAR$_Src')) is null
begin
                        
CREATE TABLE Air_1d_api_$YEAR$_Src (

                            Id              INT     IDENTITY(1,1) NOT NULL,

                            StationCode     varchar(20)     NOT NULL,

                            TimePoint       datetime        NOT NULL,

                            PollutantCode   varchar(5)      NOT NULL,

                            MonValue        decimal(10,3)   NOT NULL,

                            Mark            varchar(255)    NOT NULL,

constraint [pk_Air_1d_api_$YEAR$_Src] primary key([Id]));

end
go	

if( select object_id('Ins_Live_$YEAR$') ) is null
begin

CREATE TABLE [dbo].[Ins_Live_$YEAR$](
[ID] [int] IDENTITY(1,1) NOT NULL,
[StationCode] [varchar](20) NOT NULL,
[TimePoint] [datetime] NOT NULL,
[Brand] [varchar](10) NOT NULL,
[Series] [varchar](15) NOT NULL,
[StatusName] [varchar](15) NOT NULL,
[PollutantCode] [varchar](10) NOT NULL,
[Value] [varchar](50) NOT NULL,
[Mark] [varchar](255) NOT NULL,
 CONSTRAINT [InsStatusInfo_Live1] PRIMARY KEY CLUSTERED 
(
[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]



end
go

if( select object_id('Ins_1h_$YEAR$') ) is null
begin

CREATE TABLE [dbo].[Ins_1h_$YEAR$](
[ID] [int] IDENTITY(1,1) NOT NULL,
[StationCode] [varchar](20) NOT NULL,
[TimePoint] [datetime] NOT NULL,
[Brand] [varchar](10) NOT NULL,
[Series] [varchar](15) NOT NULL,
[StatusName] [varchar](15) NOT NULL,
[PollutantCode] [varchar](10) NOT NULL,
[Value] [varchar](50) NOT NULL,
[Mark] [varchar](255) NOT NULL,
 CONSTRAINT [InsStatusInfo_Live2] PRIMARY KEY CLUSTERED 
(
[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]



end
go
