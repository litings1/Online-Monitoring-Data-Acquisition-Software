IF (select object_id('ResendCommand')) is not null  AND   COL_LENGTH('ResendCommand', 'Destination') IS NULL  ALTER TABLE [ResendCommand] ADD [Destination] [tinyint] NULL
IF (select object_id('QC_Arrange')) is not null  AND COL_LENGTH('QC_Arrange', 'record_time') IS NULL  ALTER TABLE [QC_Arrange] ADD record_time datetime not null
IF (select object_id('ManualQCEvent')) is not null  AND  COL_LENGTH('ManualQCEvent', 'PollutantCode') IS NOT NULL ALTER TABLE [ManualQCEvent] ALTER column PollutantCode varchar(20) not null
IF (select object_id('QC_History')) is not null  AND  COL_LENGTH('QC_History', 'recorde_time') IS NOT NULL exec sp_rename '[QC_History].[recorde_time]','record_time'
IF (select object_id('QC_History')) is not null  AND  COL_LENGTH('QC_History', 'document_name') IS NOT NULL ALTER TABLE [QC_History] ALTER column document_name varchar(200)

DECLARE @SQL VARCHAR(MAX),@year VARCHAR(10),@Nextyear VARCHAR(10) ,@now VARCHAR(50) ,@next VARCHAR(50)
SELECT   @year=YEAR(GETDATE()),
		 @nextyear=YEAR(GETDATE())+1,
		 @now= CONVERT(VARCHAR(10), YEAR(GETDATE())) + '_'+ CONVERT(VARCHAR(10), MONTH(GETDATE())),
		 @next= CONVERT(VARCHAR(10), YEAR(DATEADD(MONTH, 1,GETDATE()))) + '_'+ CONVERT(VARCHAR(10), MONTH(DATEADD(MONTH, 1,GETDATE())))
SET @SQL=
'
if (select object_id(''Ins_1h_' + @year +  ''')) is not null and  COL_LENGTH(''Ins_1h_' + @year +  ''', ''StatusName'') IS NOT NULL begin ALTER TABLE [Ins_1h_' + @year +  '] ALTER column [StatusName] varchar(50) not null end
if (select object_id(''Ins_Live_' + @year +  ''')) is not null and  COL_LENGTH(''Ins_Live_' + @year +  ''', ''StatusName'') IS NOT NULL begin ALTER TABLE [Ins_Live_' + @year +  '] ALTER column [StatusName] varchar(50) not null end
if (select object_id(''Ins_1h_' + @year +  ''')) is not null and  COL_LENGTH(''Ins_1h_' + @year +  ''', ''Units'') IS NULL begin ALTER table Ins_1h_' + @year +  ' ADD Units varchar(20) NULL end
if (select object_id(''Ins_Live_' + @year +  ''')) is not null and  COL_LENGTH(''Ins_Live_' + @year +  ''', ''Units'') IS NULL begin ALTER table Ins_Live_' + @year +  ' ADD Units varchar(20) NULL end
if (select object_id(''Air_1d_api_' + @year +  '_Src'')) is not null and  COL_LENGTH(''Air_1d_api_' + @year +  '_Src'', ''ConditionType'') IS NULL begin ALTER table Air_1d_api_' + @year +  '_Src ADD ConditionType   int   not null default(0) end
if (select object_id(''Air_1d_aqi_' + @year +  '_Src'')) is not null and  COL_LENGTH(''Air_1d_aqi_' + @year +  '_Src'', ''ConditionType'') IS NULL begin ALTER table Air_1d_aqi_' + @year +  '_Src ADD ConditionType   int   not null default(0) end
if (select object_id(''Air_1h_' + @year +  '_Src'')) is not null and  COL_LENGTH(''Air_1h_' + @year +  '_Src'', ''ConditionType'') IS NULL begin ALTER table Air_1h_' + @year +  '_Src ADD ConditionType   int   not null default(0) end
if (select object_id(''Air_30s_' + @year +  '_Src'')) is not null and  COL_LENGTH(''Air_30s_' + @year +  '_Src'', ''ConditionType'') IS NULL begin ALTER table Air_30s_' + @year +  '_Src ADD ConditionType   int   not null default(0) end

if (select object_id(''Ins_1h_' + @Nextyear +  ''')) is not null and  COL_LENGTH(''Ins_1h_' + @Nextyear +  ''', ''StatusName'') IS NOT NULL begin ALTER TABLE [Ins_1h_' + @Nextyear +  '] ALTER column [StatusName] varchar(50) not null end
if (select object_id(''Ins_Live_' + @Nextyear +  ''')) is not null and  COL_LENGTH(''Ins_Live_' + @Nextyear +  ''', ''StatusName'') IS NOT NULL begin ALTER TABLE [Ins_Live_' + @Nextyear +  '] ALTER column [StatusName] varchar(50) not null end
if (select object_id(''Ins_1h_' + @Nextyear +  ''')) is not null and  COL_LENGTH(''Ins_1h_' + @Nextyear +  ''', ''Units'') IS NULL begin ALTER table Ins_1h_' + @Nextyear +  ' ADD Units varchar(20) NULL end
if (select object_id(''Ins_Live_' + @Nextyear +  ''')) is not null and  COL_LENGTH(''Ins_Live_' + @Nextyear +  ''', ''Units'') IS NULL begin ALTER table Ins_Live_' + @Nextyear +  ' ADD Units varchar(20) NULL end
if (select object_id(''Air_1d_api_' + @Nextyear +  '_Src'')) is not null and  COL_LENGTH(''Air_1d_api_' + @Nextyear +  '_Src'', ''ConditionType'') IS NULL begin ALTER table Air_1d_api_' + @Nextyear +  '_Src ADD ConditionType   int   not null default(0) end
if (select object_id(''Air_1d_aqi_' + @Nextyear +  '_Src'')) is not null and  COL_LENGTH(''Air_1d_aqi_' + @Nextyear +  '_Src'', ''ConditionType'') IS NULL begin ALTER table Air_1d_aqi_' + @Nextyear +  '_Src ADD ConditionType   int   not null default(0) end
if (select object_id(''Air_1h_' + @Nextyear +  '_Src'')) is not null and  COL_LENGTH(''Air_1h_' + @Nextyear +  '_Src'', ''ConditionType'') IS NULL begin ALTER table Air_1h_' + @Nextyear +  '_Src ADD ConditionType   int   not null default(0) end
if (select object_id(''Air_30s_' + @Nextyear +  '_Src'')) is not null and  COL_LENGTH(''Air_30s_' + @Nextyear +  '_Src'', ''ConditionType'') IS NULL begin ALTER table Air_30s_' + @Nextyear +  '_Src ADD ConditionType   int   not null default(0) end

if (select object_id(''Air_1m_' + @now +  '_Src'')) is not null and  COL_LENGTH(''Air_1m_' + @now +  '_Src'', ''ConditionType'') IS NULL begin ALTER table Air_1m_' + @now +  '_Src ADD ConditionType   int   not null default(0) end
if (select object_id(''Air_1m_' + @next +  '_Src'')) is not null and  COL_LENGTH(''Air_1m_' + @next +  '_Src'', ''ConditionType'') IS NULL begin ALTER table Air_1m_' + @next +  '_Src ADD ConditionType   int   not null default(0) end
if (select object_id(''Air_5m_' + @now +  '_Src'')) is not null and  COL_LENGTH(''Air_5m_' + @now +  '_Src'', ''ConditionType'') IS NULL begin ALTER table Air_5m_' + @now +  '_Src ADD ConditionType   int   not null default(0) end
if (select object_id(''Air_5m_' + @next +  '_Src'')) is not null and  COL_LENGTH(''Air_5m_' + @next +  '_Src'', ''ConditionType'') IS NULL begin ALTER table Air_5m_' + @next +  '_Src ADD ConditionType   int   not null default(0) end
if (select object_id(''Air_2m_' + @now +  '_Src'')) is not null and  COL_LENGTH(''Air_2m_' + @now +  '_Src'', ''ConditionType'') IS NULL begin ALTER table Air_2m_' + @now +  '_Src ADD ConditionType   int   not null default(0) end
if (select object_id(''Air_2m_' + @next +  '_Src'')) is not null and  COL_LENGTH(''Air_2m_' + @next +  '_Src'', ''ConditionType'') IS NULL begin ALTER table Air_2m_' + @next +  '_Src ADD ConditionType   int   not null default(0) end
if (select object_id(''Air_10m_' + @now +  '_Src'')) is not null and  COL_LENGTH(''Air_10m_' + @now +  '_Src'', ''ConditionType'') IS NULL begin ALTER table Air_10m_' + @now +  '_Src ADD ConditionType   int   not null default(0) end
if (select object_id(''Air_10m_' + @next +  '_Src'')) is not null and  COL_LENGTH(''Air_10m_' + @next +  '_Src'', ''ConditionType'') IS NULL begin ALTER table Air_10m_' + @next +  '_Src ADD ConditionType   int   not null default(0) end
'
EXEC  (@SQL)
