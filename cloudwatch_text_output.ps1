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
$OutputFilePath = "$CurrentFolder\Cloudtrail-$RandomName.csv"

Import-Module AWSPowerShell
Set-AWSCredential -AccessKey  $accessKey  -SecretKey $secretKey -StoreAs my_profile
Set-AWSCredential -ProfileName my_profile
$region = "ap-southeast-1"
#$region = "us-east-1"
Set-DefaultAWSRegion -Region $region

If(![System.IO.File]::Exists($OutputFilePath))
{
    $OutputFile = [System.IO.File]::CreateText($OutputFilePath)
}

Write-host "Processing region $region" -ForegroundColor Magenta

# Write header in output file


    $OutputFile.Write( "Security Group" )
    $OutputFile.Write("`t")
    $OutputFile.Write( "Event ID" )
    $OutputFile.Write("`t")
    $OutputFile.Write( "Event time" )
    $OutputFile.Write("`t")
    $OutputFile.Write( "User name" )
    $OutputFile.Write("`t")
    $OutputFile.Write( "Event name" )
    $OutputFile.Write("`t")
    $OutputFile.Write( "Resource type" )
    $OutputFile.Write("`t")
    $OutputFile.Write( "Resource name" )
    $OutputFile.Write("`t")
    $OutputFile.Write( "AWS access key" )
    $OutputFile.Write("`t")
    $OutputFile.Write( "AWS region" )
    $OutputFile.Write("`t")
    $OutputFile.Write( "Source IP address" )
    $OutputFile.Write("`t")
    $OutputFile.Write( "Resource" )
    $OutputFile.Write("`t")
    $OutputFile.Write("`n")
    
$nextToken = $null
do
{   
    Find-CTEvent -NextToken $nextToken | %{
    

    $FCTeach = $_
    $FCTEvent = $FCTeach.CloudTrailEvent.Replace("`",`"","$").Split("$").Replace("{`"","").Replace("`"}","")


    $CTSourceIPAddressRaw = $FCTEvent | Select-String -Pattern "sourceIPAddress" -CaseSensitive
    If(![String]::IsNullOrEmpty($CTSourceIPAddressRaw)) 
    {
    $CTSourceIPAddress= $CTSourceIPAddressRaw.ToString().Remove(0,18)
    }

    $CTAWSAccessKeyRaw = $FCTEvent | select-string -Pattern "accessKeyId" -CaseSensitive
    If(![String]::IsNullOrEmpty($CTAWSAccessKeyRaw)) 
    {
        $CTAWSAccessKey = $CTAWSAccessKeyRaw.ToString().Remove(0,14)
    }

    $CTAWSRegionRaw = $FCTEvent | select-string -Pattern "awsRegion" -CaseSensitive
    $CTAWSRegion = $CTAWSRegionRaw.ToString().Remove(0,12)


    $CTEventID = $FCTeach.EventId
    $CTEventTime = $FCTeach.EventTime.AddHours(8).DateTime  #This is to make it UTC timezone
    $CTUserName = $FCTeach.Username
    $CTEventName = $FCTeach.EventName
    

    #filter the resource name
    $ResourceName = ""
    $FCTeach.Resources | select ResourceName | %{$ResourceName = "$ResourceName"+$_+"," }
    $CTResourceName = $ResourceName.Replace("@{","").Replace("ResourceName=","").Replace("`}","")

    #filter the resource type
    $ResourceType = $FCTeach.Resources | select ResourceType

    If(![String]::IsNullOrEmpty($ResourceType)) 
    {
    $CTResourceType = $ResourceType[0].ResourceType.Remove(0,5).Replace("::"," ")
    }
    
    $OutputFile.Write( "$CTSecurityGroup" )
    $OutputFile.Write("`t")
    $OutputFile.Write( "$CTEventID" )
    $OutputFile.Write("`t")
    $OutputFile.Write( "$CTEventTime" )
    $OutputFile.Write("`t")
    $OutputFile.Write( "$CTUserName" )
    $OutputFile.Write("`t")
    $OutputFile.Write( "$CTEventName" )
    $OutputFile.Write("`t")
    $OutputFile.Write( "$CTResourceType" )
    $OutputFile.Write("`t")
    $OutputFile.Write( "$CTResourceName" )
    $OutputFile.Write("`t")
    $OutputFile.Write( "$CTAWSAccessKey" )
    $OutputFile.Write("`t")
    $OutputFile.Write( "$CTAWSRegion" )
    $OutputFile.Write("`t")
    $OutputFile.Write( "$CTSourceIPAddress" )
    $OutputFile.Write("`t")
    $OutputFile.Write( "$FCTEvent" )
    $OutputFile.Write("`t")
    $OutputFile.Write("`n")
     
      <#
write-host $CTSecurityGroup
write-host $CTEventID
write-host $CTEventTime
write-host $CTUserName
write-host $CTEventName
write-host $CTResourceType
write-host $CTResourceName
write-host $CTAWSAccessKey
write-host $CTAWSRegion
write-host $CTSourceIPAddress
write-host $FCTEvent
#>
    }

$nextToken = $AWSHistory.LastServiceResponse.NextToken

} while ($nextToken -ne $null) 

$OutputFile.Close()

Write-Host "Done" -ForegroundColor Green
