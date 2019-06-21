$SubscriptionID='11111111-1111-1111-1111-111111111111'
$TenantID='11111111-1111-1111-1111-111111111111'
$UserID='username@contosodomain.onmicrosoft.com'
$Password='HSGP@ssw0rd'
$SecurePassword=Convertto-SecureString $Password –asplaintext -force
$Credential=New-Object System.Management.Automation.PSCredential ($UserID,$SecurePassword)
Add-AzAccount -credential $credential -tenantid $TenantID -subscriptionid $SubscriptionID
#Set OneDrive location
$OneDriveLocation = "$env:userprofile\OneDrive - DXC Production"

#Connect First Time
$AccountData=Add-AzAccount
#Login Interactively

#Store data away for later user
Get-AzSubscription | export-clixml "$OneDriveLocation\PowerShell\Import\Subscription.xml"
Get-AzTenant | export-clixml "$OneDriveLocation\PowerShell\Import\Tenant.xml"

#OR

$AccountData.Context.Tenant.TenantId
$accountdata.Context.Subscription.SubscriptionId

Get-AzResource | Ft ResourceName,ResourceGroupName,ResourceType  Get-AzResourceGroup | ft ResourceGroupName, Location, ResourceID 

Get-AzNetworkInterface | ft Name,Location,ResourceGroupName 

Get-AzVirtualNetwork | Select Name, ResourceGroupName, Subnets

$RgName='HSG-AzureRG'
$VMName='HSG-VirtualMachine'

$VM=get-AzmVm -ResourceGroupName $RGName -name $VMName

$VMSize=$vm.HardwareProfile.VmSize
$ResourceGroup=$vm.ResourceGroupName
$location =$VM.Location

$VMStorageURL=($vm.StorageProfile.OsDisk.Vhd).uri
$StorageGroupURL=$VMStorageURL.substring(0,(($VMStorageURL| Select-String -Pattern '/' -AllMatches).Matches[-1].Index)+1)

$Publisher=$VM.StorageProfile.ImageReference.Publisher
$Offer=$VM.StorageProfile.ImageReference.Offer
$Sku=$VM.StorageProfile.ImageReference.Sku
$Version=$VM.StorageProfile.ImageReference.Version

$AzureImage = Get-AzVMImage -Location $location -PublisherName $Publisher -Offer $Offer -Skus $Sku -Version $Version
