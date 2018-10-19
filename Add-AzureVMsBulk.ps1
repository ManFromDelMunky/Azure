#####################################################################################################################
# File Name                                                                                                         #
#   Add-AzureVMsBulk.ps1                                                                                            #
# Description                                                                                                       #
#   Script to Import Windows Servers on mass from a csv file                                                        #
# Usage                                                                                                             #
#   Copy and paste script in to PowerShell window whilst connected to an azure subscription                         #
#   To login to an Azure subscription use Login-AzureRmAccount and enter valid credentials                          #
# Scope                                                                                                             #
#   Azure Resource manager model only, not clasic                                                                   #
# Change Control                                                                                                    #
#   Andy Ferguson 24/08/2016 Initial Version                                                                        #
#   Andy Ferguson 16/04/2018 Changed to use the first storage account URI $OSDiskUri    #

# To Do                                                                                                             #
# Source info
# https://blogs.technet.microsoft.com/heyscriptingguy/2016/06/06/create-azure-resource-manager-virtual-machines-by-u
# sing-powershell-part-1/
#####################################################################################################################
#Set OneDrive location
$OneDriveLocation = "$env:userprofile\OneDrive - DXC Production"


#Set the CSV location
$VirtualMachines = Import-CSV "$OneDriveLocation\PowerShell\Import\Azure PKI Servers.CSV"

# # Create Resources for IAAS if they do not exist
# # Resource Group
# $RGName='PKI-Domain-ECC'
# $Location='North Europe'
# New-AzureRmResourceGroup -Name $RGName -Location $Location

# # Storage Account
# $SAName='pkistorage1284'
# $AccountType='Standard_LRS'
# New-AzureRmStorageAccount -Name $SAName -ResourceGroupName $RGName -Location $Location -Type $AccountType

# # Virtual Network
# $VNAddressPrefix = '10.0.0.0/16'
# $vNetName = "$ResourceGroup" + "-vnet" 

# $SNName = 'pkisubnet1'
# $SNAddressPrefix = '10.0.0.0/24'

# New-AzureRmVirtualNetworkSubnetConfig -Name $SNName -AddressPrefix $SNAddressPrefix
# New-AzureRmVirtualNetwork -Name $vNetName -ResourceGroupName $RGName -Location $location -AddressPrefix $VNAddressPrefix -Subnet $Subnet


ForEach ($VirtualMachine in $VirtualMachines)
{
    $Location = "North Europe"
    $Name = $VirtualMachine.Name
    $vmSize = $VirtualMachine.vmSize
    $PubName = $VirtualMachine.pubName
    $OfferName = $VirtualMachine.offerName
    $skuName = $VirtualMachine.skuName
    $Description = $VirtualMachine.Description
    $ResourceGroup = $VirtualMachine.ResourceGroup
    $PublicIP = $VirtualMachineVM.PublicIP
    $DiskName = $VirtualMachine.Name
    $DataDiskName = "$DiskName" + "-DataDisk1"
    $StaticIP = $VirtualMachine.StaticIP    
    $vNetName = "$ResourceGroup" + "-vnet"    
    $RandomNum = Get-Random -Maximum 9999 -Minimum 1
    $nicName = "$Name" + "$RandomNum"

    $StorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroup    
    #Get previously stored password from file, see bottom for how to store password in file.
    $PasswordFile = "$OneDriveLocation\PowerShell\Secure\TestLabPassword.enc"
    $password = get-content $PasswordFile | convertto-securestring
    $cred = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist $Name,$password

    If ($StaticIP -eq "")
    {
         $StaticIP = "Dynamic"
         #$StaticIP = New-AzureRmIpAddress -Name $NICName -ResourceGroupName $ResourceGroup -Location $Location -AllocationMethod Dynamic
    }
    # Get the reference to the vNet that has the subnet being targeted
    $vNet = Get-AzureRMVirtualNetwork -ResourceGroupName $ResourceGroup -Name $vNetName
    # Create the Basic virtual machine configuration object and save a reference to it
    $vm = New-AzureRmVMConfig -VMName $Name -VMSize $vmSize

    # Assign the operating system to the VM configuration
    $vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $Name -Credential $cred -ProvisionVMAgent -EnableAutoUpdate

    # Assign the gallery image to the VM configuration
    $vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName $pubName -Offer $offerName -Skus $skuName -Version "latest"

    # Get a reference to the Subnet to attach the NIC
    $Subnet = (Get-AzureRmVirtualNetwork -Name $vNetName -ResourceGroupName $ResourceGroup).subnets[0]
    If ($PublicIP -eq "TRUE")
    {
        $pubIP = New-AzureRmPublicIpAddress -Name $NICName -ResourceGroupName $ResourceGroup -Location $Location -AllocationMethod Dynamic
        $NIC = New-AzureRmNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroup -Location $Location -SubnetId $Subnet.Id -PublicIpAddressId $pubIP.Id -PrivateIpAddress $staticIP
    }
    Else
    {
        $NIC = New-AzureRmNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroup -Location $Location -SubnetId $Subnet.Id -PrivateIpAddress $staticIP
    }

    # Assign the NIC to the VM configuration
    $vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $NIC.Id
    # Create the URI to store the OS disk VHD
    $OSDiskUri = $StorageAccount[0].PrimaryEndpoints.Blob.ToString() + "vhds/" + $diskName  + ".vhd"
    $DataDiskUri = $StorageAccount[0].PrimaryEndpoints.Blob.ToString() + "vhds/" + $DataDiskName  + ".vhd"
    # Assign the OS Disk name and location to the VM configuration
    $vm = Set-AzureRmVMOSDisk -VM $vm -Name $diskName -VhdUri $OSDiskUri -CreateOption fromImage
    #Add extra data disk
    $vm = Add-AzureRmVMDataDisk -VM $vm -Name "$DataDiskName" -Caching "ReadOnly" -DiskSizeInGB 100 -Lun 0 -VhdUri $DataDiskUri -CreateOption Empty
    #Now actually create the VM
    New-AzureRmVM -ResourceGroupName $ResourceGroup -Location $Location -VM $vm
}

#To Generate Password file
#Read-Host -AsSecureString | ConvertFrom-SecureString | Out-File "$env:userprofile\OneDrive - DXC Production\PowerShell\Secure\TestLabPassword.enc"
#Enter Password at prompt and hit Enter
#get-content $PasswordFile | convertto-securestring

