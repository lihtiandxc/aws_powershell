#author : lihtian@gmail.com

$accessKeyInput = Read-Host -Prompt "Paste AWS access key here. Leave blank to use the previous one"
$secretKeyInput = Read-Host -Prompt "Paste AWS secret access key here. Leave blank to use the previous one"
    
If(![String]::IsNullOrEmpty($accessKeyInput)) 
{
    $accessKey = $accessKeyInput
}

If(![String]::IsNullOrEmpty($secretKeyInput)) 
{
    $secretKey = $secretKeyInput
}

$CurrentFolder = Split-Path -Parent $PSCommandPath
$RandomName = [DateTime]::Now.ToString().Replace(":", "_").Replace("/", "_").Replace(" ", "_")
$OutputFilePath = "$CurrentFolder\AwsRdsSnapshot-$RandomName.txt"

$region = "us-east-1"

Import-Module AWSPowerShell
Set-AWSCredential -AccessKey  $accessKey  -SecretKey $secretKey -StoreAs my_profile
Set-AWSCredential -ProfileName my_profile
Set-DefaultAWSRegion -Region $region

If(![System.IO.File]::Exists($OutputFilePath))
{
    $OutputFile = [System.IO.File]::CreateText($OutputFilePath)
}


Write-host "Processing region $region" -ForegroundColor Magenta

# Write header in output file
$RDSItems = @(
                "Region"
                "AllocatedStorage",
                "DBSnapShotArn",
                "AvailabilityZone",
                "DBInstanceIdentifier",
                "DBSnapshotIdentifier",
                "SnapshotCreateTime",
                "SnapshotCreateTime in Month",
                "SnapshotCreateTime in DayOfWeek",
                "SnapshotCreateTime in Hour",
                "SnapshotCreateTime in Minute",
                "MasterUsername",
                "Encrypted",
                "Iops",
                "PercentProgress",
                "SnapshotType",
                "StorageType",
                "VpcId"
             )

Foreach ($RDSItem in $RDSItems){

    $OutputFile.Write($RDSItem)
    $OutputFile.Write("`t")

}
    $OutputFile.Write("`n")


    Write-Host " -> Retrieving RDS Snapshot list" -ForegroundColor Cyan

(get-rdsdbsnapshot -region $_.region) | %{

    $RdsSnapshot = $_
         
    $RdsSnapshotArray = @(
                            $region,
                            $_.AllocatedStorage,
                            $_.DBSnapshotArn,
                            $_.AvailabilityZone,
                            $_.DBInstanceIdentifier,
                            $_.DBSnapshotIdentifier,
                            $_.SnapshotCreateTime,
                            $_.SnapshotCreateTime.Month,
                            $_.SnapshotCreateTime.DayOfWeek,
                            $_.SnapshotCreateTime.Hour,
                            $_.SnapshotCreateTime.Minute,
                            $_.MasterUsername,
                            $_.Encrypted,
                            $_.Iops,
                            $_.PercentProgress,
                            $_.SnapshotType,
                            $_.StorageType,
                            $_.VpcId
                        )


    #$I = 0
    $I = $RdsSnapshotArray.Count - $RdsSnapshotArray.Count

    While ($I -lt $RdsSnapshotArray.Count) {

        $OutputFile.Write($RdsSnapshotArray[$I])
        $OutputFile.Write("`t")
        $I = $I + 1
    
    }
        $OutputFile.Write("`n")

}

$OutputFile.Close()

Write-Host "Done" -ForegroundColor Green
