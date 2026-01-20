use AQMDB
go

if  exists( select 1 from sys.all_objects where [type]='p' and [name]='ChangeFieldLength') 
drop procedure ChangeFieldLength
go
create procedure ChangeFieldLength 
@tableName varchar(20),
@columnName varchar(20),
@length varchar(5),
@isNullable tinyint
as 
begin
declare @content varchar(800);
set @content='if exists(
select a.name object_name,b.name column_name,c.name type_name,max_length 
from sys.objects a join sys.columns b on a.object_id=b.object_id
     join  sys.systypes c on b.system_type_id=c.xtype
where c.status=0 and a.name ='''+@tableName+''' and b.name='''+@columnName+''' and max_length!='+@length +'
 )
 begin
      alter table '+@tableName+' alter column '+@columnName+' varchar('+@length+') NOT NULL
 end'
 
 if @isNullable = 1
 begin
 SET @content= REPLACE(@content,'NOT NULL','NULL')
 end
 
--print(@content)
exec (@content)
end

go

declare @drop_model varchar(500);
declare @drop_cmd varchar(700);
set @drop_model=
'if (select object_id(''TableName'')) is not null
begin 
drop table  TableName ;
end
';

set @drop_cmd=REPLACE(@drop_model,'TableName','QC_State_Record');
exec (@drop_cmd)

set @drop_cmd=REPLACE(@drop_model,'TableName','ResendCommand_History');
exec (@drop_cmd)

set @drop_cmd=REPLACE(@drop_model,'TableName','ResendCommand_Waiting');
exec (@drop_cmd)

set @drop_cmd=REPLACE(@drop_model,'TableName','Air_Temp_Mark');
exec (@drop_cmd)

set @drop_cmd=REPLACE(@drop_model,'TableName','Instrument_State_Record');
exec (@drop_cmd)

if (select object_id('Air_Temp_Mark')) is null
begin
CREATE TABLE Air_Temp_Mark (
 
    Id            INT      IDENTITY(1,1) NOT NULL  ,

    PollutantCode VARCHAR( 20 ),
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
else 
begin
--if (select * from sys.objects AS TableName JOIN sys.objects AS ColName 
--ON TableName.object_id=ColName.object_id 
--WHERE TableName.name='QC_Arrange' AND ColName.name='record_time') IS NULL
if(SELECT Name from SysColumns WHERE id=Object_Id('QC_Arrange') and name='record_time')is null
 alter table QC_Arrange add record_time datetime not null
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

if (select object_id('QC_History')) is not null
begin
exec ChangeFieldLength 'QC_History','document_name','200',1
if(SELECT Name from SysColumns WHERE id=Object_Id('QC_History') and name='record_time')is null
begin
alter table QC_History add record_time datetime not null default(GETDATE())
end
else 
ALTER TABLE [QC_History] ADD  CONSTRAINT [DF_QC_History_record_time]  DEFAULT ((GetDATE())) FOR record_time
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

document_name varchar(200) null,

record_time datetime not null DEFAULT(getdate()),
constraint[pk_QC_History] primary key([id])
);
end
go


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
[Type] [varchar](5) NOT NULL,--数据类型代码，ResendCommandTool的Convert2Type方法。
[PollutantCode] [varchar](20) NOT NULL,--监测污染物
[RecordTime] [datetime] NOT NULL,--记录时间
Destination tinyint null,
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
else
begin
if(SELECT Name from SysColumns WHERE id=Object_Id('ResendCommand') and name='StartDateTime')is NOT null
EXEC sp_rename 'ResendCommand.[StartDateTime ]', 'StartTime', 'COLUMN'
if(SELECT Name from SysColumns WHERE id=Object_Id('ResendCommand') and name='EndDateTime')is NOT null
EXEC sp_rename 'ResendCommand.[EndDateTime ]', 'EndTime', 'COLUMN'
if(SELECT Name from SysColumns WHERE id=Object_Id('ResendCommand') and name='MaxID')is null
alter  table ResendCommand add [MaxID] [int] NOT NULL
if(SELECT Name from SysColumns WHERE id=Object_Id('ResendCommand') and name='SourcePlatform')is null
alter  table ResendCommand add [SourcePlatform] [tinyint] NOT NULL
if(SELECT Name from SysColumns WHERE id=Object_Id('ResendCommand') and name='RecordTime')is null
alter  table ResendCommand add [RecordTime] [datetime] NOT NULL
if(SELECT Name from SysColumns WHERE id=Object_Id('ResendCommand') and name='Type')is NOT null
alter table ResendCommand alter column [Type] [varchar](5) NOT NULL
if(SELECT Name from SysColumns WHERE id=Object_Id('ResendCommand') and name='State')is NOT null
alter table ResendCommand alter column [State] [tinyint] NOT NULL
if(SELECT Name from SysColumns WHERE id=Object_Id('ResendCommand') and name='FailTick')is NOT null
alter table ResendCommand alter column [FailTick] [tinyint] NOT NULL
if(SELECT Name from SysColumns WHERE id=Object_Id('ResendCommand') and name='Detail')is NOT null
alter table REsendCommand drop column Detail
declare @sql varchar(900)
select @sql='alter table ResendCommand drop constraint '+name+' 


alter table ResendCommand alter column PollutantCode varchar(20) not null 


alter table ResendCommand alter column StartTime datetime not null 
alter table ResendCommand alter column EndTime datetime not null 
alter table ResendCommand alter column ReceiveIP varchar(30) not null 


alter table ResendCommand add PRIMARY KEY CLUSTERED 
(
[StartTime] ASC,
[EndTime] ASC,
[ReceiveIP] ASC,
[Type] ASC,
[PollutantCode] ASC,
[RecordTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY] 


'
from sys.objects where type='pk' and parent_object_id=object_id('ResendCommand')
print @sql
exec (@sql)


alter table ResendCommand add  Destination tinyint null
end
go

if(select object_id('InsBrandInfo')) is null
begin
CREATE TABLE [dbo].[InsBrandInfo](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Brand] [varchar](20) NOT NULL,
	[Series] [varchar](20) NOT NULL,
	[PollutantCode] [varchar](20) NOT NULL,
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
exec ChangeFieldLength 'InsBrandInfo','Brand','20',0
exec ChangeFieldLength 'InsBrandInfo','Series','20',0
exec ChangeFieldLength 'InsBrandInfo','PollutantCode','20',0
go

if (select object_id('ManualQCEvent')) is not null
begin
if(SELECT Name from SysColumns WHERE id=Object_Id('ManualQCEvent') and name='repeatid')is null
begin
alter table ManualQCEvent add RepeatCircle int default(0)
alter table ManualQCEvent add RepeatId int default(1)
end
if(select COUNT(*) FROM ManualQCEvent) =0
drop table ManualQCEvent
end
go

if (select object_id('ManualQCEvent')) is null
begin
    CREATE TABLE ManualQCEvent (
 
    Id            INT       IDENTITY(2,1) NOT NULL,

    PollutantCode VARCHAR( 20 )    NOT NULL,

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

if(select object_id('PollingStation')) is null
begin
CREATE TABLE [dbo].[PollingStation](
	[id] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY ,
	[Operator] [varchar](50) NOT NULL,
	[FillingDate] [datetime] NOT NULL,
	[FillingName] [varchar](20) NOT NULL,
	[TableData] [text] NOT NULL,
	[ErrorCount] [int] NOT NULL,
	[Script] [text] NOT NULL,
	[Extraordinarily] [text] NULL,
	[ModelDocName] [varchar](150) NOT NULL,
 );
end
go 



--数据存储表，需要替换相应的年月

declare @year varchar(4);
set @year=year(getdate())
declare @month varchar(2);
set @month=month(getdate())

declare @tablecontext varchar(700);
set @tablecontext='if (select object_id(''TableName'')) is null
begin
CREATE TABLE TableName (

                            Id             INT IDENTITY(1,1) NOT NULL,

                            StationCode     varchar(20)     NOT NULL,

                            TimePoint       datetime        NOT NULL,

                            PollutantCode   varchar(20)      NOT NULL,

                            MonValue        decimal(10,3)   NOT NULL,

                            Mark            varchar(255)    NOT NULL,

constraint [pk_TableName] primary key([Id]));
end
exec ChangeFieldLength ''TableName'', ''PollutantCode'' ,''20'',0
'

declare @tableName varchar(50);
declare @cmd varchar(800);

 
 --set @myTableName='Air_Temp_Mark';


set @tableName='Air_1m_'+@year+'_'+@month+'_Src'
set @cmd=REPLACE(@tablecontext,'TableName',@tableName)
exec (@cmd)

set @tableName='Air_5m_'+@year+'_'+@month+'_Src'
set @cmd=REPLACE(@tablecontext,'TableName',@tableName)
exec (@cmd)

set @tableName='Air_30s_'+@year+'_Src'
set @cmd=REPLACE(@tablecontext,'TableName',@tableName)
exec (@cmd)

set @tableName='Air_1h_'+@year+'_Src'
set @cmd=REPLACE(@tablecontext,'TableName',@tableName)
exec (@cmd)

set @tableName='Air_1d_aqi_'+@year+'_Src'
set @cmd=REPLACE(@tablecontext,'TableName',@tableName)
exec (@cmd)

set @tableName='Air_1d_api_'+@year+'_Src'
set @cmd=REPLACE(@tablecontext,'TableName',@tableName)
exec (@cmd)
                        
set @tablecontext='if( select object_id(''TableName'') ) is null
begin

CREATE TABLE [dbo].[TableName](
[ID] [int] IDENTITY(1,1) NOT NULL,
[StationCode] [varchar](20) NOT NULL,
[TimePoint] [datetime] NOT NULL,
[Brand] [varchar](20) NOT NULL,
[Series] [varchar](20) NOT NULL,
[StatusName] [varchar](20) NOT NULL,
[PollutantCode] [varchar](20) NOT NULL,
[Value] [varchar](50) NOT NULL,
[Mark] [varchar](255) NOT NULL,
 CONSTRAINT [pk_TableName] PRIMARY KEY CLUSTERED 
(
[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

end'

set @tableName='Ins_Live_'+@year
set @cmd=REPLACE(@tablecontext,'TableName',@tableName)
exec (@cmd)
exec ChangeFieldLength @tableName,'Brand','20',0
exec ChangeFieldLength @tableName,'Series','20',0
exec ChangeFieldLength @tableName,'StatusName','20',0
exec ChangeFieldLength @tableName,'PollutantCode','20',0


set @tableName='Ins_1h_'+@year
set @cmd=REPLACE(@tablecontext,'TableName',@tableName)
exec (@cmd)
exec ChangeFieldLength @tableName,'Brand','20',0
exec ChangeFieldLength @tableName,'Series','20',0
exec ChangeFieldLength @tableName,'StatusName','20',0
exec ChangeFieldLength @tableName,'PollutantCode','20',0

if (select OBJECT_ID('PollutantCode')) is null
begin
CREATE TABLE [dbo].[PollutantCode](
	[id] [int] IDENTITY(1,1) NOT NULL primary key,
	[PollutantCode] [varchar](20) NOT NULL,
	[ChineseName] [varchar](20) NULL,
 )
end
GO

IF (SELECT object_id( 'Info_MachineCollection')) is not null 
BEGIN
DROP TABLE [dbo].[Info_MachineCollection]
END

CREATE TABLE [dbo].[Info_MachineCollection](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CollectionType] [nvarchar](20) NOT NULL,
	[Description] [nvarchar](50) NOT NULL,
	[WMI_Cmd] [nvarchar](80) NULL,
 CONSTRAINT [PK_Info_MachineCollection] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

drop procedure ChangeFieldLength;

SET IDENTITY_INSERT [dbo].[Info_MachineCollection] ON
INSERT [dbo].[Info_MachineCollection] ([Id], [CollectionType], [Description], [WMI_Cmd]) VALUES (1, N'CPU_Brand', N'CPU型号', N'Win32_Processor,Manufacturer')
INSERT [dbo].[Info_MachineCollection] ([Id], [CollectionType], [Description], [WMI_Cmd]) VALUES (2, N'CPU_Desc', N'CPU描述', N'Win32_Processor,Name')
INSERT [dbo].[Info_MachineCollection] ([Id], [CollectionType], [Description], [WMI_Cmd]) VALUES (3, N'CPU_Freq', N'CPU主频(GHz)', N'Win32_Processor,CurrentClockSpeed')
INSERT [dbo].[Info_MachineCollection] ([Id], [CollectionType], [Description], [WMI_Cmd]) VALUES (4, N'RAM', N'内存总容量(GB)', N'Win32_ComputerSystem,TotalPhysicalMemory')
INSERT [dbo].[Info_MachineCollection] ([Id], [CollectionType], [Description], [WMI_Cmd]) VALUES (5, N'ROM', N'硬盘总容量(GB)', N'Win32_DiskDrive,Size')
INSERT [dbo].[Info_MachineCollection] ([Id], [CollectionType], [Description], [WMI_Cmd]) VALUES (6, N'Oper_Version', N'操作系统版本', N'Win32_OperatingSystem,Caption')
INSERT [dbo].[Info_MachineCollection] ([Id], [CollectionType], [Description], [WMI_Cmd]) VALUES (7, N'Oper_NT', N'操作系统NT版本', N'Win32_OperatingSystem,Version')
INSERT [dbo].[Info_MachineCollection] ([Id], [CollectionType], [Description], [WMI_Cmd]) VALUES (8, N'Oper_Pack', N'操作系统Pack版本', N'Win32_OperatingSystem,CSDVersion')
INSERT [dbo].[Info_MachineCollection] ([Id], [CollectionType], [Description], [WMI_Cmd]) VALUES (9, N'AQM_Version', N'数采版本号', NULL)
INSERT [dbo].[Info_MachineCollection] ([Id], [CollectionType], [Description], [WMI_Cmd]) VALUES (10, N'Station_Code', N'站点编号', NULL)
INSERT [dbo].[Info_MachineCollection] ([Id], [CollectionType], [Description], [WMI_Cmd]) VALUES (11, N'Station_Name', N'站点名称', NULL)
INSERT [dbo].[Info_MachineCollection] ([Id], [CollectionType], [Description], [WMI_Cmd]) VALUES (12, N'Station_LocalIP', N'站点的内网IP', NULL)
INSERT [dbo].[Info_MachineCollection] ([Id], [CollectionType], [Description], [WMI_Cmd]) VALUES (16, N'Station_IP', N'站点的外网IP', NULL)
INSERT [dbo].[Info_MachineCollection] ([Id], [CollectionType], [Description], [WMI_Cmd]) VALUES (17, N'AQM_Connect', N'仪器连接状态', NULL)
INSERT [dbo].[Info_MachineCollection] ([Id], [CollectionType], [Description], [WMI_Cmd]) VALUES (20, N'AQM_ConDetail', N'仪器连接详细状态', NULL)
INSERT [dbo].[Info_MachineCollection] ([Id], [CollectionType], [Description], [WMI_Cmd]) VALUES (24, N'AQM_QC', N'当月质控次数', NULL)
INSERT [dbo].[Info_MachineCollection] ([Id], [CollectionType], [Description], [WMI_Cmd]) VALUES (25, N'Disk', N'硬盘分区信息', N'Win32_DiskDrive')
INSERT [dbo].[Info_MachineCollection] ([Id], [CollectionType], [Description], [WMI_Cmd]) VALUES (26, N'MdfPath', N'AQMDB数据库文件所在盘符', NULL)
INSERT [dbo].[Info_MachineCollection] ([Id], [CollectionType], [Description], [WMI_Cmd]) VALUES (27, N'CPU_Core', N'CPU核心数', N'Win32_Processor,NumberOfLogicalProcessors')
SET IDENTITY_INSERT [dbo].[Info_MachineCollection] OFF



SET IDENTITY_INSERT [dbo].[PollutantCode] ON
INSERT [dbo].[PollutantCode] ([id], [PollutantCode], [ChineseName]) VALUES (1, N'SO2', N'二氧化硫')
INSERT [dbo].[PollutantCode] ([id], [PollutantCode], [ChineseName]) VALUES (2, N'CO', N'一氧化碳')
INSERT [dbo].[PollutantCode] ([id], [PollutantCode], [ChineseName]) VALUES (3, N'NO', N'一氧化氮')
INSERT [dbo].[PollutantCode] ([id], [PollutantCode], [ChineseName]) VALUES (4, N'NOx', N'总氮')
INSERT [dbo].[PollutantCode] ([id], [PollutantCode], [ChineseName]) VALUES (5, N'NO2', N'二氧化氮')
INSERT [dbo].[PollutantCode] ([id], [PollutantCode], [ChineseName]) VALUES (6, N'O3', N'臭氧')
INSERT [dbo].[PollutantCode] ([id], [PollutantCode], [ChineseName]) VALUES (7, N'PM10', N'颗粒物')
INSERT [dbo].[PollutantCode] ([id], [PollutantCode], [ChineseName]) VALUES (8, N'PM2.5', N'细颗粒物')
INSERT [dbo].[PollutantCode] ([id], [PollutantCode], [ChineseName]) VALUES (9, N'CO2', N'二氧化碳')
INSERT [dbo].[PollutantCode] ([id], [PollutantCode], [ChineseName]) VALUES (10, N'CH4', N'甲烷')
INSERT [dbo].[PollutantCode] ([id], [PollutantCode], [ChineseName]) VALUES (11, N'风速', N'风速')
INSERT [dbo].[PollutantCode] ([id], [PollutantCode], [ChineseName]) VALUES (12, N'风向', N'风向')
INSERT [dbo].[PollutantCode] ([id], [PollutantCode], [ChineseName]) VALUES (13, N'气温', N'气温')
INSERT [dbo].[PollutantCode] ([id], [PollutantCode], [ChineseName]) VALUES (14, N'湿度', N'湿度')
INSERT [dbo].[PollutantCode] ([id], [PollutantCode], [ChineseName]) VALUES (15, N'气压', N'气压')
INSERT [dbo].[PollutantCode] ([id], [PollutantCode], [ChineseName]) VALUES (16, N'降水强度', N'降水强度')
INSERT [dbo].[PollutantCode] ([id], [PollutantCode], [ChineseName]) VALUES (17, N'降水量', N'降水量')
SET IDENTITY_INSERT [dbo].[PollutantCode] OFF

SET IDENTITY_INSERT [InsBrandInfo] ON
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (52, N'API', N'M100', N'SO2', N'PMT背景值', N'PMT背景值', CAST(200.000 AS Decimal(10, 3)), CAST(325.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (59, N'API', N'M100', N'SO2', N'PMT温度', N'PMT温度', CAST(7.500 AS Decimal(10, 3)), CAST(11.500 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (47, N'API', N'M100', N'SO2', N'PMT信号', N'PMT信号', CAST(-20.000 AS Decimal(10, 3)), CAST(150.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (45, N'API', N'M100', N'SO2', N'样气压力', N'采样压力', CAST(-9999.000 AS Decimal(10, 3)), CAST(9999.000 AS Decimal(10, 3)), N'In-Hg-A', N'In-Hg-A', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (48, N'API', N'M100', N'SO2', N'参考PMT信号', N'参考PMT信号', CAST(0.000 AS Decimal(10, 3)), CAST(100.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (53, N'API', N'M100', N'SO2', N'灯背景值', N'灯背景值', CAST(-50.000 AS Decimal(10, 3)), CAST(200.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (57, N'API', N'M100', N'SO2', N'反应室温度', N'反应室温度', CAST(49.000 AS Decimal(10, 3)), CAST(51.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (51, N'API', N'M100', N'SO2', N'干扰光', N'干扰光', CAST(-9999.000 AS Decimal(10, 3)), CAST(100.000 AS Decimal(10, 3)), N'ppb', N'ppb', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (56, N'API', N'M100', N'SO2', N'高压电源', N'高压电源', CAST(400.000 AS Decimal(10, 3)), CAST(800.000 AS Decimal(10, 3)), N'V', N'V', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (58, N'API', N'M100', N'SO2', N'机箱温度', N'机箱温度', CAST(-9999.000 AS Decimal(10, 3)), CAST(9999.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (55, N'API', N'M100', N'SO2', N'截距', N'截距', CAST(-9999.000 AS Decimal(10, 3)), CAST(250.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (46, N'API', N'M100', N'SO2', N'样气流量', N'室采样流量', CAST(640.000 AS Decimal(10, 3)), CAST(660.000 AS Decimal(10, 3)), N'ml/min', N'ml/min', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (44, N'API', N'M100', N'SO2', N'稳定度', N'稳定度', CAST(-9999.000 AS Decimal(10, 3)), CAST(0.300 AS Decimal(10, 3)), N'ppb', N'ppb', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (54, N'API', N'M100', N'SO2', N'斜率', N'斜率', CAST(0.500 AS Decimal(10, 3)), CAST(1.500 AS Decimal(10, 3)), N'—', N'—', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (49, N'API', N'M100', N'SO2', N'紫外灯电压', N'紫外灯光强', CAST(2000.000 AS Decimal(10, 3)), CAST(4500.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (50, N'API', N'M100', N'SO2', N'紫外灯效率', N'紫外灯效率', CAST(30.000 AS Decimal(10, 3)), CAST(120.000 AS Decimal(10, 3)), N'%', N'%', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (74, N'API', N'M200', N'NO', N'NOx截距', N'NOX截距', CAST(-10.000 AS Decimal(10, 3)), CAST(50.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (73, N'API', N'M200', N'NO', N'NOx斜率', N'NOX斜率', CAST(0.700 AS Decimal(10, 3)), CAST(1.300 AS Decimal(10, 3)), N'—', N'—', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (76, N'API', N'M200', N'NO', N'NO截距', N'NO截距', CAST(-10.000 AS Decimal(10, 3)), CAST(50.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (75, N'API', N'M200', N'NO', N'NO斜率', N'NO斜率', CAST(0.700 AS Decimal(10, 3)), CAST(1.300 AS Decimal(10, 3)), N'—', N'—', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (69, N'API', N'M200', N'NO', N'PMT温度', N'PMT温度', CAST(-9999.000 AS Decimal(10, 3)), CAST(9999.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (63, N'API', N'M200', N'NO', N'PMT信号', N'PMT信号', CAST(-100.000 AS Decimal(10, 3)), CAST(100.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (65, N'API', N'M200', N'NO', N'背景值', N'背景值', CAST(0.000 AS Decimal(10, 3)), CAST(1000.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (61, N'API', N'M200', N'NO', N'样气流量', N'采样流量', CAST(900.000 AS Decimal(10, 3)), CAST(1100.000 AS Decimal(10, 3)), N'ml/min', N'ml/min', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (72, N'API', N'M200', N'NO', N'样气压力', N'采样压力', CAST(25.000 AS Decimal(10, 3)), CAST(30.000 AS Decimal(10, 3)), N'In-Hg-A', N'In-Hg-A', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (64, N'API', N'M200', N'NO', N'参考PMT信号', N'参考PMT信号', CAST(-100.000 AS Decimal(10, 3)), CAST(100.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (62, N'API', N'M200', N'NO', N'臭氧流量', N'臭氧流量', CAST(65.000 AS Decimal(10, 3)), CAST(95.000 AS Decimal(10, 3)), N'ml/min', N'ml/min', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (67, N'API', N'M200', N'NO', N'反应室温度', N'反应室温度', CAST(39.000 AS Decimal(10, 3)), CAST(41.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (71, N'API', N'M200', N'NO', N'反应室压力', N'反应室压力', CAST(1.000 AS Decimal(10, 3)), CAST(4.000 AS Decimal(10, 3)), N'In-Hg-A', N'In-Hg-A', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (66, N'API', N'M200', N'NO', N'高压电源', N'高压电源', CAST(450.000 AS Decimal(10, 3)), CAST(900.000 AS Decimal(10, 3)), N'V', N'V', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (68, N'API', N'M200', N'NO', N'机箱温度', N'机箱温度', CAST(-9999.000 AS Decimal(10, 3)), CAST(9999.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (60, N'API', N'M200', N'NO', N'稳定度', N'稳定度', CAST(-9999.000 AS Decimal(10, 3)), CAST(1.000 AS Decimal(10, 3)), N'ppb', N'ppb', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (70, N'API', N'M200', N'NO', N'转换器温度', N'转换炉', CAST(310.000 AS Decimal(10, 3)), CAST(320.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (333, N'API', N'M200', N'NO2', N'NOx截距', N'NOX截距', CAST(-10.000 AS Decimal(10, 3)), CAST(50.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (332, N'API', N'M200', N'NO2', N'NOx斜率', N'NOX斜率', CAST(0.700 AS Decimal(10, 3)), CAST(1.300 AS Decimal(10, 3)), N'—', N'—', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (335, N'API', N'M200', N'NO2', N'NO截距', N'NO截距', CAST(-10.000 AS Decimal(10, 3)), CAST(50.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (334, N'API', N'M200', N'NO2', N'NO斜率', N'NO斜率', CAST(0.700 AS Decimal(10, 3)), CAST(1.300 AS Decimal(10, 3)), N'—', N'—', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (328, N'API', N'M200', N'NO2', N'PMT温度', N'PMT温度', CAST(-9999.000 AS Decimal(10, 3)), CAST(9999.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (322, N'API', N'M200', N'NO2', N'PMT信号', N'PMT信号', CAST(-100.000 AS Decimal(10, 3)), CAST(100.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (324, N'API', N'M200', N'NO2', N'背景值', N'背景值', CAST(0.000 AS Decimal(10, 3)), CAST(1000.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (320, N'API', N'M200', N'NO2', N'样气流量', N'采样流量', CAST(900.000 AS Decimal(10, 3)), CAST(1100.000 AS Decimal(10, 3)), N'ml/min', N'ml/min', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (331, N'API', N'M200', N'NO2', N'样气压力', N'采样压力', CAST(25.000 AS Decimal(10, 3)), CAST(30.000 AS Decimal(10, 3)), N'In-Hg-A', N'In-Hg-A', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (323, N'API', N'M200', N'NO2', N'参考PMT信号', N'参考PMT信号', CAST(-100.000 AS Decimal(10, 3)), CAST(100.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (321, N'API', N'M200', N'NO2', N'臭氧流量', N'臭氧流量', CAST(65.000 AS Decimal(10, 3)), CAST(95.000 AS Decimal(10, 3)), N'ml/min', N'ml/min', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (326, N'API', N'M200', N'NO2', N'反应室温度', N'反应室温度', CAST(39.000 AS Decimal(10, 3)), CAST(41.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (330, N'API', N'M200', N'NO2', N'反应室压力', N'反应室压力', CAST(1.000 AS Decimal(10, 3)), CAST(4.000 AS Decimal(10, 3)), N'In-Hg-A', N'In-Hg-A', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (325, N'API', N'M200', N'NO2', N'高压电源', N'高压电源', CAST(450.000 AS Decimal(10, 3)), CAST(900.000 AS Decimal(10, 3)), N'V', N'V', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (327, N'API', N'M200', N'NO2', N'机箱温度', N'机箱温度', CAST(-9999.000 AS Decimal(10, 3)), CAST(9999.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (319, N'API', N'M200', N'NO2', N'稳定度', N'稳定度', CAST(-9999.000 AS Decimal(10, 3)), CAST(1.000 AS Decimal(10, 3)), N'ppb', N'ppb', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (329, N'API', N'M200', N'NO2', N'转换器温度', N'转换炉', CAST(310.000 AS Decimal(10, 3)), CAST(320.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (404, N'API', N'M200', N'NOx', N'NOx截距', N'NOX截距', CAST(-10.000 AS Decimal(10, 3)), CAST(50.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (403, N'API', N'M200', N'NOx', N'NOx斜率', N'NOX斜率', CAST(0.700 AS Decimal(10, 3)), CAST(1.300 AS Decimal(10, 3)), N'—', N'—', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (406, N'API', N'M200', N'NOx', N'NO截距', N'NO截距', CAST(-10.000 AS Decimal(10, 3)), CAST(50.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (405, N'API', N'M200', N'NOx', N'NO斜率', N'NO斜率', CAST(0.700 AS Decimal(10, 3)), CAST(1.300 AS Decimal(10, 3)), N'—', N'—', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (399, N'API', N'M200', N'NOx', N'PMT温度', N'PMT温度', CAST(-9999.000 AS Decimal(10, 3)), CAST(9999.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (393, N'API', N'M200', N'NOx', N'PMT信号', N'PMT信号', CAST(-100.000 AS Decimal(10, 3)), CAST(100.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (395, N'API', N'M200', N'NOx', N'背景值', N'背景值', CAST(0.000 AS Decimal(10, 3)), CAST(1000.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (391, N'API', N'M200', N'NOx', N'样气流量', N'采样流量', CAST(900.000 AS Decimal(10, 3)), CAST(1100.000 AS Decimal(10, 3)), N'ml/min', N'ml/min', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (402, N'API', N'M200', N'NOx', N'样气压力', N'采样压力', CAST(25.000 AS Decimal(10, 3)), CAST(30.000 AS Decimal(10, 3)), N'In-Hg-A', N'In-Hg-A', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (394, N'API', N'M200', N'NOx', N'参考PMT信号', N'参考PMT信号', CAST(-100.000 AS Decimal(10, 3)), CAST(100.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (392, N'API', N'M200', N'NOx', N'臭氧流量', N'臭氧流量', CAST(65.000 AS Decimal(10, 3)), CAST(95.000 AS Decimal(10, 3)), N'ml/min', N'ml/min', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (397, N'API', N'M200', N'NOx', N'反应室温度', N'反应室温度', CAST(39.000 AS Decimal(10, 3)), CAST(41.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (401, N'API', N'M200', N'NOx', N'反应室压力', N'反应室压力', CAST(1.000 AS Decimal(10, 3)), CAST(4.000 AS Decimal(10, 3)), N'In-Hg-A', N'In-Hg-A', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (396, N'API', N'M200', N'NOx', N'高压电源', N'高压电源', CAST(450.000 AS Decimal(10, 3)), CAST(900.000 AS Decimal(10, 3)), N'V', N'V', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (398, N'API', N'M200', N'NOx', N'机箱温度', N'机箱温度', CAST(-9999.000 AS Decimal(10, 3)), CAST(9999.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (390, N'API', N'M200', N'NOx', N'稳定度', N'稳定度', CAST(-9999.000 AS Decimal(10, 3)), CAST(1.000 AS Decimal(10, 3)), N'ppb', N'ppb', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (400, N'API', N'M200', N'NOx', N'转换器温度', N'转换炉', CAST(310.000 AS Decimal(10, 3)), CAST(320.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (81, N'API', N'M300', N'CO', N'样气压力', N'采样压力', CAST(-9999.000 AS Decimal(10, 3)), CAST(9999.000 AS Decimal(10, 3)), N'In-Hg-A', N'In-Hg-A', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (79, N'API', N'M300', N'CO', N'参比信号', N'参比信号', CAST(2500.000 AS Decimal(10, 3)), CAST(4800.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (78, N'API', N'M300', N'CO', N'测量信号', N'测量信号', CAST(2500.000 AS Decimal(10, 3)), CAST(4800.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (80, N'API', N'M300', N'CO', N'测量信号/参比信号', N'测量信号/参比信号', CAST(1.170 AS Decimal(10, 3)), CAST(1.220 AS Decimal(10, 3)), N'—', N'—', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (84, N'API', N'M300', N'CO', N'光室温度', N'光室温度', CAST(44.000 AS Decimal(10, 3)), CAST(52.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (86, N'API', N'M300', N'CO', N'机箱温度', N'机箱温度', CAST(-9999.000 AS Decimal(10, 3)), CAST(9999.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (89, N'API', N'M300', N'CO', N'截距', N'截距', CAST(-0.200 AS Decimal(10, 3)), CAST(2.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (77, N'API', N'M300', N'CO', N'稳定度', N'稳定度', CAST(-9999.000 AS Decimal(10, 3)), CAST(1.000 AS Decimal(10, 3)), N'ppm', N'ppm', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (85, N'API', N'M300', N'CO', N'轮温度', N'相关轮温度', CAST(66.000 AS Decimal(10, 3)), CAST(70.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (88, N'API', N'M300', N'CO', N'斜率', N'斜率', CAST(0.700 AS Decimal(10, 3)), CAST(1.300 AS Decimal(10, 3)), N'', N'', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (82, N'API', N'M300', N'CO', N'样气温度', N'样品温度', CAST(44.000 AS Decimal(10, 3)), CAST(52.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (87, N'API', N'M300', N'CO', N'制冷驱动电压', N'制冷驱动电压', CAST(250.000 AS Decimal(10, 3)), CAST(4750.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (94, N'API', N'M400', N'O3', N'样气流量', N'采样流量', CAST(790.000 AS Decimal(10, 3)), CAST(810.000 AS Decimal(10, 3)), N'ml/min', N'ml/min', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (92, N'API', N'M400', N'O3', N'参比信号', N'参比信号', CAST(2500.000 AS Decimal(10, 3)), CAST(4800.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (91, N'API', N'M400', N'O3', N'测量信号', N'测量信号', CAST(2500.000 AS Decimal(10, 3)), CAST(4800.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (96, N'API', N'M400', N'O3', N'光室温度', N'光度计温度', CAST(45.000 AS Decimal(10, 3)), CAST(51.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (97, N'API', N'M400', N'O3', N'机箱温度', N'机箱温度', CAST(-9999.000 AS Decimal(10, 3)), CAST(9999.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (99, N'API', N'M400', N'O3', N'截距', N'截距', CAST(-5.000 AS Decimal(10, 3)), CAST(5.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (90, N'API', N'M400', N'O3', N'稳定度', N'稳定度', CAST(-9999.000 AS Decimal(10, 3)), CAST(1.000 AS Decimal(10, 3)), N'ppb', N'ppb', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (98, N'API', N'M400', N'O3', N'斜率', N'斜率', CAST(-0.500 AS Decimal(10, 3)), CAST(2.500 AS Decimal(10, 3)), N'', N'', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (93, N'API', N'M400', N'O3', N'样气压力', N'压力', CAST(-9999.000 AS Decimal(10, 3)), CAST(9999.000 AS Decimal(10, 3)), N'In-Hg-A', N'In-Hg-A', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (95, N'API', N'M400', N'O3', N'样气温度', N'样品温度', CAST(10.000 AS Decimal(10, 3)), CAST(50.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (181, N'DASIBI', N'1208', N'O3', N'加热器电压', N'加热器电压', CAST(0.010 AS Decimal(10, 3)), CAST(5.000 AS Decimal(10, 3)), N'V', N'V', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (182, N'DASIBI', N'1208', N'O3', N'样气压力', N'压力', CAST(0.000 AS Decimal(10, 3)), CAST(800.000 AS Decimal(10, 3)), N'mmHg', N'mmHg', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (172, N'DASIBI', N'2208', N'NO', N'反应室温度', N'反应室温度', CAST(40.000 AS Decimal(10, 3)), CAST(50.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (173, N'DASIBI', N'2208', N'NO', N'高压', N'高压', CAST(500.000 AS Decimal(10, 3)), CAST(950.000 AS Decimal(10, 3)), N'V', N'V', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (174, N'DASIBI', N'2208', N'NO', N'转换器温度', N'转换室温度', CAST(26.000 AS Decimal(10, 3)), CAST(55.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (175, N'DASIBI', N'2208', N'NO', N'样气流量', N'总流量', CAST(150.000 AS Decimal(10, 3)), CAST(500.000 AS Decimal(10, 3)), N'ccpm', N'ccpm', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (349, N'DASIBI', N'2208', N'NO2', N'反应室温度', N'反应室温度', CAST(40.000 AS Decimal(10, 3)), CAST(50.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (350, N'DASIBI', N'2208', N'NO2', N'高压', N'高压', CAST(500.000 AS Decimal(10, 3)), CAST(950.000 AS Decimal(10, 3)), N'V', N'V', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (351, N'DASIBI', N'2208', N'NO2', N'转换器温度', N'转换室温度', CAST(26.000 AS Decimal(10, 3)), CAST(55.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (352, N'DASIBI', N'2208', N'NO2', N'样气流量', N'总流量', CAST(150.000 AS Decimal(10, 3)), CAST(500.000 AS Decimal(10, 3)), N'ccpm', N'ccpm', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (420, N'DASIBI', N'2208', N'NOx', N'反应室温度', N'反应室温度', CAST(40.000 AS Decimal(10, 3)), CAST(50.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
GO
print 'Processed 100 total records'
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (421, N'DASIBI', N'2208', N'NOx', N'高压', N'高压', CAST(500.000 AS Decimal(10, 3)), CAST(950.000 AS Decimal(10, 3)), N'V', N'V', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (422, N'DASIBI', N'2208', N'NOx', N'转换器温度', N'转换室温度', CAST(26.000 AS Decimal(10, 3)), CAST(55.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (423, N'DASIBI', N'2208', N'NOx', N'样气流量', N'总流量', CAST(150.000 AS Decimal(10, 3)), CAST(500.000 AS Decimal(10, 3)), N'ccpm', N'ccpm', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (178, N'DASIBI', N'3208', N'CO', N'Det信号', N'Det信号', CAST(2.000 AS Decimal(10, 3)), CAST(9.000 AS Decimal(10, 3)), N'V', N'V', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (176, N'DASIBI', N'3208', N'CO', N'反应室温度', N'反应室温度', CAST(20.000 AS Decimal(10, 3)), CAST(70.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (179, N'DASIBI', N'3208', N'CO', N'样气流量', N'流速', CAST(500.000 AS Decimal(10, 3)), CAST(2000.000 AS Decimal(10, 3)), N'ccpm', N'ccpm', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (177, N'DASIBI', N'3208', N'CO', N'轮温度', N'轮温', CAST(30.000 AS Decimal(10, 3)), CAST(55.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (180, N'DASIBI', N'3208', N'CO', N'样气压力', N'压力', CAST(400.000 AS Decimal(10, 3)), CAST(800.000 AS Decimal(10, 3)), N'mmHg', N'mmHg', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (169, N'DASIBI', N'4208', N'SO2', N'Det信号', N'Det信号', CAST(1.000 AS Decimal(10, 3)), CAST(15.000 AS Decimal(10, 3)), N'V', N'V', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (170, N'DASIBI', N'4208', N'SO2', N'样气流量', N'流速', CAST(100.000 AS Decimal(10, 3)), CAST(2000.000 AS Decimal(10, 3)), N'ccpm', N'ccpm', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (171, N'DASIBI', N'4208', N'SO2', N'样气压力', N'压力', CAST(100.000 AS Decimal(10, 3)), CAST(900.000 AS Decimal(10, 3)), N'mmHg', N'mmHg', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (183, N'DASIBI', N'7201', N'PM10', N'高压', N'高压', CAST(8.000 AS Decimal(10, 3)), CAST(9999.000 AS Decimal(10, 3)), N'V', N'V', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (243, N'EC', N'9841', N'NO', N'样气流量', N'采样流量', CAST(0.515 AS Decimal(10, 3)), CAST(0.765 AS Decimal(10, 3)), N'SLPM', N'SLPM', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (246, N'EC', N'9841', N'NO', N'反应室温度', N'反应室温度', CAST(47.000 AS Decimal(10, 3)), CAST(53.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (245, N'EC', N'9841', N'NO', N'机箱温度', N'内部温度', CAST(25.000 AS Decimal(10, 3)), CAST(40.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (244, N'EC', N'9841', N'NO', N'大气压力', N'压力', CAST(690.000 AS Decimal(10, 3)), CAST(760.000 AS Decimal(10, 3)), N'Torr', N'Torr', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (242, N'EC', N'9841', N'NO', N'样气压力', N'样气压力', CAST(75.000 AS Decimal(10, 3)), CAST(375.000 AS Decimal(10, 3)), N'Torr', N'Torr', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (247, N'EC', N'9841', N'NO', N'制冷器温度', N'制冷器温度', CAST(10.000 AS Decimal(10, 3)), CAST(14.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (248, N'EC', N'9841', N'NO', N'转换器温度', N'转换炉温度', CAST(315.000 AS Decimal(10, 3)), CAST(335.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (358, N'EC', N'9841', N'NO2', N'样气流量', N'采样流量', CAST(0.515 AS Decimal(10, 3)), CAST(0.765 AS Decimal(10, 3)), N'SLPM', N'SLPM', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (361, N'EC', N'9841', N'NO2', N'反应室温度', N'反应室温度', CAST(47.000 AS Decimal(10, 3)), CAST(53.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (360, N'EC', N'9841', N'NO2', N'机箱温度', N'内部温度', CAST(25.000 AS Decimal(10, 3)), CAST(40.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (359, N'EC', N'9841', N'NO2', N'大气压力', N'压力', CAST(690.000 AS Decimal(10, 3)), CAST(760.000 AS Decimal(10, 3)), N'Torr', N'Torr', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (357, N'EC', N'9841', N'NO2', N'样气压力', N'样气压力', CAST(75.000 AS Decimal(10, 3)), CAST(375.000 AS Decimal(10, 3)), N'Torr', N'Torr', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (362, N'EC', N'9841', N'NO2', N'制冷器温度', N'制冷器温度', CAST(10.000 AS Decimal(10, 3)), CAST(14.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (363, N'EC', N'9841', N'NO2', N'转换器温度', N'转换炉温度', CAST(315.000 AS Decimal(10, 3)), CAST(335.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (429, N'EC', N'9841', N'NOx', N'样气流量', N'采样流量', CAST(0.515 AS Decimal(10, 3)), CAST(0.765 AS Decimal(10, 3)), N'SLPM', N'SLPM', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (432, N'EC', N'9841', N'NOx', N'反应室温度', N'反应室温度', CAST(47.000 AS Decimal(10, 3)), CAST(53.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (431, N'EC', N'9841', N'NOx', N'机箱温度', N'内部温度', CAST(25.000 AS Decimal(10, 3)), CAST(40.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (430, N'EC', N'9841', N'NOx', N'大气压力', N'压力', CAST(690.000 AS Decimal(10, 3)), CAST(760.000 AS Decimal(10, 3)), N'Torr', N'Torr', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (428, N'EC', N'9841', N'NOx', N'样气压力', N'样气压力', CAST(75.000 AS Decimal(10, 3)), CAST(375.000 AS Decimal(10, 3)), N'Torr', N'Torr', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (433, N'EC', N'9841', N'NOx', N'制冷器温度', N'制冷器温度', CAST(10.000 AS Decimal(10, 3)), CAST(14.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (434, N'EC', N'9841', N'NOx', N'转换器温度', N'转换炉温度', CAST(315.000 AS Decimal(10, 3)), CAST(335.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (240, N'EC', N'9850', N'SO2', N'反应室温度', N'反应室温度', CAST(47.000 AS Decimal(10, 3)), CAST(53.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (236, N'EC', N'9850', N'SO2', N'样气流量', N'流量', CAST(0.375 AS Decimal(10, 3)), CAST(0.625 AS Decimal(10, 3)), N'SLPM', N'SLPM', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (239, N'EC', N'9850', N'SO2', N'机箱温度', N'内部温度', CAST(25.000 AS Decimal(10, 3)), CAST(35.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (238, N'EC', N'9850', N'SO2', N'浓度电压', N'浓度电压', CAST(0.000 AS Decimal(10, 3)), CAST(4.200 AS Decimal(10, 3)), N'V', N'V', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (235, N'EC', N'9850', N'SO2', N'样气压力', N'压力', CAST(690.000 AS Decimal(10, 3)), CAST(760.000 AS Decimal(10, 3)), N'Torr', N'Torr', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (241, N'EC', N'9850', N'SO2', N'制冷器温度', N'制冷温度', CAST(10.000 AS Decimal(10, 3)), CAST(14.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (237, N'EC', N'9850', N'SO2', N'紫外灯电压', N'紫外灯参比电压', CAST(2.300 AS Decimal(10, 3)), CAST(2.700 AS Decimal(10, 3)), N'V', N'V', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (118, N'ESA', N'AC32', N'NO', N'+15v参考', N'+15v参考', CAST(1200.000 AS Decimal(10, 3)), CAST(1600.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (117, N'ESA', N'AC32', N'NO', N'-15v参考', N'-15v参考', CAST(-1600.000 AS Decimal(10, 3)), CAST(-1200.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (124, N'ESA', N'AC32', N'NO', N'2.5v参考', N'2.5v参考', CAST(2440.000 AS Decimal(10, 3)), CAST(2550.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (112, N'ESA', N'AC32', N'NO', N'GND接地', N'GND接地', CAST(-9999.000 AS Decimal(10, 3)), CAST(50.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (120, N'ESA', N'AC32', N'NO', N'臭氧发生器', N'臭氧发生器', CAST(100.000 AS Decimal(10, 3)), CAST(250.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (123, N'ESA', N'AC32', N'NO', N'反应室温度', N'反应室温度', CAST(1350.000 AS Decimal(10, 3)), CAST(1450.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (116, N'ESA', N'AC32', N'NO', N'反应室压力', N'反应室压力', CAST(133.000 AS Decimal(10, 3)), CAST(433.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (121, N'ESA', N'AC32', N'NO', N'PMT高压', N'高压', CAST(480.000 AS Decimal(10, 3)), CAST(950.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (122, N'ESA', N'AC32', N'NO', N'PMT温度', N'光电倍增温度', CAST(1240.000 AS Decimal(10, 3)), CAST(1300.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (119, N'ESA', N'AC32', N'NO', N'PMT电压', N'光电倍增信号', CAST(0.000 AS Decimal(10, 3)), CAST(9999.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (115, N'ESA', N'AC32', N'NO', N'样气压力', N'样气压力', CAST(408.000 AS Decimal(10, 3)), CAST(610.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (113, N'ESA', N'AC32', N'NO', N'机箱温度', N'仪器内部温度', CAST(50.000 AS Decimal(10, 3)), CAST(500.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (114, N'ESA', N'AC32', N'NO', N'转换器温度', N'转换炉温度', CAST(2426.000 AS Decimal(10, 3)), CAST(2765.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (342, N'ESA', N'AC32', N'NO2', N'+15v参考', N'+15v参考', CAST(1200.000 AS Decimal(10, 3)), CAST(1600.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (341, N'ESA', N'AC32', N'NO2', N'-15v参考', N'-15v参考', CAST(-1600.000 AS Decimal(10, 3)), CAST(-1200.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (348, N'ESA', N'AC32', N'NO2', N'2.5v参考', N'2.5v参考', CAST(2440.000 AS Decimal(10, 3)), CAST(2550.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (336, N'ESA', N'AC32', N'NO2', N'GND接地', N'GND接地', CAST(-9999.000 AS Decimal(10, 3)), CAST(50.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (344, N'ESA', N'AC32', N'NO2', N'臭氧发生器', N'臭氧发生器', CAST(100.000 AS Decimal(10, 3)), CAST(250.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (347, N'ESA', N'AC32', N'NO2', N'反应室温度', N'反应室温度', CAST(1350.000 AS Decimal(10, 3)), CAST(1450.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (340, N'ESA', N'AC32', N'NO2', N'反应室压力', N'反应室压力', CAST(133.000 AS Decimal(10, 3)), CAST(433.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (345, N'ESA', N'AC32', N'NO2', N'PMT高压', N'高压', CAST(480.000 AS Decimal(10, 3)), CAST(950.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (346, N'ESA', N'AC32', N'NO2', N'PMT温度', N'光电倍增温度', CAST(1240.000 AS Decimal(10, 3)), CAST(1300.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (343, N'ESA', N'AC32', N'NO2', N'PMT电压', N'光电倍增信号', CAST(0.000 AS Decimal(10, 3)), CAST(9999.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (339, N'ESA', N'AC32', N'NO2', N'样气压力', N'样气压力', CAST(408.000 AS Decimal(10, 3)), CAST(610.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (337, N'ESA', N'AC32', N'NO2', N'机箱温度', N'仪器内部温度', CAST(50.000 AS Decimal(10, 3)), CAST(500.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (338, N'ESA', N'AC32', N'NO2', N'转换器温度', N'转换炉温度', CAST(2426.000 AS Decimal(10, 3)), CAST(2765.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (413, N'ESA', N'AC32', N'NOx', N'+15v参考', N'+15v参考', CAST(1200.000 AS Decimal(10, 3)), CAST(1600.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (412, N'ESA', N'AC32', N'NOx', N'-15v参考', N'-15v参考', CAST(-1600.000 AS Decimal(10, 3)), CAST(-1200.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (419, N'ESA', N'AC32', N'NOx', N'2.5v参考', N'2.5v参考', CAST(2440.000 AS Decimal(10, 3)), CAST(2550.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (407, N'ESA', N'AC32', N'NOx', N'GND接地', N'GND接地', CAST(-9999.000 AS Decimal(10, 3)), CAST(50.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (415, N'ESA', N'AC32', N'NOx', N'臭氧发生器', N'臭氧发生器', CAST(100.000 AS Decimal(10, 3)), CAST(250.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (418, N'ESA', N'AC32', N'NOx', N'反应室温度', N'反应室温度', CAST(1350.000 AS Decimal(10, 3)), CAST(1450.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (411, N'ESA', N'AC32', N'NOx', N'反应室压力', N'反应室压力', CAST(133.000 AS Decimal(10, 3)), CAST(433.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (416, N'ESA', N'AC32', N'NOx', N'PMT高压', N'高压', CAST(480.000 AS Decimal(10, 3)), CAST(950.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (417, N'ESA', N'AC32', N'NOx', N'PMT温度', N'光电倍增温度', CAST(1240.000 AS Decimal(10, 3)), CAST(1300.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (414, N'ESA', N'AC32', N'NOx', N'PMT电压', N'光电倍增信号', CAST(0.000 AS Decimal(10, 3)), CAST(9999.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (410, N'ESA', N'AC32', N'NOx', N'样气压力', N'样气压力', CAST(408.000 AS Decimal(10, 3)), CAST(610.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (408, N'ESA', N'AC32', N'NOx', N'机箱温度', N'仪器内部温度', CAST(50.000 AS Decimal(10, 3)), CAST(500.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (409, N'ESA', N'AC32', N'NOx', N'转换器温度', N'转换炉温度', CAST(2426.000 AS Decimal(10, 3)), CAST(2765.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (107, N'ESA', N'AF22', N'SO2', N'+15v参考', N'+15v参考', CAST(1200.000 AS Decimal(10, 3)), CAST(1600.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (106, N'ESA', N'AF22', N'SO2', N'-15v参考', N'-15v参考', CAST(-1600.000 AS Decimal(10, 3)), CAST(-1200.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (111, N'ESA', N'AF22', N'SO2', N'2.5v参考', N'2.5v参考', CAST(2450.000 AS Decimal(10, 3)), CAST(2550.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (100, N'ESA', N'AF22', N'SO2', N'GND接地', N'GND接地', CAST(-9999.000 AS Decimal(10, 3)), CAST(50.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (103, N'ESA', N'AF22', N'SO2', N'PMT高压', N'光电倍增高压', CAST(2100.000 AS Decimal(10, 3)), CAST(4500.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (109, N'ESA', N'AF22', N'SO2', N'PMT电压', N'光电倍增信号', CAST(0.000 AS Decimal(10, 3)), CAST(400.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (102, N'ESA', N'AF22', N'SO2', N'光室温度', N'光具座温度', CAST(0.000 AS Decimal(10, 3)), CAST(500.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (104, N'ESA', N'AF22', N'SO2', N'样气流量', N'仪器流量', CAST(1000.000 AS Decimal(10, 3)), CAST(5000.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (101, N'ESA', N'AF22', N'SO2', N'机箱温度', N'仪器内部温度', CAST(100.000 AS Decimal(10, 3)), CAST(600.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (105, N'ESA', N'AF22', N'SO2', N'样气压力', N'仪器压力', CAST(1200.000 AS Decimal(10, 3)), CAST(5000.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (110, N'ESA', N'AF22', N'SO2', N'紫外灯强度', N'紫外灯强度', CAST(80.000 AS Decimal(10, 3)), CAST(440.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (108, N'ESA', N'AF22', N'SO2', N'紫外灯电压', N'紫外灯信号', CAST(1000.000 AS Decimal(10, 3)), CAST(9000.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (131, N'ESA', N'CO12', N'CO', N'+15v参考', N'+15v参考', CAST(1450.000 AS Decimal(10, 3)), CAST(1550.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (130, N'ESA', N'CO12', N'CO', N'-15v参考', N'-15v参考', CAST(-1550.000 AS Decimal(10, 3)), CAST(-1450.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (134, N'ESA', N'CO12', N'CO', N'2.5v参考', N'2.5v参考', CAST(2480.000 AS Decimal(10, 3)), CAST(2520.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (125, N'ESA', N'CO12', N'CO', N'GND接地', N'GND接地', CAST(-10.000 AS Decimal(10, 3)), CAST(10.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (127, N'ESA', N'CO12', N'CO', N'光室温度', N'光具座温度', CAST(445.000 AS Decimal(10, 3)), CAST(475.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (133, N'ESA', N'CO12', N'CO', N'红外信号', N'红外信号', CAST(970.000 AS Decimal(10, 3)), CAST(1020.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (132, N'ESA', N'CO12', N'CO', N'制冷器温度', N'冷却器强度', CAST(300.000 AS Decimal(10, 3)), CAST(900.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (128, N'ESA', N'CO12', N'CO', N'样气流量', N'仪器流量', CAST(4100.000 AS Decimal(10, 3)), CAST(5100.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (126, N'ESA', N'CO12', N'CO', N'机箱温度', N'仪器内部温度', CAST(100.000 AS Decimal(10, 3)), CAST(500.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (129, N'ESA', N'CO12', N'CO', N'样气压力', N'仪器压力', CAST(3700.000 AS Decimal(10, 3)), CAST(4300.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
GO
print 'Processed 200 total records'
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (142, N'ESA', N'O342', N'O3', N'+15v参考', N'+15v参考', CAST(1200.000 AS Decimal(10, 3)), CAST(1600.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (141, N'ESA', N'O342', N'O3', N'-15v参考', N'-15v参考', CAST(-1600.000 AS Decimal(10, 3)), CAST(-1200.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (146, N'ESA', N'O342', N'O3', N'2.5v参考', N'2.5v参考', CAST(2400.000 AS Decimal(10, 3)), CAST(2600.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (135, N'ESA', N'O342', N'O3', N'GND接地', N'GND接地', CAST(-10.000 AS Decimal(10, 3)), CAST(10.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (145, N'ESA', N'O342', N'O3', N'参考信号', N'参考信号', CAST(500.000 AS Decimal(10, 3)), CAST(4800.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (144, N'ESA', N'O342', N'O3', N'测量信号', N'测量信号', CAST(500.000 AS Decimal(10, 3)), CAST(4800.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (138, N'ESA', N'O342', N'O3', N'光室温度', N'光具座温度', CAST(100.000 AS Decimal(10, 3)), CAST(600.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (137, N'ESA', N'O342', N'O3', N'样气温度', N'气体温度', CAST(100.000 AS Decimal(10, 3)), CAST(500.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (139, N'ESA', N'O342', N'O3', N'样气流量', N'仪器流量', CAST(1500.000 AS Decimal(10, 3)), CAST(2500.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (136, N'ESA', N'O342', N'O3', N'机箱温度', N'仪器内部温度', CAST(100.000 AS Decimal(10, 3)), CAST(600.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (140, N'ESA', N'O342', N'O3', N'样气压力', N'仪器压力', CAST(3000.000 AS Decimal(10, 3)), CAST(5000.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (143, N'ESA', N'O342', N'O3', N'紫外灯电流', N'紫外灯测量电流', CAST(100.000 AS Decimal(10, 3)), CAST(250.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (150, N'ESA', N'PM101', N'PM10', N'+15v参考', N'+15v参考', CAST(1300.000 AS Decimal(10, 3)), CAST(1700.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (148, N'ESA', N'PM101', N'PM10', N'+5v电压', N'+5v电压', CAST(4800.000 AS Decimal(10, 3)), CAST(5200.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (149, N'ESA', N'PM101', N'PM10', N'-15v参考', N'-15v参考', CAST(1300.000 AS Decimal(10, 3)), CAST(1700.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (151, N'ESA', N'PM101', N'PM10', N'2.5v参考', N'2.5v参考', CAST(2450.000 AS Decimal(10, 3)), CAST(2550.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (157, N'ESA', N'PM101', N'PM10', N'A/D参考', N'A/D参考', CAST(2450.000 AS Decimal(10, 3)), CAST(2550.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (147, N'ESA', N'PM101', N'PM10', N'GND接地', N'GND接地', CAST(-50.000 AS Decimal(10, 3)), CAST(50.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (156, N'ESA', N'PM101', N'PM10', N'大气压力', N'大气压力', CAST(3880.000 AS Decimal(10, 3)), CAST(4380.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (152, N'ESA', N'PM101', N'PM10', N'过虑温度', N'过滤温度', CAST(100.000 AS Decimal(10, 3)), CAST(400.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (153, N'ESA', N'PM101', N'PM10', N'机箱温度', N'仪器内部温度', CAST(100.000 AS Decimal(10, 3)), CAST(400.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (154, N'ESA', N'PM101', N'PM10', N'上游压力', N'仪器上游压力', CAST(3880.000 AS Decimal(10, 3)), CAST(4380.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (155, N'ESA', N'PM101', N'PM10', N'下游压力', N'仪器下游压力', CAST(3880.000 AS Decimal(10, 3)), CAST(4380.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (161, N'ESA', N'PM101', N'PM2.5', N'+15v参考', N'+15v参考', CAST(1300.000 AS Decimal(10, 3)), CAST(1700.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (159, N'ESA', N'PM101', N'PM2.5', N'+5v电压', N'+5v电压', CAST(4800.000 AS Decimal(10, 3)), CAST(5200.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (160, N'ESA', N'PM101', N'PM2.5', N'-15v参考', N'-15v参考', CAST(1300.000 AS Decimal(10, 3)), CAST(1700.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (162, N'ESA', N'PM101', N'PM2.5', N'2.5v参考', N'2.5v参考', CAST(2450.000 AS Decimal(10, 3)), CAST(2550.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (168, N'ESA', N'PM101', N'PM2.5', N'A/D参考', N'A/D参考', CAST(2450.000 AS Decimal(10, 3)), CAST(2550.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (158, N'ESA', N'PM101', N'PM2.5', N'GND接地', N'GND接地', CAST(-50.000 AS Decimal(10, 3)), CAST(50.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (167, N'ESA', N'PM101', N'PM2.5', N'大气压力', N'大气压力', CAST(3880.000 AS Decimal(10, 3)), CAST(4380.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (163, N'ESA', N'PM101', N'PM2.5', N'过虑温度', N'过滤温度', CAST(100.000 AS Decimal(10, 3)), CAST(400.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (164, N'ESA', N'PM101', N'PM2.5', N'机箱温度', N'仪器内部温度', CAST(100.000 AS Decimal(10, 3)), CAST(400.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (165, N'ESA', N'PM101', N'PM2.5', N'上游压力', N'仪器上游压力', CAST(3880.000 AS Decimal(10, 3)), CAST(4380.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (166, N'ESA', N'PM101', N'PM2.5', N'下游压力', N'仪器下游压力', CAST(3880.000 AS Decimal(10, 3)), CAST(4380.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (186, N'OPSIS', N'AR500S', N'CO', N'光强', N'光强', CAST(15.000 AS Decimal(10, 3)), CAST(90.000 AS Decimal(10, 3)), N'%', N'%', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (185, N'OPSIS', N'AR500S', N'CO', N'偏差', N'偏差', CAST(0.000 AS Decimal(10, 3)), CAST(1000.000 AS Decimal(10, 3)), N'ug/m3', N'ug/m3', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (455, N'OPSIS', N'AR500S', N'NO', N'光强', N'光强', CAST(15.000 AS Decimal(10, 3)), CAST(90.000 AS Decimal(10, 3)), N'%', N'%', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (454, N'OPSIS', N'AR500S', N'NO', N'偏差', N'偏差', CAST(0.000 AS Decimal(10, 3)), CAST(1000.000 AS Decimal(10, 3)), N'ug/m3', N'ug/m3', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (457, N'OPSIS', N'AR500S', N'NO2', N'光强', N'光强', CAST(15.000 AS Decimal(10, 3)), CAST(90.000 AS Decimal(10, 3)), N'%', N'%', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (456, N'OPSIS', N'AR500S', N'NO2', N'偏差', N'偏差', CAST(0.000 AS Decimal(10, 3)), CAST(1000.000 AS Decimal(10, 3)), N'ug/m3', N'ug/m3', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (459, N'OPSIS', N'AR500S', N'O3', N'光强', N'光强', CAST(15.000 AS Decimal(10, 3)), CAST(90.000 AS Decimal(10, 3)), N'%', N'%', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (458, N'OPSIS', N'AR500S', N'O3', N'偏差', N'偏差', CAST(0.000 AS Decimal(10, 3)), CAST(1000.000 AS Decimal(10, 3)), N'ug/m3', N'ug/m3', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (461, N'OPSIS', N'AR500S', N'SO2', N'光强', N'光强', CAST(15.000 AS Decimal(10, 3)), CAST(90.000 AS Decimal(10, 3)), N'%', N'%', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (460, N'OPSIS', N'AR500S', N'SO2', N'偏差', N'偏差', CAST(0.000 AS Decimal(10, 3)), CAST(1000.000 AS Decimal(10, 3)), N'ug/m3', N'ug/m3', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (33, N'TE', N'1405DF', N'PM10', N'采样管温度', N'采样管温度', CAST(50.000 AS Decimal(10, 3)), CAST(50.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (28, N'TE', N'1405DF', N'PM10', N'滤膜载量', N'采样滤膜负载量', CAST(-9999.000 AS Decimal(10, 3)), CAST(90.000 AS Decimal(10, 3)), N'％', N'％', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (32, N'TE', N'1405DF', N'PM10', N'顶盖温度', N'顶盖温度', CAST(50.000 AS Decimal(10, 3)), CAST(50.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (30, N'TE', N'1405DF', N'PM10', N'辅助流量', N'辅助流量', CAST(15.670 AS Decimal(10, 3)), CAST(15.670 AS Decimal(10, 3)), N'LPM', N'LPM', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (31, N'TE', N'1405DF', N'PM10', N'机箱温度', N'机箱温度', CAST(50.000 AS Decimal(10, 3)), CAST(50.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (35, N'TE', N'1405DF', N'PM10', N'频率', N'频率', CAST(200.000 AS Decimal(10, 3)), CAST(350.000 AS Decimal(10, 3)), N'Hz', N'Hz', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (34, N'TE', N'1405DF', N'PM10', N'噪声', N'噪声', CAST(-9999.000 AS Decimal(10, 3)), CAST(0.100 AS Decimal(10, 3)), N'Hz', N'Hz', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (29, N'TE', N'1405DF', N'PM10', N'样气流量', N'主流量', CAST(1.000 AS Decimal(10, 3)), CAST(1.000 AS Decimal(10, 3)), N'LPM', N'LPM', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (41, N'TE', N'1405DF', N'PM2.5', N'采样管温度', N'采样管温度', CAST(-9999.000 AS Decimal(10, 3)), CAST(50.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (36, N'TE', N'1405DF', N'PM2.5', N'滤膜载量', N'采样滤膜负载量', CAST(-9999.000 AS Decimal(10, 3)), CAST(90.000 AS Decimal(10, 3)), N'％', N'％', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (40, N'TE', N'1405DF', N'PM2.5', N'顶盖温度', N'顶盖温度', CAST(-9999.000 AS Decimal(10, 3)), CAST(50.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (38, N'TE', N'1405DF', N'PM2.5', N'辅助流量', N'辅助流量', CAST(-9999.000 AS Decimal(10, 3)), CAST(15.670 AS Decimal(10, 3)), N'LPM', N'LPM', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (39, N'TE', N'1405DF', N'PM2.5', N'机箱温度', N'机箱温度', CAST(-9999.000 AS Decimal(10, 3)), CAST(50.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (43, N'TE', N'1405DF', N'PM2.5', N'频率', N'频率', CAST(200.000 AS Decimal(10, 3)), CAST(350.000 AS Decimal(10, 3)), N'Hz', N'Hz', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (42, N'TE', N'1405DF', N'PM2.5', N'噪声', N'噪声', CAST(-9999.000 AS Decimal(10, 3)), CAST(0.100 AS Decimal(10, 3)), N'Hz', N'Hz', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (37, N'TE', N'1405DF', N'PM2.5', N'样气流量', N'主流量', CAST(-9999.000 AS Decimal(10, 3)), CAST(1.000 AS Decimal(10, 3)), N'LPM', N'LPM', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (8, N'TE', N'42', N'NO', N'样气流量', N'采样流量', CAST(0.500 AS Decimal(10, 3)), CAST(2.000 AS Decimal(10, 3)), N'LPM', N'LPM', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (9, N'TE', N'42', N'NO', N'臭氧流量', N'臭氧流量', CAST(0.050 AS Decimal(10, 3)), CAST(9999.000 AS Decimal(10, 3)), N'LPM', N'LPM', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (11, N'TE', N'42', N'NO', N'反应室温度', N'反应室温度', CAST(48.000 AS Decimal(10, 3)), CAST(52.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (10, N'TE', N'42', N'NO', N'机箱温度', N'内部温度', CAST(15.000 AS Decimal(10, 3)), CAST(45.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (7, N'TE', N'42', N'NO', N'样气压力', N'压力', CAST(100.000 AS Decimal(10, 3)), CAST(450.000 AS Decimal(10, 3)), N'mmHg', N'mmHg', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (12, N'TE', N'42', N'NO', N'制冷器温度', N'制冷器温度', CAST(-20.000 AS Decimal(10, 3)), CAST(-1.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (13, N'TE', N'42', N'NO', N'转换器温度', N'转换炉温度', CAST(300.000 AS Decimal(10, 3)), CAST(350.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (313, N'TE', N'42', N'NO2', N'样气流量', N'采样流量', CAST(0.500 AS Decimal(10, 3)), CAST(2.000 AS Decimal(10, 3)), N'LPM', N'LPM', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (314, N'TE', N'42', N'NO2', N'臭氧流量', N'臭氧流量', CAST(0.050 AS Decimal(10, 3)), CAST(9999.000 AS Decimal(10, 3)), N'LPM', N'LPM', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (316, N'TE', N'42', N'NO2', N'反应室温度', N'反应室温度', CAST(48.000 AS Decimal(10, 3)), CAST(52.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (315, N'TE', N'42', N'NO2', N'机箱温度', N'内部温度', CAST(15.000 AS Decimal(10, 3)), CAST(45.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (312, N'TE', N'42', N'NO2', N'样气压力', N'压力', CAST(100.000 AS Decimal(10, 3)), CAST(450.000 AS Decimal(10, 3)), N'mmHg', N'mmHg', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (317, N'TE', N'42', N'NO2', N'制冷器温度', N'制冷器温度', CAST(-20.000 AS Decimal(10, 3)), CAST(-1.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (318, N'TE', N'42', N'NO2', N'转换器温度', N'转换炉温度', CAST(300.000 AS Decimal(10, 3)), CAST(350.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (384, N'TE', N'42', N'NOx', N'样气流量', N'采样流量', CAST(0.500 AS Decimal(10, 3)), CAST(2.000 AS Decimal(10, 3)), N'LPM', N'LPM', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (385, N'TE', N'42', N'NOx', N'臭氧流量', N'臭氧流量', CAST(0.050 AS Decimal(10, 3)), CAST(9999.000 AS Decimal(10, 3)), N'LPM', N'LPM', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (387, N'TE', N'42', N'NOx', N'反应室温度', N'反应室温度', CAST(48.000 AS Decimal(10, 3)), CAST(52.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (386, N'TE', N'42', N'NOx', N'机箱温度', N'内部温度', CAST(15.000 AS Decimal(10, 3)), CAST(45.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (383, N'TE', N'42', N'NOx', N'样气压力', N'压力', CAST(100.000 AS Decimal(10, 3)), CAST(450.000 AS Decimal(10, 3)), N'mmHg', N'mmHg', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (388, N'TE', N'42', N'NOx', N'制冷器温度', N'制冷器温度', CAST(-20.000 AS Decimal(10, 3)), CAST(-1.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (389, N'TE', N'42', N'NOx', N'转换器温度', N'转换炉温度', CAST(300.000 AS Decimal(10, 3)), CAST(350.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (6, N'TE', N'43', N'SO2', N'反应室温度', N'反应室', CAST(43.000 AS Decimal(10, 3)), CAST(47.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (2, N'TE', N'43', N'SO2', N'样气流量', N'流量', CAST(0.350 AS Decimal(10, 3)), CAST(0.750 AS Decimal(10, 3)), N'LPM', N'LPM', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (5, N'TE', N'43', N'SO2', N'机箱温度', N'内部温度', CAST(15.000 AS Decimal(10, 3)), CAST(40.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (1, N'TE', N'43', N'SO2', N'样气压力', N'压力', CAST(400.000 AS Decimal(10, 3)), CAST(1000.000 AS Decimal(10, 3)), N'mmHg', N'mmHg', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (3, N'TE', N'43', N'SO2', N'紫外灯电压', N'紫外灯电压', CAST(800.000 AS Decimal(10, 3)), CAST(1200.000 AS Decimal(10, 3)), N'V', N'V', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (4, N'TE', N'43', N'SO2', N'紫外灯强度', N'紫外灯强度', CAST(40.000 AS Decimal(10, 3)), CAST(100.000 AS Decimal(10, 3)), N'%', N'%', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (17, N'TE', N'48', N'CO', N'光室温度', N'光室温度', CAST(40.000 AS Decimal(10, 3)), CAST(59.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (15, N'TE', N'48', N'CO', N'样气流量', N'流量', CAST(0.300 AS Decimal(10, 3)), CAST(0.750 AS Decimal(10, 3)), N'LPM', N'LPM', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (20, N'TE', N'48', N'CO', N'电机速度', N'马达速度', CAST(100.000 AS Decimal(10, 3)), CAST(9999.000 AS Decimal(10, 3)), N'%', N'%', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (16, N'TE', N'48', N'CO', N'机箱温度', N'内部温度', CAST(38.000 AS Decimal(10, 3)), CAST(45.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (18, N'TE', N'48', N'CO', N'偏置电压', N'偏置电压', CAST(-130.000 AS Decimal(10, 3)), CAST(-100.000 AS Decimal(10, 3)), N'V', N'V', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (14, N'TE', N'48', N'CO', N'样气压力', N'压力', CAST(250.000 AS Decimal(10, 3)), CAST(1000.000 AS Decimal(10, 3)), N'mmHg', N'mmHg', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (19, N'TE', N'48', N'CO', N'自动增益', N'自动增益控制', CAST(150000.000 AS Decimal(10, 3)), CAST(300000.000 AS Decimal(10, 3)), N'Hz', N'Hz', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (27, N'TE', N'49', N'O3', N'紫外灯温度', N'灯温度', CAST(50.000 AS Decimal(10, 3)), CAST(60.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (24, N'TE', N'49', N'O3', N'光强A', N'光强A', CAST(45000.000 AS Decimal(10, 3)), CAST(150000.000 AS Decimal(10, 3)), N'Hz', N'Hz', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (25, N'TE', N'49', N'O3', N'光强B', N'光强B', CAST(45000.000 AS Decimal(10, 3)), CAST(150000.000 AS Decimal(10, 3)), N'Hz', N'Hz', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (26, N'TE', N'49', N'O3', N'光室温度', N'光室温度', CAST(15.000 AS Decimal(10, 3)), CAST(40.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (22, N'TE', N'49', N'O3', N'样气流量A', N'流量A', CAST(0.400 AS Decimal(10, 3)), CAST(1.600 AS Decimal(10, 3)), N'LPM', N'LPM', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (23, N'TE', N'49', N'O3', N'样气流量B', N'流量B', CAST(0.400 AS Decimal(10, 3)), CAST(1.600 AS Decimal(10, 3)), N'LPM', N'LPM', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (21, N'TE', N'49', N'O3', N'样气压力', N'压力', CAST(200.000 AS Decimal(10, 3)), CAST(1000.000 AS Decimal(10, 3)), N'mmHg', N'mmHg', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
GO
print 'Processed 300 total records'
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (223, N'TH', N'2000', N'PM10', N'采样管温度', N'采样体温度', CAST(-40.000 AS Decimal(10, 3)), CAST(85.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (217, N'TH', N'2000', N'PM10', N'大气压力', N'大气压力', CAST(50.000 AS Decimal(10, 3)), CAST(106.000 AS Decimal(10, 3)), N'Pa', N'Pa', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (218, N'TH', N'2000', N'PM10', N'计前压力', N'计前压力', CAST(50.000 AS Decimal(10, 3)), CAST(106.000 AS Decimal(10, 3)), N'Pa', N'Pa', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (222, N'TH', N'2000', N'PM10', N'加热管温度', N'加热杆温度', CAST(-40.000 AS Decimal(10, 3)), CAST(85.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (219, N'TH', N'2000', N'PM10', N'样气流量', N'流量', CAST(15.500 AS Decimal(10, 3)), CAST(17.500 AS Decimal(10, 3)), N'ml/min', N'ml/min', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (225, N'TH', N'2000', N'PM10', N'脉冲频率', N'脉冲频率', CAST(500.000 AS Decimal(10, 3)), CAST(10000.000 AS Decimal(10, 3)), N'Hz', N'Hz', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (220, N'TH', N'2000', N'PM10', N'大气湿度', N'室外湿度', CAST(0.000 AS Decimal(10, 3)), CAST(100.000 AS Decimal(10, 3)), N'%', N'%', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (221, N'TH', N'2000', N'PM10', N'大气温度', N'室外温度', CAST(-40.000 AS Decimal(10, 3)), CAST(85.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (224, N'TH', N'2000', N'PM10', N'样气温度', N'样气温度', CAST(0.000 AS Decimal(10, 3)), CAST(50.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (232, N'TH', N'2000', N'PM2.5', N'采样管温度', N'采样体温度', CAST(-40.000 AS Decimal(10, 3)), CAST(85.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (226, N'TH', N'2000', N'PM2.5', N'大气压力', N'大气压力', CAST(50.000 AS Decimal(10, 3)), CAST(106.000 AS Decimal(10, 3)), N'Pa', N'Pa', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (227, N'TH', N'2000', N'PM2.5', N'计前压力', N'计前压力', CAST(50.000 AS Decimal(10, 3)), CAST(106.000 AS Decimal(10, 3)), N'Pa', N'Pa', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (231, N'TH', N'2000', N'PM2.5', N'加热管温度', N'加热杆温度', CAST(-40.000 AS Decimal(10, 3)), CAST(85.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (228, N'TH', N'2000', N'PM2.5', N'样气流量', N'流量', CAST(15.500 AS Decimal(10, 3)), CAST(17.500 AS Decimal(10, 3)), N'ml/min', N'ml/min', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (234, N'TH', N'2000', N'PM2.5', N'脉冲频率', N'脉冲频率', CAST(500.000 AS Decimal(10, 3)), CAST(10000.000 AS Decimal(10, 3)), N'Hz', N'Hz', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (229, N'TH', N'2000', N'PM2.5', N'大气湿度', N'室外湿度', CAST(0.000 AS Decimal(10, 3)), CAST(100.000 AS Decimal(10, 3)), N'%', N'%', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (230, N'TH', N'2000', N'PM2.5', N'大气温度', N'室外温度', CAST(-40.000 AS Decimal(10, 3)), CAST(85.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (233, N'TH', N'2000', N'PM2.5', N'样气温度', N'样气温度', CAST(0.000 AS Decimal(10, 3)), CAST(50.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (193, N'TH', N'2001', N'NO', N'PMT温度', N'PMT温度', CAST(0.000 AS Decimal(10, 3)), CAST(15.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (192, N'TH', N'2001', N'NO', N'反应室温度', N'反应室温度', CAST(45.000 AS Decimal(10, 3)), CAST(55.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (194, N'TH', N'2001', N'NO', N'样气流量', N'样气流量', CAST(300.000 AS Decimal(10, 3)), CAST(800.000 AS Decimal(10, 3)), N'l/min', N'l/min', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (191, N'TH', N'2001', N'NO', N'转换器温度', N'转换炉温度', CAST(180.000 AS Decimal(10, 3)), CAST(220.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (355, N'TH', N'2001', N'NO2', N'PMT温度', N'PMT温度', CAST(0.000 AS Decimal(10, 3)), CAST(15.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (354, N'TH', N'2001', N'NO2', N'反应室温度', N'反应室温度', CAST(45.000 AS Decimal(10, 3)), CAST(55.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (356, N'TH', N'2001', N'NO2', N'样气流量', N'样气流量', CAST(300.000 AS Decimal(10, 3)), CAST(800.000 AS Decimal(10, 3)), N'l/min', N'l/min', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (353, N'TH', N'2001', N'NO2', N'转换器温度', N'转换炉温度', CAST(180.000 AS Decimal(10, 3)), CAST(220.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (426, N'TH', N'2001', N'NOx', N'PMT温度', N'PMT温度', CAST(0.000 AS Decimal(10, 3)), CAST(15.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (425, N'TH', N'2001', N'NOx', N'反应室温度', N'反应室温度', CAST(45.000 AS Decimal(10, 3)), CAST(55.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (427, N'TH', N'2001', N'NOx', N'样气流量', N'样气流量', CAST(300.000 AS Decimal(10, 3)), CAST(800.000 AS Decimal(10, 3)), N'l/min', N'l/min', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (424, N'TH', N'2001', N'NOx', N'转换器温度', N'转换炉温度', CAST(180.000 AS Decimal(10, 3)), CAST(220.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (189, N'TH', N'2002', N'SO2', N'PMT温度', N'PMT温度', CAST(0.000 AS Decimal(10, 3)), CAST(15.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (188, N'TH', N'2002', N'SO2', N'反应室温度', N'反应室温度', CAST(45.000 AS Decimal(10, 3)), CAST(55.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (187, N'TH', N'2002', N'SO2', N'锌灯电压', N'锌灯电压', CAST(1.000 AS Decimal(10, 3)), CAST(2.000 AS Decimal(10, 3)), N'V', N'V', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (190, N'TH', N'2002', N'SO2', N'样气流量', N'样气流量', CAST(300.000 AS Decimal(10, 3)), CAST(800.000 AS Decimal(10, 3)), N'l/min', N'l/min', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (215, N'TH', N'2003', N'O3', N'+15v电压', N'+15v', CAST(14.000 AS Decimal(10, 3)), CAST(16.000 AS Decimal(10, 3)), N'V', N'V', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (214, N'TH', N'2003', N'O3', N'-15v电压', N'-15v', CAST(-16.000 AS Decimal(10, 3)), CAST(-14.000 AS Decimal(10, 3)), N'V', N'V', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (216, N'TH', N'2003', N'O3', N'2.5v电压', N'2.5v基准电压', CAST(2.450 AS Decimal(10, 3)), CAST(2.550 AS Decimal(10, 3)), N'V', N'V', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (211, N'TH', N'2003', N'O3', N'紫外灯电流', N'UV灯平均电流', CAST(15.000 AS Decimal(10, 3)), CAST(25.000 AS Decimal(10, 3)), N'A', N'A', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (210, N'TH', N'2003', N'O3', N'紫外灯温度', N'UV灯温度', CAST(40.000 AS Decimal(10, 3)), CAST(70.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (207, N'TH', N'2003', N'O3', N'参考电压', N'参考电压', CAST(2500.000 AS Decimal(10, 3)), CAST(6500.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (206, N'TH', N'2003', N'O3', N'测量电压', N'测量电压', CAST(2500.000 AS Decimal(10, 3)), CAST(6500.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (209, N'TH', N'2003', N'O3', N'光室温度', N'光室温度', CAST(0.000 AS Decimal(10, 3)), CAST(60.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (208, N'TH', N'2003', N'O3', N'机箱温度', N'机箱温度', CAST(10.000 AS Decimal(10, 3)), CAST(75.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (212, N'TH', N'2003', N'O3', N'样气流量', N'样气流量', CAST(300.000 AS Decimal(10, 3)), CAST(1200.000 AS Decimal(10, 3)), N'ml/min', N'ml/min', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (213, N'TH', N'2003', N'O3', N'样气压力', N'样气压力', CAST(50.000 AS Decimal(10, 3)), CAST(106.000 AS Decimal(10, 3)), N'kPa', N'kPa', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (204, N'TH', N'2004', N'CO', N'+15v电压', N'+15v', CAST(14.000 AS Decimal(10, 3)), CAST(16.000 AS Decimal(10, 3)), N'V', N'V', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (203, N'TH', N'2004', N'CO', N'-15v电压', N'-15v', CAST(-16.000 AS Decimal(10, 3)), CAST(-14.000 AS Decimal(10, 3)), N'V', N'V', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (205, N'TH', N'2004', N'CO', N'2.5v电压', N'2.5v基准电压', CAST(2.450 AS Decimal(10, 3)), CAST(2.550 AS Decimal(10, 3)), N'V', N'V', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (199, N'TH', N'2004', N'CO', N'IR灯电流', N'IR灯电流', CAST(0.900 AS Decimal(10, 3)), CAST(1.100 AS Decimal(10, 3)), N'A', N'A', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (196, N'TH', N'2004', N'CO', N'参考电压', N'参考电压', CAST(2500.000 AS Decimal(10, 3)), CAST(6500.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (195, N'TH', N'2004', N'CO', N'测量电压', N'测量电压', CAST(2500.000 AS Decimal(10, 3)), CAST(6500.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (198, N'TH', N'2004', N'CO', N'光室温度', N'光室温度', CAST(0.000 AS Decimal(10, 3)), CAST(60.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (197, N'TH', N'2004', N'CO', N'机箱温度', N'机箱温度', CAST(10.000 AS Decimal(10, 3)), CAST(75.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (201, N'TH', N'2004', N'CO', N'样气流量', N'样气流量', CAST(300.000 AS Decimal(10, 3)), CAST(1200.000 AS Decimal(10, 3)), N'ml/min', N'ml/min', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (202, N'TH', N'2004', N'CO', N'样气压力', N'样气压力', CAST(50.000 AS Decimal(10, 3)), CAST(106.000 AS Decimal(10, 3)), N'kPa', N'kPa', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (200, N'TH', N'2004', N'CO', N'制冷电流', N'致冷电流', CAST(0.000 AS Decimal(10, 3)), CAST(1.500 AS Decimal(10, 3)), N'A', N'A', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (291, N'XH', N'XHCO200B', N'CO', N'参比暗电流', N'参比暗电流', CAST(0.000 AS Decimal(10, 3)), CAST(500.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (289, N'XH', N'XHCO200B', N'CO', N'参比电压', N'参比电压', CAST(2500.000 AS Decimal(10, 3)), CAST(4700.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (292, N'XH', N'XHCO200B', N'CO', N'测量暗电流', N'测量暗电流', CAST(0.000 AS Decimal(10, 3)), CAST(500.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (293, N'XH', N'XHCO200B', N'CO', N'测量参比率', N'测量参比率', CAST(1.100 AS Decimal(10, 3)), CAST(1.250 AS Decimal(10, 3)), N' ', N' ', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (290, N'XH', N'XHCO200B', N'CO', N'测量电压', N'测量电压', CAST(2500.000 AS Decimal(10, 3)), CAST(4700.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (294, N'XH', N'XHCO200B', N'CO', N'电源组件', N'电源组件', CAST(2300.000 AS Decimal(10, 3)), CAST(2700.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (295, N'XH', N'XHCO200B', N'CO', N'光室温度', N'光室温度', CAST(47.000 AS Decimal(10, 3)), CAST(49.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (296, N'XH', N'XHCO200B', N'CO', N'机箱温度', N'机箱温度', CAST(-9999.000 AS Decimal(10, 3)), CAST(9999.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (285, N'XH', N'XHCO200B', N'CO', N'截距', N'截距', CAST(-6.000 AS Decimal(10, 3)), CAST(6.000 AS Decimal(10, 3)), N'μmol/mol', N'μmol/mol', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (283, N'XH', N'XHCO200B', N'CO', N'仪器量程', N'量程', CAST(0.000 AS Decimal(10, 3)), CAST(100.000 AS Decimal(10, 3)), N'μmol/mol', N'μmol/mol', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (286, N'XH', N'XHCO200B', N'CO', N'稳定度', N'稳定度', CAST(0.000 AS Decimal(10, 3)), CAST(4.000 AS Decimal(10, 3)), N'μmol/mol', N'μmol/mol', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (297, N'XH', N'XHCO200B', N'CO', N'轮温度', N'相关轮温度', CAST(62.000 AS Decimal(10, 3)), CAST(68.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (284, N'XH', N'XHCO200B', N'CO', N'斜率', N'斜率', CAST(0.700 AS Decimal(10, 3)), CAST(1.300 AS Decimal(10, 3)), N' ', N' ', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (288, N'XH', N'XHCO200B', N'CO', N'样气流量', N'样气流量', CAST(900.000 AS Decimal(10, 3)), CAST(1100.000 AS Decimal(10, 3)), N'ml/min', N'ml/min', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (298, N'XH', N'XHCO200B', N'CO', N'样气温度', N'样气温度', CAST(47.000 AS Decimal(10, 3)), CAST(49.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (287, N'XH', N'XHCO200B', N'CO', N'样气压力', N'样气压力', CAST(60.000 AS Decimal(10, 3)), CAST(120.000 AS Decimal(10, 3)), N'kPa', N'kPa', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (282, N'XH', N'XHN2000B', N'NO', N'NOx 截距', N'NOx 截距', CAST(-250.000 AS Decimal(10, 3)), CAST(250.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (280, N'XH', N'XHN2000B', N'NO', N'NOx斜率 ', N'NOx斜率 ', CAST(0.700 AS Decimal(10, 3)), CAST(1.300 AS Decimal(10, 3)), N' ', N' ', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (281, N'XH', N'XHN2000B', N'NO', N'NO截距', N'NO截距', CAST(-250.000 AS Decimal(10, 3)), CAST(250.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (279, N'XH', N'XHN2000B', N'NO', N'NO斜率', N'NO斜率', CAST(0.700 AS Decimal(10, 3)), CAST(1.300 AS Decimal(10, 3)), N' ', N' ', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (273, N'XH', N'XHN2000B', N'NO', N'PMT温度', N'PMT 温度', CAST(6.000 AS Decimal(10, 3)), CAST(8.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (268, N'XH', N'XHN2000B', N'NO', N'PMT电压', N'PMT电压', CAST(0.000 AS Decimal(10, 3)), CAST(5000.000 AS Decimal(10, 3)), N'V', N'V', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (276, N'XH', N'XHN2000B', N'NO', N'PMT高压', N'PMT高压', CAST(450.000 AS Decimal(10, 3)), CAST(900.000 AS Decimal(10, 3)), N'V', N'V', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (275, N'XH', N'XHN2000B', N'NO', N'PMT电压', N'PMT信号', CAST(0.000 AS Decimal(10, 3)), CAST(5000.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (267, N'XH', N'XHN2000B', N'NO', N'臭氧流量', N'臭氧流量', CAST(65.000 AS Decimal(10, 3)), CAST(95.000 AS Decimal(10, 3)), N'ml/min', N'ml/min', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (272, N'XH', N'XHN2000B', N'NO', N'反应室温度', N'反应温度', CAST(49.000 AS Decimal(10, 3)), CAST(51.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (270, N'XH', N'XHN2000B', N'NO', N'反应室压力', N'反应压力', CAST(13.000 AS Decimal(10, 3)), CAST(34.000 AS Decimal(10, 3)), N'kPa', N'kPa', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (274, N'XH', N'XHN2000B', N'NO', N'机箱温度', N'机箱温度', CAST(5.000 AS Decimal(10, 3)), CAST(45.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (264, N'XH', N'XHN2000B', N'NO', N'仪器量程', N'量程', CAST(-9999.000 AS Decimal(10, 3)), CAST(2.000 AS Decimal(10, 3)), N'μmol/mol', N'μmol/mol', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (271, N'XH', N'XHN2000B', N'NO', N'转换器温度', N'钼炉温度', CAST(310.000 AS Decimal(10, 3)), CAST(320.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (265, N'XH', N'XHN2000B', N'NO', N'稳定度', N'稳定度', CAST(0.000 AS Decimal(10, 3)), CAST(2.000 AS Decimal(10, 3)), N' ', N' ', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (266, N'XH', N'XHN2000B', N'NO', N'样气流量', N'样气流量', CAST(450.000 AS Decimal(10, 3)), CAST(550.000 AS Decimal(10, 3)), N'ml/min', N'ml/min', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (269, N'XH', N'XHN2000B', N'NO', N'样气压力', N'样气压力', CAST(84.000 AS Decimal(10, 3)), CAST(102.000 AS Decimal(10, 3)), N'kPa', N'kPa', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (277, N'XH', N'XHN2000B', N'NO', N'直流电压', N'直流电压', CAST(2300.000 AS Decimal(10, 3)), CAST(2700.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (278, N'XH', N'XHN2000B', N'NO', N'自动零点', N'自动零点', CAST(0.000 AS Decimal(10, 3)), CAST(250.000 AS Decimal(10, 3)), N' ', N' ', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (382, N'XH', N'XHN2000B', N'NO2', N'NOx 截距', N'NOx 截距', CAST(-250.000 AS Decimal(10, 3)), CAST(250.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (380, N'XH', N'XHN2000B', N'NO2', N'NOx斜率 ', N'NOx斜率 ', CAST(0.700 AS Decimal(10, 3)), CAST(1.300 AS Decimal(10, 3)), N' ', N' ', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (381, N'XH', N'XHN2000B', N'NO2', N'NO截距', N'NO截距', CAST(-250.000 AS Decimal(10, 3)), CAST(250.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (379, N'XH', N'XHN2000B', N'NO2', N'NO斜率', N'NO斜率', CAST(0.700 AS Decimal(10, 3)), CAST(1.300 AS Decimal(10, 3)), N' ', N' ', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (373, N'XH', N'XHN2000B', N'NO2', N'PMT温度', N'PMT 温度', CAST(6.000 AS Decimal(10, 3)), CAST(8.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (368, N'XH', N'XHN2000B', N'NO2', N'PMT电压', N'PMT电压', CAST(0.000 AS Decimal(10, 3)), CAST(5000.000 AS Decimal(10, 3)), N'V', N'V', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (376, N'XH', N'XHN2000B', N'NO2', N'PMT高压', N'PMT高压', CAST(450.000 AS Decimal(10, 3)), CAST(900.000 AS Decimal(10, 3)), N'V', N'V', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (375, N'XH', N'XHN2000B', N'NO2', N'PMT电压', N'PMT信号', CAST(0.000 AS Decimal(10, 3)), CAST(5000.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (367, N'XH', N'XHN2000B', N'NO2', N'臭氧流量', N'臭氧流量', CAST(65.000 AS Decimal(10, 3)), CAST(95.000 AS Decimal(10, 3)), N'ml/min', N'ml/min', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (372, N'XH', N'XHN2000B', N'NO2', N'反应室温度', N'反应温度', CAST(49.000 AS Decimal(10, 3)), CAST(51.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
GO
print 'Processed 400 total records'
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (370, N'XH', N'XHN2000B', N'NO2', N'反应室压力', N'反应压力', CAST(13.000 AS Decimal(10, 3)), CAST(34.000 AS Decimal(10, 3)), N'kPa', N'kPa', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (374, N'XH', N'XHN2000B', N'NO2', N'机箱温度', N'机箱温度', CAST(5.000 AS Decimal(10, 3)), CAST(45.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (364, N'XH', N'XHN2000B', N'NO2', N'仪器量程', N'量程', CAST(-9999.000 AS Decimal(10, 3)), CAST(2.000 AS Decimal(10, 3)), N'μmol/mol', N'μmol/mol', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (371, N'XH', N'XHN2000B', N'NO2', N'转换器温度', N'钼炉温度', CAST(310.000 AS Decimal(10, 3)), CAST(320.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (365, N'XH', N'XHN2000B', N'NO2', N'稳定度', N'稳定度', CAST(0.000 AS Decimal(10, 3)), CAST(2.000 AS Decimal(10, 3)), N' ', N' ', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (366, N'XH', N'XHN2000B', N'NO2', N'样气流量', N'样气流量', CAST(450.000 AS Decimal(10, 3)), CAST(550.000 AS Decimal(10, 3)), N'ml/min', N'ml/min', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (369, N'XH', N'XHN2000B', N'NO2', N'样气压力', N'样气压力', CAST(84.000 AS Decimal(10, 3)), CAST(102.000 AS Decimal(10, 3)), N'kPa', N'kPa', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (377, N'XH', N'XHN2000B', N'NO2', N'直流电压', N'直流电压', CAST(2300.000 AS Decimal(10, 3)), CAST(2700.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (378, N'XH', N'XHN2000B', N'NO2', N'自动零点', N'自动零点', CAST(0.000 AS Decimal(10, 3)), CAST(250.000 AS Decimal(10, 3)), N' ', N' ', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (453, N'XH', N'XHN2000B', N'NOx', N'NOx 截距', N'NOx 截距', CAST(-250.000 AS Decimal(10, 3)), CAST(250.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (451, N'XH', N'XHN2000B', N'NOx', N'NOx斜率 ', N'NOx斜率 ', CAST(0.700 AS Decimal(10, 3)), CAST(1.300 AS Decimal(10, 3)), N' ', N' ', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (452, N'XH', N'XHN2000B', N'NOx', N'NO截距', N'NO截距', CAST(-250.000 AS Decimal(10, 3)), CAST(250.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (450, N'XH', N'XHN2000B', N'NOx', N'NO斜率', N'NO斜率', CAST(0.700 AS Decimal(10, 3)), CAST(1.300 AS Decimal(10, 3)), N' ', N' ', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (444, N'XH', N'XHN2000B', N'NOx', N'PMT温度', N'PMT 温度', CAST(6.000 AS Decimal(10, 3)), CAST(8.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (439, N'XH', N'XHN2000B', N'NOx', N'PMT电压', N'PMT电压', CAST(0.000 AS Decimal(10, 3)), CAST(5000.000 AS Decimal(10, 3)), N'V', N'V', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (447, N'XH', N'XHN2000B', N'NOx', N'PMT高压', N'PMT高压', CAST(450.000 AS Decimal(10, 3)), CAST(900.000 AS Decimal(10, 3)), N'V', N'V', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (446, N'XH', N'XHN2000B', N'NOx', N'PMT电压', N'PMT信号', CAST(0.000 AS Decimal(10, 3)), CAST(5000.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (438, N'XH', N'XHN2000B', N'NOx', N'臭氧流量', N'臭氧流量', CAST(65.000 AS Decimal(10, 3)), CAST(95.000 AS Decimal(10, 3)), N'ml/min', N'ml/min', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (443, N'XH', N'XHN2000B', N'NOx', N'反应室温度', N'反应温度', CAST(49.000 AS Decimal(10, 3)), CAST(51.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (441, N'XH', N'XHN2000B', N'NOx', N'反应室压力', N'反应压力', CAST(13.000 AS Decimal(10, 3)), CAST(34.000 AS Decimal(10, 3)), N'kPa', N'kPa', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (445, N'XH', N'XHN2000B', N'NOx', N'机箱温度', N'机箱温度', CAST(5.000 AS Decimal(10, 3)), CAST(45.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (435, N'XH', N'XHN2000B', N'NOx', N'仪器量程', N'量程', CAST(-9999.000 AS Decimal(10, 3)), CAST(2.000 AS Decimal(10, 3)), N'μmol/mol', N'μmol/mol', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (442, N'XH', N'XHN2000B', N'NOx', N'转换器温度', N'钼炉温度', CAST(310.000 AS Decimal(10, 3)), CAST(320.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (436, N'XH', N'XHN2000B', N'NOx', N'稳定度', N'稳定度', CAST(0.000 AS Decimal(10, 3)), CAST(2.000 AS Decimal(10, 3)), N' ', N' ', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (437, N'XH', N'XHN2000B', N'NOx', N'样气流量', N'样气流量', CAST(450.000 AS Decimal(10, 3)), CAST(550.000 AS Decimal(10, 3)), N'ml/min', N'ml/min', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (440, N'XH', N'XHN2000B', N'NOx', N'样气压力', N'样气压力', CAST(84.000 AS Decimal(10, 3)), CAST(102.000 AS Decimal(10, 3)), N'kPa', N'kPa', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (448, N'XH', N'XHN2000B', N'NOx', N'直流电压', N'直流电压', CAST(2300.000 AS Decimal(10, 3)), CAST(2700.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (449, N'XH', N'XHN2000B', N'NOx', N'自动零点', N'自动零点', CAST(0.000 AS Decimal(10, 3)), CAST(250.000 AS Decimal(10, 3)), N' ', N' ', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (305, N'XH', N'XHOZ200B', N'O3', N'臭氧参比电压', N'臭氧参比电压', CAST(2500.000 AS Decimal(10, 3)), CAST(4700.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (306, N'XH', N'XHOZ200B', N'O3', N'臭氧测量电压', N'臭氧测量电压', CAST(2500.000 AS Decimal(10, 3)), CAST(4700.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (307, N'XH', N'XHOZ200B', N'O3', N'电源组件', N'电源组件', CAST(2300.000 AS Decimal(10, 3)), CAST(2700.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (309, N'XH', N'XHOZ200B', N'O3', N'机箱温度', N'机箱温度', CAST(-9999.000 AS Decimal(10, 3)), CAST(9999.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (301, N'XH', N'XHOZ200B', N'O3', N'截距', N'截距', CAST(-5.000 AS Decimal(10, 3)), CAST(5.000 AS Decimal(10, 3)), N'nmol/mol', N'nmol/mol', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (299, N'XH', N'XHOZ200B', N'O3', N'仪器量程', N'量程', CAST(0.000 AS Decimal(10, 3)), CAST(500.000 AS Decimal(10, 3)), N'nmol/mol', N'nmol/mol', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (302, N'XH', N'XHOZ200B', N'O3', N'稳定度', N'稳定度', CAST(0.000 AS Decimal(10, 3)), CAST(1.000 AS Decimal(10, 3)), N' ', N' ', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (311, N'XH', N'XHOZ200B', N'O3', N'限流孔温度', N'限流孔温度 ', CAST(47.000 AS Decimal(10, 3)), CAST(49.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (300, N'XH', N'XHOZ200B', N'O3', N'斜率', N'斜率', CAST(0.500 AS Decimal(10, 3)), CAST(1.500 AS Decimal(10, 3)), N' ', N' ', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (304, N'XH', N'XHOZ200B', N'O3', N'样气流量', N'样气流量', CAST(720.000 AS Decimal(10, 3)), CAST(880.000 AS Decimal(10, 3)), N'ml/min', N'ml/min', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (310, N'XH', N'XHOZ200B', N'O3', N'样气温度', N'样气温度', CAST(20.000 AS Decimal(10, 3)), CAST(45.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (303, N'XH', N'XHOZ200B', N'O3', N'样气压力', N'样气压力', CAST(60.000 AS Decimal(10, 3)), CAST(120.000 AS Decimal(10, 3)), N'kPa', N'kPa', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (308, N'XH', N'XHOZ200B', N'O3', N'紫外灯温度', N'紫外灯温度', CAST(51.900 AS Decimal(10, 3)), CAST(52.100 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (255, N'XH', N'XHS2000B', N'SO2', N'PMT温度', N'PMT 温度', CAST(6.000 AS Decimal(10, 3)), CAST(8.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (252, N'XH', N'XHS2000B', N'SO2', N'PMT电压', N'PMT电压', CAST(0.000 AS Decimal(10, 3)), CAST(5000.000 AS Decimal(10, 3)), N'V', N'V', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (258, N'XH', N'XHS2000B', N'SO2', N'PMT高压', N'PMT高压', CAST(450.000 AS Decimal(10, 3)), CAST(900.000 AS Decimal(10, 3)), N'V', N'V', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (257, N'XH', N'XHS2000B', N'SO2', N'PMT电压', N'PMT信号', CAST(0.000 AS Decimal(10, 3)), CAST(5000.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (263, N'XH', N'XHS2000B', N'SO2', N'截距', N'SO2截距', CAST(-9999.000 AS Decimal(10, 3)), CAST(250.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (262, N'XH', N'XHS2000B', N'SO2', N'斜率', N'SO2斜率', CAST(1.000 AS Decimal(10, 3)), CAST(0.300 AS Decimal(10, 3)), N' ', N' ', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (261, N'XH', N'XHS2000B', N'SO2', N'倍增管暗电流', N'倍增管暗电流', CAST(-50.000 AS Decimal(10, 3)), CAST(150.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (253, N'XH', N'XHS2000B', N'SO2', N'反应室压力', N'反应室压力', CAST(84.000 AS Decimal(10, 3)), CAST(102.000 AS Decimal(10, 3)), N'kPa', N'kPa', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (254, N'XH', N'XHS2000B', N'SO2', N'反应室温度', N'反应温度', CAST(49.000 AS Decimal(10, 3)), CAST(51.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (260, N'XH', N'XHS2000B', N'SO2', N'PMT暗电流', N'光电管暗电流', CAST(-50.000 AS Decimal(10, 3)), CAST(150.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (256, N'XH', N'XHS2000B', N'SO2', N'机箱温度', N'机箱温度', CAST(0.000 AS Decimal(10, 3)), CAST(45.000 AS Decimal(10, 3)), N'℃', N'℃', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (249, N'XH', N'XHS2000B', N'SO2', N'仪器量程', N'量程', CAST(-9999.000 AS Decimal(10, 3)), CAST(0.500 AS Decimal(10, 3)), N'μmol/mol', N'μmol/mol', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (250, N'XH', N'XHS2000B', N'SO2', N'稳定度', N'稳定度', CAST(0.000 AS Decimal(10, 3)), CAST(0.030 AS Decimal(10, 3)), N'', N'', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (251, N'XH', N'XHS2000B', N'SO2', N'样气流量', N'样气流量', CAST(555.000 AS Decimal(10, 3)), CAST(715.000 AS Decimal(10, 3)), N'ml/min', N'ml/min', CAST(-999.000 AS Decimal(10, 3)), 1, 1)
INSERT [InsBrandInfo] ([ID], [Brand], [Series], [PollutantCode], [ShowName], [StatusName], [LowLimit], [TopLimit], [OriUnit], [TargetUnit], [ConvertUnit], [IsShow], [IsStorage]) VALUES (259, N'XH', N'XHS2000B', N'SO2', N'直流电压', N'直流电压', CAST(2300.000 AS Decimal(10, 3)), CAST(2700.000 AS Decimal(10, 3)), N'mV', N'mV', CAST(-999.000 AS Decimal(10, 3)), 0, 1)
SET IDENTITY_INSERT [InsBrandInfo] OFF
