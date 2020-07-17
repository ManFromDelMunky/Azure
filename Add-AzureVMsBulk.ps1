#####################################################################################################################
# File Name                                                                                                         #
#   Add-AzureVMsBulk.ps1                                                                                            #
# Description                                                                                                       #
#   Script to Import Windows Servers on mass from a csv file                                                        #
# Usage                                                                                                             #
#   Copy and paste script in to PowerShell window whilst connected to an azure subscription                         #
#   To login to an Azure subscription use Connect-AzAccount and enter valid credentials                             #
#   NB if creation goes wrong you may have to manually delete the VM and Network interface from Resources in Azure  #
#   as well as the two disk blobs from the storage account                                                          #
#   To get the SKU's use $Location='UK South' Get-AzVMImagePublisher -Location $Location Gives you publishers       #
#   
# Scope                                                                                                             #
#   Azure Resource manager model only, not clasic                                                                   #
# Change Control                                                                                                    #
#   ManFromDelMunky 24/08/2016 Initial Version                                                                      #
#   ManFromDelMunky 16/04/2018 Changed to use the first storage account URI $OSDiskUri                              #
#   ManFromDelMunky 21/06/2019 Updated to new AZ powershell module from older AzRM                                  #
# To Do                                                                                                             #
#                                                                                                                   #
# Source info                                                                                                       #
# https://blogs.technet.microsoft.com/heyscriptingguy/2016/06/06/create-azure-resource-manager-virtual-machines-by-u
# sing-powershell-part-1/
# https://docs.microsoft.com/en-us/azure/virtual-machines/windows/cli-ps-findimage                                  #
#####################################################################################################################
#Set OneDrive location
$OneDriveLocation = "$env:userprofile\OneDrive - DXC Production"


#Set the CSV location
$VirtualMachines = Import-CSV "$OneDriveLocation\PowerShell\Import\Azure PKI Servers.CSV"

# Create Resources for IAAS if they do not exist
# Resource Group
$ResourceGroup='UKSDefault'
$Location='UK South'
New-AzResourceGroup -Name $ResourceGroup -Location $Location

# Storage Account
$SAName='uksdefaultstore'
$AccountType='Standard_LRS'
New-AzStorageAccount -Location $Location -Name $SAName -ResourceGroupName $ResourceGroup -SkuName $AccountType -AccessTier Hot -EnableHttpsTrafficOnly $true -Kind StorageV2

# Virtual Network
$VNAddressPrefix = '10.0.0.0/16'
$vNetName = "$ResourceGroup" + "vnet" 

$SNName = 'UKSubnet1'
$SNAddressPrefix = '10.0.0.0/24'

$Subnet = New-AzVirtualNetworkSubnetConfig -Name $SNName -AddressPrefix $SNAddressPrefix
New-AzVirtualNetwork -Name $vNetName -ResourceGroupName $ResourceGroup -Location $location -AddressPrefix $VNAddressPrefix -DnsServer "10.0.0.11,8.8.8.8" -Subnet $Subnet


ForEach ($VirtualMachine in $VirtualMachines)
{
    $Name = $VirtualMachine.Name
    Write-Host "Creating $Name"
    $vmSize = $VirtualMachine.vmSize
    $PubName = $VirtualMachine.pubName
    $OfferName = $VirtualMachine.offerName
    $skuName = $VirtualMachine.skuName
    $Description = $VirtualMachine.Description
    #$ResourceGroup = $VirtualMachine.ResourceGroup
    $PublicIP = $VirtualMachineVM.PublicIP
    $DiskName = $VirtualMachine.Name
    $DataDiskName = "$DiskName" + "-DataDisk1"
    $StaticIP = $VirtualMachine.StaticIP    
    $vNetName = "$ResourceGroup" + "vnet"    
    $RandomNum = Get-Random -Maximum 9999 -Minimum 1
    $nicName = "$Name" + "$RandomNum"

    $StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroup    
    #Get previously stored password from file, see bottom for how to store password in file.
    $PasswordFile = "$OneDriveLocation\PowerShell\Secure\TestLabPassword.enc"
    $Password = Get-Content $PasswordFile | ConvertTo-SecureString
    $Cred = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist $Name,$Password

    If ($StaticIP -eq "")
    {
         $StaticIP = "Dynamic"
         #$StaticIP = New-AzIpAddress -Name $NICName -ResourceGroupName $ResourceGroup -Location $Location -AllocationMethod Dynamic
    }
    # Get the reference to the vNet that has the subnet being targeted
    $vNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroup -Name $vNetName
    # Create the Basic virtual machine configuration object and save a reference to it
    $vm = New-AzVMConfig -VMName $Name -VMSize $vmSize

    # Assign the operating system to the VM configuration
    $vm = Set-AzVMOperatingSystem -VM $vm -Windows -ComputerName $Name -Credential $Cred -ProvisionVMAgent -EnableAutoUpdate

    # Assign the gallery image to the VM configuration
    $vm = Set-AzVMSourceImage -VM $vm -PublisherName $pubName -Offer $offerName -Skus $skuName -Version "latest"

    # Get a reference to the Subnet to attach the NIC
    $Subnet = (Get-AzVirtualNetwork -Name $vNetName -ResourceGroupName $ResourceGroup).subnets[0]
    If ($PublicIP -eq "TRUE")
    {
        $pubIP = New-AzPublicIpAddress -Name $NICName -ResourceGroupName $ResourceGroup -Location $Location -AllocationMethod Dynamic
        $NIC = New-AzNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroup -Location $Location -SubnetId $Subnet.Id -PublicIpAddressId $pubIP.Id -PrivateIpAddress $staticIP
    }
    Else
    {
        $NIC = New-AzNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroup -Location $Location -SubnetId $Subnet.Id -PrivateIpAddress $staticIP
    }

    # Assign the NIC to the VM configuration
    $vm = Add-AzVMNetworkInterface -VM $vm -Id $NIC.Id
    # Create the URI to store the OS disk VHD
    $OSDiskUri = $StorageAccount[0].PrimaryEndpoints.Blob.ToString() + "vhds/" + $diskName  + ".vhd"
    $DataDiskUri = $StorageAccount[0].PrimaryEndpoints.Blob.ToString() + "vhds/" + $DataDiskName  + ".vhd"
    # Assign the OS Disk name and location to the VM configuration
    $vm = Set-AzVMOSDisk -VM $vm -Name $diskName -VhdUri $OSDiskUri -CreateOption fromImage
    #Add extra data disk
    $vm = Add-AzVMDataDisk -VM $vm -Name "$DataDiskName" -Caching "ReadOnly" -DiskSizeInGB 10 -Lun 0 -VhdUri $DataDiskUri -CreateOption Empty
    #Now actually create the VM
    New-AzVM -ResourceGroupName $ResourceGroup -Location $Location -VM $vm
}

#To Generate Password file
#Read-Host -AsSecureString | ConvertFrom-SecureString | Out-File "$env:userprofile\OneDrive - DXC Production\PowerShell\Secure\TestLabPassword.enc"
#Enter Password at prompt and hit Enter
#get-content $PasswordFile | convertto-securestring

