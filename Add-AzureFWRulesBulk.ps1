#####################################################################################################################
# Script to Import Firewall rules on mass from a csv file                                                           #
#   Ensures all rules are given a unique Priority                                                                   #
#   Andy Ferguson 24/08/2016                                                                                         #
#   Usage Copy and paste script in to PowerShell window whilst connected to an azure subscription                   #
#   Ensure $NetSecGroup is set to the group you want to addd the rules to                                           #
#####################################################################################################################
#Set OneDrive location
$OneDriveLocation = "$env:userprofile\OneDrive - DXC Production"

#Set the CSV location
$Rules = Import-CSV "$OneDriveLocation\PowerShell\Import\AD Firewall Rules.CSV"
#Set the Network Security Group
$NetSecGroup = Get-AzureRMNetworkSecurityGroup -ResourceGroupName "PKI-Domain" -Name "Domain-Controllers"
#Works out that Unique Priority to give each rule NB TCP Rule will start at 2000 and UDP will be 3000
[Int32]$TCPCount = (($NetSecGroup.SecurityRules | Where {$_.Protocol -eq "TCP" }| Sort-Object Priority -descending)[0]).Priority
[Int32]$UDPCount = (($NetSecGroup.SecurityRules | Where {$_.Protocol -eq "UDP" }| Sort-Object Priority -descending)[0]).Priority
If ($TCPCount -lt "2000")
    {
        $TCPCount = "2000"
    }
If ($UDPCount -lt "3000")
    {
        $UDPCount = "3000"
    }

ForEach ($Rule in $Rules)
    {
    $Name = $Rule.Name
    $Protocol = $Rule.Protocol
    $DestinationPortRange = $Rule.DestinationPortRange
    $Description = $Rule.Description
    $Priority = $Rule.Priority
 #   IF ($Protocol -eq "TCP")
 #       {
 #       $Priority = $TCPCount
 #       $TCPCount = $TCPCount++
 #       } 
 #   ElseIf ($Protocol -eq "UDP")
 #       {
 #       $Priority = $UDPCount
 #       $UDPCount = $UDPCount++
 #       }
    Add-AzureRmNetworkSecurityRuleConfig -Name $Name -Description $Description -NetworkSecurityGroup $NetSecGroup -Protocol $Protocol -SourcePortRange "*" -DestinationPortRange $DestinationPortRange -SourceAddressPrefix "10.0.0.0/22" -DestinationAddressPrefix "*" -Access "Allow" -Priority $Priority -Direction "Inbound"
    }



#Now set all the rules Commented out  for saftey reasons
#Set-AzureRmNetworkSecurityGroup -NetworkSecurityGroup $NetSecGroup
