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
$OutputFilePath = "$CurrentFolder\AwsRdsList-$RandomName.txt"

Import-Module AWSPowerShell
Set-AWSCredential -AccessKey  $accessKey  -SecretKey $secretKey -StoreAs my_profile
Set-AWSCredential -ProfileName my_profile
Set-DefaultAWSRegion -Region us-east-1

If(![System.IO.File]::Exists($OutputFilePath))
{
    $OutputFile = [System.IO.File]::CreateText($OutputFilePath)
}


# Write header in output file
$RDSItems = @(
                "Region",
                "DBInstanceIdentifier",
                "DBName",
                "DBParameterGroups",
                "DBClusterIdentifier",
                "IsClusterWriter",
                "DBClusterParameterGroupStatus",
                "DBClusterWriterEndPoint",
                "DBClusterReaderEndPoint",
                "DBClusterPort",
                "Engine" ,
                "EngineVersion",
                "DbInstancePort",
                "DbEndPointAddress",
                "DbEndPointPort",
                "DBInstanceStatus",
                "AvailabilityZone",
                "SecondaryAvailabilityZone",
                "MultiAZ",
                "RdsSubnetGroup",
                "PubliclyAccessible",
                "ReadReplicaSourceDBInstanceIdentifier",
                "RdsClReplicaIds",
                "RdsDbReplicaIds",
                "InstanceCreateTime",
                "AutoMinorVersionUpgrade",
                "PreferredMaintenanceWindow",
                "PreferredBackupWindow",
                "BackupRetentionPeriod",
                "LatestRestorableTime",
                "AllocatedStorage" ,
                "StorageEncrypted",
                "StorageType" ,
                "Iops",
                "DBInstanceClass",
                "DbiResourceId",
                "DBInstanceArn",
                "IAMDatabaseAuthenticationEnabled",
                "RdsSecurityGroups",
                "RdsVpcSecurityGroups",
                "Tag-Brand",
                "Tag-Role",
                "Tag-Country",
                "Tag-Service",
                "Tag-Domain",
                "Tag-Env",
                "Tag-Segment"
                "RdsTfBlock"
                "RdsClusterTfBlock"
                "DxcScope?"
             )

Foreach ($RDSItem in $RDSItems){

    $OutputFile.Write($RDSItem)
    $OutputFile.Write("`t")

}
$OutputFile.Write("`n")
$ExcelCount = 1

#Getting RDS Cluster information

    $RdsCluster               = (Get-RDSDBCluster -Region $_.Region)
    $RdsClusterMember         = (Get-RDSDBCluster -Region $_.Region).DBClusterMembers


#Get-AWSRegion | % {
   
    #$region = $_.Region
    $region = "us-east-1"
    Write-host "Processing region $region" -ForegroundColor Magenta
    

    $Ec2Subnets = Get-EC2Subnet -Region $region
    $Ec2Vpcs = Get-EC2Vpc -Region $region


    Write-Host " -> Retrieving RDS instances list" -ForegroundColor Cyan

    Get-RDSDBInstance -Region $_.Region | % {
        
        #$ExcelCount++
        $RdsInstance = $_
        $RdsTags = Get-RDSTagForResource -ResourceName $RdsInstance.DBInstanceArn

        $RdsInstanceParameter = ""
        $RdsInstance.DBParameterGroups | %{$RdsInstanceParameter = "$RdsInstanceParameter"+$_.DBParameterGroupName+" "}

        $OutputFile.Write( $region )
        $OutputFile.Write("`t")
        $OutputFile.Write( $RdsInstance.DBInstanceIdentifier )
        $OutputFile.Write("`t")
        $OutputFile.Write( $RdsInstance.DBName )
        $OutputFile.Write("`t")
        $OutputFile.Write( $RdsInstanceParameter )
        $OutputFile.Write("`t")
        $OutputFile.Write( $RdsInstance.DBClusterIdentifier )
        $OutputFile.Write("`t")

        $OutputFile.Write( ($RdsClusterMember | where DBInstanceIdentifier -EQ $RdsInstance.DBInstanceIdentifier).IsClusterWriter )
        $OutputFile.Write("`t")
        $OutputFile.Write( ($RdsClusterMember | where DBInstanceIdentifier -EQ $RdsInstance.DBInstanceIdentifier).DBClusterParameterGroupStatus )
        $OutputFile.Write("`t")
        $OutputFile.Write( ($RdsCluster | where DBClusterIdentifier -EQ $RdsInstance.DBClusterIdentifier).Endpoint )
        $OutputFile.Write("`t")
        $OutputFile.Write( ($RdsCluster | where DBClusterIdentifier -EQ $RdsInstance.DBClusterIdentifier).ReaderEndpoint )
        $OutputFile.Write("`t")
        $OutputFile.Write( ($RdsCluster | where DBClusterIdentifier -EQ $RdsInstance.DBClusterIdentifier).Port )
        $OutputFile.Write("`t")

        $OutputFile.Write( $RdsInstance.Engine )
        $OutputFile.Write("`t")
        $OutputFile.Write( $RdsInstance.EngineVersion)
        $OutputFile.Write("`t")
        $OutputFile.Write( $RdsInstance.DbInstancePort )
        $OutputFile.Write("`t")
        $OutputFile.Write( $RdsInstance.Endpoint.Address )
        $OutputFile.Write("`t")
        $OutputFile.Write( $RdsInstance.Endpoint.Port )
        $OutputFile.Write("`t")

        $OutputFile.Write( $RdsInstance.DBInstanceStatus )
        $OutputFile.Write("`t")
        $OutputFile.Write( $RdsInstance.AvailabilityZone )
        $OutputFile.Write("`t")
        $OutputFile.Write( $RdsInstance.SecondaryAvailabilityZone )
        $OutputFile.Write("`t")
        $OutputFile.Write( $RdsInstance.MultiAZ )
        $OutputFile.Write("`t")

        $RdsSubnetGroup = ""
        $RdsInstance.DBSubnetGroup | % { $RdsSubnetGroup = "$RdsSubnetGroup"+$_.DBSubnetGroupName+":"
        
            $_.Subnets | % { 
                
                $SubnetAz = ($Ec2Subnets | Where SubnetId -EQ $_.SubnetIdentifier).AvailabilityZone
                $SubnetCidr = ($Ec2Subnets | Where SubnetId -EQ $_.SubnetIdentifier).CidrBlock
                $RdsSubnetGroup = "$RdsSubnetGroup{$SubnetAz,$SubnetCidr}"
            }

            $RdsSubnetGroup = $RdsSubnetGroup+"} "  
        }

        $OutputFile.Write( $RdsSubnetGroup )
        $OutputFile.Write("`t")
        $OutputFile.Write( $RdsInstance.PubliclyAccessible )
        $OutputFile.Write("`t")


        $RdsClReplicaIds = ""
        $RdsInstance.ReadReplicaDBClusterIdentifiers | % { $RdsClReplicaIds = "$RdsClReplicaIds"+$_+" "  }
        $RdsDbReplicaIds = ""
        $RdsInstance.ReadReplicaDBInstanceIdentifiers | % { $RdsDbReplicaIds = "$RdsDbReplicaIds"+$_+" "  }

        $OutputFile.Write( $RdsInstance.ReadReplicaSourceDBInstanceIdentifier )
        $OutputFile.Write("`t")
        $OutputFile.Write( $RdsClReplicaIds )
        $OutputFile.Write("`t")
        $OutputFile.Write( $RdsDbReplicaIds )
        $OutputFile.Write("`t")

        $OutputFile.Write( $RdsInstance.InstanceCreateTime )
        $OutputFile.Write("`t")
        $OutputFile.Write( $RdsInstance.AutoMinorVersionUpgrade )
        $OutputFile.Write("`t")
        $OutputFile.Write( $RdsInstance.PreferredMaintenanceWindow )
        $OutputFile.Write("`t")
        $OutputFile.Write( $RdsInstance.PreferredBackupWindow )
        $OutputFile.Write("`t")
        $OutputFile.Write( $RdsInstance.BackupRetentionPeriod )
        $OutputFile.Write("`t")
        $OutputFile.Write( $RdsInstance.LatestRestorableTime )
        $OutputFile.Write("`t")

        $OutputFile.Write( $RdsInstance.AllocatedStorage )
        $OutputFile.Write("`t")
        $OutputFile.Write( $RdsInstance.StorageEncrypted )
        $OutputFile.Write("`t")
        $OutputFile.Write( $RdsInstance.StorageType )
        $OutputFile.Write("`t")
        $OutputFile.Write( $RdsInstance.Iops )
        $OutputFile.Write("`t")

        $OutputFile.Write( $RdsInstance.DBInstanceClass )
        $OutputFile.Write("`t")
        $OutputFile.Write( $RdsInstance.DbiResourceId )
        $OutputFile.Write("`t")
        $OutputFile.Write( $RdsInstance.DBInstanceArn )
        $OutputFile.Write("`t")

        $RdsDbSgs = ""
        $RdsInstance.DBSecurityGroups | % { $RdsSgs = "$RdsSgs"+$_+" "  }
        $RdsVpcSgs = ""
        $RdsInstance.VpcSecurityGroups | % { $RdsVpcSgs = "$RdsVpcSgs"+$_.VpcSecurityGroupId+"("+$_.Status+") "  }

        $OutputFile.Write( $RdsInstance.IAMDatabaseAuthenticationEnabled )
        $OutputFile.Write("`t")
        $OutputFile.Write( $RdsSgs )
        $OutputFile.Write("`t")
        $OutputFile.Write( $RdsVpcSgs )
        $OutputFile.Write("`t")

        $OutputFile.Write( ($RdsTags | Where Key -Like "Brand").Value )
        $OutputFile.Write("`t")
        $OutputFile.Write( ($RdsTags | Where Key -Like "Role").Value )
        $OutputFile.Write("`t")
        $OutputFile.Write( ($RdsTags | Where Key -Like "Country").Value )
        $OutputFile.Write("`t")
        $OutputFile.Write( ($RdsTags | Where Key -Like "Service").Value )
        $OutputFile.Write("`t")
        $OutputFile.Write( ($RdsTags | Where Key -Like "Domain").Value )
        $OutputFile.Write("`t")
        $OutputFile.Write( ($RdsTags | Where Key -Like "Env").Value )
        $OutputFile.Write("`t")
        $OutputFile.Write( ($RdsTags | Where Key -Like "Segment").Value )
       
        $OutputFile.Write("`t")
        #$OutputFile.Write("=VLOOKUP(B$ExcelCount, TFMap!"+'$A$1:$B$70000,2,FALSE)') 
        #$OutputFile.Write("`t")
        #$OutputFile.Write("=VLOOKUP(E$ExcelCount, TFMap!"+'$A$1:$B$70000,2,FALSE)') 
        #$OutputFile.Write("`t")
        #$OutputFile.Write("=IF(AND((ISNA(AV$ExcelCount)),(ISNA(AW$ExcelCount))),""No"",""Yes"")") 
        $OutputFile.Write("`n")
    } 


#}

$OutputFile.Close()

Write-Host "Done" -ForegroundColor Green
