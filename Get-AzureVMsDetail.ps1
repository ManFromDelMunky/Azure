#####################################################################################################################
# File Name                                                                                                         #
#   Get-AzureVMsDetail.ps1                                                                                            #
# Description                                                                                                       #
#   Script to get detail on Azure Servers on mass                                                         #
# Usage                                                                                                             #
#   Copy and paste script in to PowerShell window whilst connected to an azure subscription                         #
#   To login to an Azure subscription use Login-AzureRmAccount and enter valid credentials                          #
# Scope                                                                                                             #
#   Azure Resource manager model only, not clasic                                                                   #
# Change Control                                                                                                    #
#   Andy Ferguson 12/04/2018 Initial Version                                                                        #
# To Do                                                                                                             #
#####################################################################################################################


$RGs = Get-AzureRMResourceGroup
foreach($RG in $RGs)
{
    $VMs = Get-AzureRmVM -ResourceGroupName $RG.ResourceGroupName
    foreach($VM in $VMs)
    {
        $VMDetail = Get-AzureRmVM -ResourceGroupName $RG.ResourceGroupName -Name $VM.Name -Status
        foreach ($VMStatus in $VMDetail.Statuses)
        { 
            if($VMStatus.Code -like "PowerState/*")
            {
                $VMStatusDetail = $VMStatus.DisplayStatus
            }
        }
        $out = new-object psobject
        $out | add-member noteproperty 'Virtual Machine Name' $VM.Name
        $out | add-member noteproperty Status $VMStatusDetail
        $out | add-member noteproperty 'Resource Group Name' $RG.ResourceGroupName
        Write-Output $out
    }
}