$SubscriptionID='11111111-1111-1111-1111-111111111111'
$TenantID='11111111-1111-1111-1111-111111111111'
$UserID='username@contosodomain.onmicrosoft.com'
$Password='HSGP@ssw0rd'
$SecurePassword=Convertto-SecureString $Password –asplaintext -force
$Credential=New-Object System.Management.Automation.PSCredential ($UserID,$SecurePassword)
Add-AzAccount -credential $credential -tenantid $TenantID -subscriptionid $SubscriptionID

#Store data away for later user
Get-AzSubscription | export-clixml Subscription.xml
Get-AzTenant | export-clixml Tenant.xml

#OR

$AccountData.Context.Tenant.TenantId
$accountdata.Context.Subscription.SubscriptionId

# Create new
# Resource Group
$RGName='HSG-AzureRG'
$Location='eastus'
New-AzResourceGroup -Name $RGName -Location $Location

# Storage Account
$SAName='hsgstorageaccount'
$AccountType='Standard_LRS'
New-AzStorageAccount -Name $SAName -ResourceGroupName $RGName -Location $Location -Type $AccountType

# Virtual Network
$VNAddressPrefix='10.0.0.0/16'
$VNName='hsgvirtualnetwork'

$SNName='hsgsubnet'
$SNAddressPrefix='10.0.0.0/24'

$Subnet=New-AzVirtualNetworkSubnetConfig -Name $SNName -AddressPrefix $SNAddressPrefix
$AzureNet=New-AzVirtualNetwork -Name $VNName -ResourceGroupName $RGName -Location $location -AddressPrefix $VNAddressPrefix -Subnet $Subnet
 