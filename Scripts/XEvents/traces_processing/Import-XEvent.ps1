$SharedPath = "C:\Program Files\Microsoft SQL Server\150\Shared";
$SqlInstanceName = "HOME-SRV\SQL2019"; #Имя SQL сервера
$DatabaseName = "Xevents" # Имя БД
$TableName = "_Test" # Имя таблицы (создается автоматически, так же содается CCI)
$DestPath ="C:\path\*.xel" # Путь к файламXEvents

$xeCore = [System.IO.Path]::Combine($SharedPath, "Microsoft.SqlServer.XE.Core.dll");
$xeLinq = [System.IO.Path]::Combine($SharedPath, "Microsoft.SqlServer.XEvent.Linq.dll");
Add-Type -Path $xeLinq;

if( [System.IO.File]::Exists($xeCore) )
{
    Add-Type -Path $xeCore;
}


# create target table
$connectionString = "Data Source=$SqlInstanceName;Initial Catalog=$DatabaseName;Integrated Security=SSPI"
$connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
$command = New-Object System.Data.SqlClient.SqlCommand("
if OBJECT_ID('$TableName') IS NOT NULL DROP TABLE $TableName
CREATE TABLE $TableName(
	[Event_TimeStamp] [datetimeoffset] NULL,
	[activity_id] UNIQUEIDENTIFIER NULL,
    [event_sequence] [int] NULL,
    [activity_id_xfer]  UNIQUEIDENTIFIER NULL,
    [event_sequence_xfer] [int] NULL,
	[Name] [nvarchar](50) NULL,
	[session_id] [int] NULL,
	[client_app_name] [nvarchar](300) NULL,
    [client_hostname] [nvarchar](300) NULL,
	[username] [nvarchar](300) NULL,
	[database_name] [sysname] NULL,
	[database_id] [int] NULL,
    [source_database_id] [int] NULL,
	[object_id] [int] NULL,
	[object_name] [sysname] NULL,
	[object_type] [nvarchar](100) NULL,
	[offset] [int] NULL,
	[offset_end] [int] NULL,
	[nest_level] [int] NULL,
	[CPU] [bigint] NULL,
	[Duration] [bigint] NULL,
	[physical_reads] [bigint] NULL,
	[logical_reads] [bigint] NULL,
	[writes] [bigint] NULL,
    [spills] [INT] NULL,
	[row_count] [bigint] NULL,
	[statement] [nvarchar](max) NULL,
	[batch_text] [nvarchar](max) NULL,
	[SQLText] [nvarchar](max) NULL,
	[plan_handle] VARBINARY(MAX) NULL,
	[query_hash_signed] [bigint] NULL,
	[query_plan_hash_signed] [bigint] NULL,
    [result] nvarchar(100),
    
   -- ,estimated_rows INT,	
   -- estimated_cost INT,	
   -- serial_ideal_memory_kb INT,	
    --requested_memory_kb	 INT,
   -- used_memory_kb	 INT,
    --ideal_memory_kb	 INT,
    --granted_memory_kb  INT,	
    --dop	 INT,
   -- showplan_xml nnvarchar(MAX),
    wait_type nvarchar(500),
    wait_resource nvarchar(1000),
    signal_duration BIGINT

	--,[statistics_list] [nvarchar](4000) NULL,
	--[index_id] [bigint] NULL,
	--[status] [nvarchar](4000) NULL,
	--[success] [bit] NULL,
	--[last_error] [bigint] NULL,
	--[job_type] [nvarchar](4000) NULL 
    

) ON [PRIMARY]
 CREATE CLUSTERED COLUMNSTORE INDEX [CCSI_$TableName] ON [dbo].[$TableName] WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0) ON [PRIMARY]
", $connection)
$connection.Open()
 [void]$command.ExecuteNonQuery()
$connection.Close()

# data table for SqlBulkCopy
$dt = New-Object System.Data.DataTable

#[void]$dt.Columns.Add("event_name", [System.Type]::GetType("System.String"))
#$dt.Columns["event_name"].MaxLength = 256
#[void]$dt.Columns.Add("timestamp", [System.Type]::GetType("System.DateTimeOffset"))
#[void]$dt.Columns.Add("statement", [System.Type]::GetType("System.String"))
#[void]$dt.Columns.Add("username", [System.Type]::GetType("System.String"))
#$dt.Columns["username"].MaxLength = 128
#$dt.Columns["statement"].MaxLength = -1


[void]$dt.Columns.Add("timestamp", [System.Type]::GetType("System.DateTimeOffset"))
[void]$dt.Columns.Add("attach_activity_id", [System.Type]::GetType("System.Guid"))
[void]$dt.Columns.Add("attach_activity_id_seq", [System.Type]::GetType("System.Int32"))
[void]$dt.Columns.Add("attach_activity_id_xfer", [System.Type]::GetType("System.Guid"))	
[void]$dt.Columns.Add("attach_activity_id_xfer_seq", [System.Type]::GetType("System.Int32"))

[void]$dt.Columns.Add("event_name", [System.Type]::GetType("System.String"))

[void]$dt.Columns.Add("session_id", [System.Type]::GetType("System.Int64"))
[void]$dt.Columns.Add("client_app_name", [System.Type]::GetType("System.String"))
[void]$dt.Columns.Add("client_hostname", [System.Type]::GetType("System.String"))
[void]$dt.Columns.Add("username", [System.Type]::GetType("System.String"))
[void]$dt.Columns.Add("database_name", [System.Type]::GetType("System.String"))
[void]$dt.Columns.Add("database_id", [System.Type]::GetType("System.Int32"))
[void]$dt.Columns.Add("source_database_id", [System.Type]::GetType("System.Int32"))
[void]$dt.Columns.Add("object_id", [System.Type]::GetType("System.Int64"))  
[void]$dt.Columns.Add("object_name", [System.Type]::GetType("System.String"))
[void]$dt.Columns.Add("object_type", [System.Type]::GetType("System.String"))
[void]$dt.Columns.Add("offset", [System.Type]::GetType("System.Int64"))
[void]$dt.Columns.Add("offset_end", [System.Type]::GetType("System.Int64"))
[void]$dt.Columns.Add("nest_level", [System.Type]::GetType("System.Int64"))
[void]$dt.Columns.Add("cpu_time", [System.Type]::GetType("System.Int64"))
[void]$dt.Columns.Add("duration", [System.Type]::GetType("System.Int64"))
[void]$dt.Columns.Add("physical_reads", [System.Type]::GetType("System.Int64"))
[void]$dt.Columns.Add("logical_reads", [System.Type]::GetType("System.Int64"))
[void]$dt.Columns.Add("writes", [System.Type]::GetType("System.Int64"))
[void]$dt.Columns.Add("Spills", [System.Type]::GetType("System.Int64"))
[void]$dt.Columns.Add("row_count", [System.Type]::GetType("System.Int64"))
[void]$dt.Columns.Add("statement", [System.Type]::GetType("System.String"))
[void]$dt.Columns.Add("batch_text", [System.Type]::GetType("System.String"))
[void]$dt.Columns.Add("sql_text", [System.Type]::GetType("System.String"))
[void]$dt.Columns.Add("plan_handle", [System.Type]::GetType("System.Byte[]"))
[void]$dt.Columns.Add("query_hash_signed", [System.Type]::GetType("System.Int64"))
[void]$dt.Columns.Add("query_plan_hash_signed", [System.Type]::GetType("System.Int64"))
[void]$dt.Columns.Add("result", [System.Type]::GetType("System.String"))

#[void]$dt.Columns.Add("estimated_rows", [System.Type]::GetType("System.Int64"))
#[void]$dt.Columns.Add("estimated_cost", [System.Type]::GetType("System.Int64"))
#[void]$dt.Columns.Add("serial_ideal_memory_kb", [System.Type]::GetType("System.Int64"))
#[void]$dt.Columns.Add("requested_memory_kb", [System.Type]::GetType("System.Int64"))
#[void]$dt.Columns.Add("used_memory_kb", [System.Type]::GetType("System.Int64"))
#[void]$dt.Columns.Add("ideal_memory_kb", [System.Type]::GetType("System.Int64"))
#[void]$dt.Columns.Add("granted_memory_kb", [System.Type]::GetType("System.Int64"))
#[void]$dt.Columns.Add("dop", [System.Type]::GetType("System.Int64"))
#[void]$dt.Columns.Add("showplan_xml", [System.Type]::GetType("System.String"))

[void]$dt.Columns.Add("wait_type", [System.Type]::GetType("System.String"))
[void]$dt.Columns.Add("wait_resource", [System.Type]::GetType("System.String"))
[void]$dt.Columns.Add("signal_duration", [System.Type]::GetType("System.Int64"))

 


# Stats info

# [void]$dt.Columns.Add("statistics_list", [System.Type]::GetType("System.String"))
# [void]$dt.Columns.Add("index_id", [System.Type]::GetType("System.Int32"))
# [void]$dt.Columns.Add("status", [System.Type]::GetType("System.String"))
# [void]$dt.Columns.Add("success", [System.Type]::GetType("System.Boolean"))
# [void]$dt.Columns.Add("last_error", [System.Type]::GetType("System.Int64"))
# [void]$dt.Columns.Add("job_type", [System.Type]::GetType("System.String"))


$StartTime = Get-Date -Format "yyyy-MM-dd hh:mm:ss"
Write-Host "Starting at: " + $StartTime

$events = new-object Microsoft.SqlServer.XEvent.Linq.QueryableXEventData($DestPath)

# import XE events from file(s)
$bcp = New-Object System.Data.SqlClient.SqlBulkCopy($connectionString)
$bcp.DestinationTableName = $TableName
$eventCount = 0
foreach($event in $events) {
    $eventCount += 1
    
    $row = $dt.NewRow()
    $dt.Rows.Add($row)
  #  $row["event_name"] = $event.Name
  #  $row["timestamp"] = $event.Timestamp
#    $row["statement"] = $event.Fields["statement"].Value
#    $row["username"] = $event.Actions["username"].Value

    $row["timestamp"] = $event.Timestamp
    $row["attach_activity_id"] =  $event.Actions["attach_activity_id"].Value.id
    $row["attach_activity_id_seq"] = $event.Actions["attach_activity_id"].Value.Sequence
    $row["event_name"] = $event.Name

    #if($event.Actions["attach_activity_id"].Value -eq $null) {$row["attach_activity_id"] = [DBNull]::Value} else  {$row["attach_activity_id"] = $event.Actions["attach_activity_id"].Value}


    #if($event.Actions["attach_activity_id_seq"].Value -eq $null) {$row["attach_activity_id_seq"] = [DBNull]::Value} else  {$row["attach_activity_id_seq"] = $event.Actions["attach_activity_id_seq"].Value}

    if($event.Actions["attach_activity_id_xfer"].Value.id -eq $null) {$row["attach_activity_id_xfer"] = [DBNull]::Value} else  {$row["attach_activity_id_xfer"] = $event.Actions["attach_activity_id_xfer"].Value.id}
    if($event.Actions["attach_activity_id_xfer"].Value.Sequence -eq $null) {$row["attach_activity_id_xfer_seq"] = [DBNull]::Value} else  {$row["attach_activity_id_xfer_seq"] = $event.Actions["attach_activity_id_xfer"].Value.Sequence}


    if($event.Actions["session_id"].Value -eq $null) {$row["session_id"] = [DBNull]::Value} else  {$row["session_id"] = $event.Actions["session_id"].Value}
    if($event.Actions["client_app_name"].Value -eq $null) {$row["client_app_name"] = [DBNull]::Value} else  {$row["client_app_name"] = $event.Actions["client_app_name"].Value}
    if($event.Actions["client_hostname"].Value -eq $null) {$row["client_hostname"] = [DBNull]::Value} else  {$row["client_hostname"] = $event.Actions["client_hostname"].Value}
    if($event.Actions["username"].Value -eq $null  ) {$row["username"] = [DBNull]::Value} else  {$row["username"] = $event.Actions["username"].Value}
    if($event.Actions["database_name"].Value -eq $null  ) {$row["database_name"] = [DBNull]::Value} else  {$row["database_name"] = $event.Actions["database_name"].Value}
    if($event.Actions["database_id"].Value -eq $null  ) {$row["database_id"] = [DBNull]::Value} else  {$row["database_id"] = $event.Actions["database_id"].Value}
    if($event.Fields["source_database_id"].Value -eq $null  ) {$row["source_database_id"] = [DBNull]::Value} else  {$row["source_database_id"] = $event.Fields["source_database_id"].Value}
    if($event.Fields["object_id"].Value -eq $null  ) {$row["object_id"] = [DBNull]::Value} else  {$row["object_id"] = $event.Fields["object_id"].Value}
    if($event.Fields["object_name"].Value -eq $null  ) {$row["object_name"] = [DBNull]::Value} else  {$row["object_name"] = $event.Fields["object_name"].Value}
    if($event.Fields["object_type"].Value -eq $null  ) {$row["object_type"] = [DBNull]::Value} else  {$row["object_type"] = $event.Fields["object_type"].Value}
    if($event.Fields["offset"].Value -eq $null  ) {$row["offset"] = [DBNull]::Value} else  {$row["offset"] = $event.Fields["offset"].Value}
    if($event.Fields["offset_end"].Value -eq $null  ) {$row["offset_end"] = [DBnull]::Value} else  {$row["offset_end"] = $event.Fields["offset_end"].Value}
    if($event.Fields["nest_level"].Value -eq $null  ) {$row["nest_level"] = [DBNull]::Value} else  {$row["nest_level"] = $event.Fields["nest_level"].Value}
    if($event.Fields["cpu_time"].Value -eq $null  ) {$row["cpu_time"] = [dbnull]::Value} else  {$row["cpu_time"] = $event.Fields["cpu_time"].Value}
    if($event.Fields["duration"].Value -eq $null  ) {$row["duration"] = [DBNull]::Value} else  {$row["duration"] = $event.Fields["duration"].Value}
    if($event.Fields["physical_reads"].Value -eq $null  ) {$row["physical_reads"] = [DBNull]::Value} else  {$row["physical_reads"] = $event.Fields["physical_reads"].Value}
    if($event.Fields["logical_reads"].Value -eq $null  ) {$row["logical_reads"] = [DBNull]::Value} else  {$row["logical_reads"] = $event.Fields["logical_reads"].Value}
    if($event.Fields["writes"].Value -eq $null  ) {$row["writes"] = [DBNull]::Value} else  {$row["writes"] = $event.Fields["writes"].Value}
    if($event.Fields["spills"].Value -eq $null  ) {$row["spills"] = [DBNull]::Value} else  {$row["spills"] = $event.Fields["spills"].Value}
    if($event.Fields["row_count"].Value -eq $null  ) {$row["row_count"] = [DBNull]::Value} else  {$row["row_count"] = $event.Fields["row_count"].Value}
    if($event.Fields["statement"].Value -eq $null  ) {$row["statement"] = [DBNull]::Value} else  {$row["statement"] = $event.Fields["statement"].Value}
    if($event.Fields["batch_text"].Value -eq $null ) {$row["batch_text"] = [DBNull]::Value} else  {$row["batch_text"] = $event.Fields["batch_text"].Value}
    if($event.Actions["sql_text"].Value -eq $null  ) {$row["sql_text"] = [DBNull]::Value} else  {$row["sql_text"] = $event.Actions["sql_text"].Value}
    if($event.Actions["plan_handle"].Value -eq $null  ) {$row["plan_handle"] = [DBNull]::Value} else  {$row["plan_handle"] = $event.Actions["plan_handle"].Value}
    if($event.Actions["query_hash_signed"].Value -eq $null  ) {$row["query_hash_signed"] = [DBNull]::Value} else  {$row["query_hash_signed"] = $event.Actions["query_hash_signed"].Value}
    if($event.Actions["query_plan_hash_signed"].Value -eq $null  ) {$row["query_plan_hash_signed"] = [DBNull]::Value} else  {$row["query_plan_hash_signed"] = $event.Actions["query_plan_hash_signed"].Value}
    if($event.Fields["result"].Value -eq $null  ) {$row["result"] = [DBNull]::Value} else  {$row["result"] = $event.Fields["result"].Value}

    #if($event.Fields["estimated_rows"].Value -eq $null  ) {$row["estimated_rows"] = [DBNull]::Value} else  {$row["estimated_rows"] = $event.Fields["estimated_rows"].Value}
    #if($event.Fields["estimated_cost"].Value -eq $null  ) {$row["estimated_cost"] = [DBNull]::Value} else  {$row["estimated_cost"] = $event.Fields["estimated_cost"].Value}
    #if($event.Fields["serial_ideal_memory_kb"].Value -eq $null  ) {$row["serial_ideal_memory_kb"] = [DBNull]::Value} else  {$row["serial_ideal_memory_kb"] = $event.Fields["serial_ideal_memory_kb"].Value}
    #if($event.Fields["requested_memory_kb"].Value -eq $null  ) {$row["requested_memory_kb"] = [DBNull]::Value} else  {$row["requested_memory_kb"] = $event.Fields["requested_memory_kb"].Value}
    #if($event.Fields["used_memory_kb"].Value -eq $null  ) {$row["used_memory_kb"] = [DBNull]::Value} else  {$row["used_memory_kb"] = $event.Fields["used_memory_kb"].Value}
    #if($event.Fields["ideal_memory_kb"].Value -eq $null  ) {$row["ideal_memory_kb"] = [DBNull]::Value} else  {$row["ideal_memory_kb"] = $event.Fields["ideal_memory_kb"].Value}
    #if($event.Fields["granted_memory_kb"].Value -eq $null  ) {$row["granted_memory_kb"] = [DBNull]::Value} else  {$row["granted_memory_kb"] = $event.Fields["granted_memory_kb"].Value}
    #if($event.Fields["dop"].Value -eq $null  ) {$row["dop"] = [DBNull]::Value} else  {$row["dop"] = $event.Fields["dop"].Value}
    #if($event.Fields["showplan_xml"].Value -eq $null  ) {$row["showplan_xml"] = [DBNull]::Value} else  {$row["showplan_xml"] = $event.Fields["showplan_xml"].Value}
    #
    if($event.Fields["wait_type"].Value.Value -eq $null  ) {$row["wait_type"] = [DBNull]::Value} else  {$row["wait_type"] = $event.Fields["wait_type"].Value.Value}
    if($event.Fields["wait_resource"].Value -eq $null  ) {$row["wait_resource"] = [DBNull]::Value} else  {$row["wait_resource"] = $event.Fields["wait_resource"].Value}
    if($event.Fields["signal_duration"].Value -eq $null  ) {$row["signal_duration"] = [DBNull]::Value} else  {$row["signal_duration"] = $event.Fields["signal_duration"].Value}
 	
 	
 	
 	
 	
 	
 	
  

 
  #  if($event.Fields["statistics_list"].Value -eq $null  ) {$row["statistics_list"] = [DBNull]::Value} else  {$row["statistics_list"] = $event.Fields["statistics_list"].Value}
  #  if($event.Fields["index_id"].Value -eq $null  ) {$row["index_id"] = [DBNull]::Value} else  {$row["index_id"] = $event.Fields["index_id"].Value}
  #  if($event.Fields["status"].Value -eq $null  ) {$row["status"] = [DBNull]::Value} else  {$row["status"] = $event.Fields["status"].Value}
  #  if($event.Fields["success"].Value -eq $null  ) {$row["success"] = [DBNull]::Value} else  {$row["success"] = $event.Fields["success"].Value}
  #  if($event.Fields["last_error"].Value -eq $null  ) {$row["last_error"] = [DBNull]::Value} else  {$row["last_error"] = $event.Fields["last_error"].Value}
  #  if($event.Fields["job_type"].Value -eq $null  ) {$row["job_type"] = [DBNull]::Value} else  {$row["job_type"] = $event.Fields["job_type"].Value}


    if($eventCount % 10000 -eq 0) {
        $bcp.WriteToServer($dt)
        $dt.Rows.Clear()
        Write-Host $eventCount
    }
}
$bcp.WriteToServer($dt) # write last batch
Write-Host "$eventCount records imported"

$ET = (Get-Date -Format "yyyy-MM-dd hh:mm:ss")
Write-Host "Finished at: "  $ET
$Duration = (NEW-TIMESPAN –Start $StartTime –End $ET).TotalMinutes
Write-Host "Duration: "  $Duration
