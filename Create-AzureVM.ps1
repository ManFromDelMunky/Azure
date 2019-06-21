$SubscriptionID='11111111-1111-1111-1111-111111111111'
$TenantID='11111111-1111-1111-1111-111111111111'
$UserID='username@contosodomain.onmicrosoft.com'
$Password='HSGP@ssw0rd'
$SecurePassword=Convertto-SecureString $Password –asplaintext -force
$Credential=New-Object System.Management.Automation.PSCredential ($UserID,$SecurePassword)
Add-AzAccount -credential $credential -tenantid $TenantID -subscriptionid $SubscriptionID

$AccountData.Context.Tenant.TenantId
$accountdata.Context.Subscription.SubscriptionId

# Create Resources for IAAS if they do not exist
# Resource Group
$RGName='MFDM-AzureRG'
$Location='eastus'
New-AzResourceGroup -Name $RGName -Location $Location

# Storage Account
$SAName='mfdmstore127'
$AccountType='Standard_LRS'
New-AzStorageAccount -Name $SAName -ResourceGroupName $RGName -Location $Location -Type $AccountType

# Virtual Network
$VNAddressPrefix='10.0.0.0/16'
$VNName='MFDMvirtualnetwork'

$SNName='MFDMsubnet'
$SNAddressPrefix='10.0.0.0/24'

$Subnet=New-AzVirtualNetworkSubnetConfig -Name $SNName -AddressPrefix $SNAddressPrefix
$AzureNet=New-AzVirtualNetwork -Name $VNName -ResourceGroupName $RGName -Location $location -AddressPrefix $VNAddressPrefix -Subnet $Subnet

#Create Azure Virtual Machine

# Create AzureVM
# Base config
$VMName='MFDM-VM'
$VMSize='Basic_A0'
$AzureVM = New-AzVMConfig -VMName $VMName -VMSize $VMSize

# Add Network card

$PublicIPNetwork=$VMname+'nic'
$PublicIP = New-AzPublicIpAddress -ResourceGroupName $RGName -Name $PublicIPNetwork -Location $Location -AllocationMethod Dynamic -DomainNameLabel $VMName.ToLower()
$NIC = New-AzNetworkInterface -Force -Name $VMName -ResourceGroupName $RGName -Location $Location -SubnetId $subnet -PublicIpAddressId $PublicIP.Id
$AzureVM = Add-AzVMNetworkInterface -VM $AzureVM -Id $NIC.Id

# Setup OS & Image
# Name the Physical Disk for the O/S, Define Caching status and target URI
$osDiskName = $VMname+'_osDisk'
$osDiskCaching = 'ReadWrite'
$osDiskVhdUri = 'https://'+$StorageURI+'/vhds/'+$vmname+'_os.vhd'

# Define Default User ID and Password for VM
$user = 'MFDMAdmin'
$PasswordFile = "$env:userprofile\OneDrive - Hewlett Packard Enterprise\PowerShell\Secure\TestLabPassword.enc"
$securePassword = get-content $PasswordFile | convertto-securestring
$cred = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist $user,$securePassword

$AzureVM = Set-AzVMOperatingSystem -VM $AzureVM -Windows -ComputerName $VMname -Credential $cred
$AzureVM = Set-AzVMSourceImage -VM $AzureVM -PublisherName $Publisher -Offer $Offer -Skus $Sku -Version $VMImage.Version
$AzureVM = Set-AzVMOSDisk -VM $AzureVM -VhdUri $osDiskVhdUri -name $osDiskName -CreateOption fromImage -Caching $osDiskCaching
                              
# Create Virtual Machine
New-AzVM -ResourceGroupName $RGName -Location $Location -VM $AzureVM 
