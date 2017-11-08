#This script is capable to pull all the Cloudtrail event
#If you wish to make this script to display all the events, please remove the "If condition" which can be found in the script :
# If($AllResourceName -like "sg-*"){}  
#This version added the filter to have selected only Security group resources


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
$OutputFilePath = "$CurrentFolder\Cloudtrail-$RandomName.txt"

Import-Module AWSPowerShell
Set-AWSCredential -AccessKey  $accessKey  -SecretKey $secretKey -StoreAs my_profile
Set-AWSCredential -ProfileName my_profile
#$region = "ap-southeast-1"
$region = "us-east-1"
Set-DefaultAWSRegion -Region $region

If(![System.IO.File]::Exists($OutputFilePath))
{
    $OutputFile = [System.IO.File]::CreateText($OutputFilePath)
}

Write-host "Processing region $region" -ForegroundColor Magenta

# Write header in output file


    $OutputFile.Write( "Resource" )
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
    $OutputFile.Write( "Resources name" )
    $OutputFile.Write("`t")
    $OutputFile.Write( "AWS access key" )
    $OutputFile.Write("`t")
    $OutputFile.Write( "AWS region" )
    $OutputFile.Write("`t")
    $OutputFile.Write( "Source IP address" )
    $OutputFile.Write("`t")
    $OutputFile.Write( "Event" )
    $OutputFile.Write("`t")
    $OutputFile.Write("`n")
    
$nextToken = $null
do
{   
    Find-CTEvent -NextToken $nextToken | %{
    
    #Get cloudtrail event only. Split it into multiple strings
    $FCTeach = $_
    $FCTEvent = $FCTeach.CloudTrailEvent.Replace("`",`"","$").Split("$").Replace("{`"","").Replace("`"}","")

    #Very important to check if the string is null or not. Else the tostring() will return error is value is null
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
    $CTEventTime = $FCTeach.EventTime.AddHours(8).DateTime  #This is to make it UTC timezone to align with what we see the cloudtrail report from AWS console
    $CTUserName = $FCTeach.Username
    $CTEventName = $FCTeach.EventName
    

    #filter the resource name
    $ResourceName = $FCTeach.Resources | %{$_.ResourceName}
    $CTResourceName = ""
    $ResourceName | %{$CTResourceName = "$CTResourceName"+$_+" , " } #Fit multiple values into a single cell with comma. e.g. : sg-175dee71,sg-047ecd62,

    #filter the resource type
    #$ResourceType = $FCTeach.Resources | select ResourceType


    $AllResourceArray = $FCTeach.Resources
    #Write-host $ResourceNameCount
    
    ForEach ($AllResource in $AllResourceArray)
    {

    $AllResourceName = $AllResource | %{$_.ResourceName}
    $AllResourceType = $AllResource | %{$_.ResourceType}

        If($AllResourceName -like "sg-*"){  #This is the filter to write output of security group only

            If(![String]::IsNullOrEmpty($AllResourceType)) 
            {
                $AllResourceType = $AllResourceType.Remove(0,5).Replace("::"," ")  #Fix this pattern "AWS::xxx::xxxxx" to "xxx xxxxx"
            }

            $OutputFile.Write( "$AllResourceName" )
            $OutputFile.Write("`t")
            $OutputFile.Write( "$CTEventID" )
            $OutputFile.Write("`t")
            $OutputFile.Write( "$CTEventTime" )
            $OutputFile.Write("`t")
            $OutputFile.Write( "$CTUserName" )
            $OutputFile.Write("`t")
            $OutputFile.Write( "$CTEventName" )
            $OutputFile.Write("`t")
            $OutputFile.Write( "$AllResourceType" )
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

            }
        }#End If -like
     
    }

    $nextToken = $AWSHistory.LastServiceResponse.NextToken

} while ($nextToken -ne $null) 

$OutputFile.Close()

Write-Host "Done" -ForegroundColor Green
