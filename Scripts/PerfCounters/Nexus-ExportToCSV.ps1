#$Counters = Import-Counter -Path C:\Temp\_testBLG\*.BLG -ListSet *

#$SQLCounters = $Counters.Counter 
$ServerName  = "Home-Srv\SQL2019"
$DBName = "alfa"
$OutFilePath = 'C:\output\blg\'
Get-Date
$ConnectionString      = "Data Source=$($Servername);Database =$DBName;User id=sa;Password=P@ssw0rd;Network Library=DBMSSOCN;Connect Timeout=3"
$Connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
$command = New-Object system.Data.SqlClient.SqlCommand($Connection)
$command.Connection = $Connection
$command.CommandTimeout = '300'

$command.CommandText = "EXEC GetWaitStats"
$Results = New-Object System.Data.DataTable
$Connection.Open()
$Reader = $Command.ExecuteReader()
$Results.Load($Reader)
$Connection.Close()

$Results | Export-Csv -Path $($OutFilePath + "Waits_" + $DBName + ".csv") -NoTypeInformation

$command.CommandText = "EXEC GetFileStats"
$Results = New-Object System.Data.DataTable
$Connection.Open()
$Reader = $Command.ExecuteReader()
$Results.Load($Reader)
$Connection.Close()

$Results | Export-Csv -Path $($OutFilePath + "FileIO" + $DBName + ".csv") -NoTypeInformation

 