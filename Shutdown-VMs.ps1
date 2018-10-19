#Shutdown all Tanium Servers
$ResourceGroup = Get-AzureRmResourceGroup "Tanium"
$VMs = Get-AzureRmVM -ResourceGroup $ResourceGroup.ResourceGroupName
Foreach ($VM in $VMs)
{
    Stop-AzureRmVM -ResourceGroupName $ResourceGroup.ResourceGroupName -Name ($VM.Name) -Force
}



#Start up all Tanium Servers, DC first
$ResourceGroup = Get-AzureRmResourceGroup "Tanium"
Start-AzureRmVM -ResourceGroupName $ResourceGroup.ResourceGroupName -Name "TaniumDC1"
#Start-Sleep -s 60
$VMs = Get-AzureRmVM -ResourceGroup $ResourceGroup.ResourceGroupName
Foreach ($VM in $VMs)
{
    If ($_.Name -ne "TaniumDC1")
    {
        Start-AzureRmVM -ResourceGroupName $ResourceGroup.ResourceGroupName -Name ($VM.Name)
    }
    
}

