#####################################################################################################################
# File Name                                                                                                         #
#   Auto-AzureLogin.ps1                                                                                             #
# Description                                                                                                       #
#   Script to Auto login to Azure                                                                                   #
# Usage                                                                                                             #
#   Copy and paste script in to PowerShell window                                                                   #
#   To change credentials edit the SubscriptionID, TenantID or UserID                                               #
#   To get SubscriptionID and TenantID use Login-AzAccount and enter credentials                               #
#   To Generate Password file                                                                                       #
#   Read-Host -AsSecureString | ConvertFrom-SecureString | Out-File "$env:userprofile\OneDrive - DXC Production\PowerShell\Secure\TestLabPassword.enc"
#   Enter Password at prompt and hit Enter                                                                          #
# Scope                                                                                                             #
#   Azure Resource manager model only, not clasic                                                                   #
# Change Control                                                                                                    #
#   ManFromDelMunky 16/04/2018 Initial Version                                                                      #
#   ManFromDelMunky 21/06/2019 Updated to new AZ powershell module from older AzRM                                  #
# To Do                                                                                                             #
#                                                                                                                   #
# Source info                                                                                                       #
#                                                                                                                   #
#####################################################################################################################

$SubscriptionID='227859da-4b29-4bc9-aa6e-f72c2a621f00'
$TenantID='4aad8693-d44d-4fb5-8553-dd5884bd0fe3'
$UserID='andrew.ferguson.hpe@gmail.com'
$PasswordFile = "$env:userprofile\OneDrive - DXC Production\PowerShell\Secure\TestLabPassword.enc"
$SecurePassword = get-content $PasswordFile | convertto-securestring
$Credential=New-Object System.Management.Automation.PSCredential ($UserID,$SecurePassword)
Add-AzAccount -credential $Credential -tenantid $TenantID -subscriptionid $SubscriptionID


