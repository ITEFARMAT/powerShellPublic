#Please Run This Script on Domain Contoller which have DirSync with Office 365
#Checking if the shell is running as administrator.
#Requires -RunAsAdministrator
#Requires -Module ActiveDirectory
$title = "Create a User Account in Active Directory"
 
$host.ui.RawUI.WindowTitle = $title
 
Import-Module ActiveDirectory -EA Stop

sleep 5
cls

Write-Host
Write-Host
#Getting variable for the First Name
$firstname = Read-Host "Enter in the First Name"
Write-Host
#Getting variable for the Last Name
$lastname = Read-Host "Enter in the Last Name"
Write-Host
#Setting Full Name (Display Name) to the users first and last name
$fullname = "$firstname $lastname"
Write-Host
$logonname = $firstname.ToLower() + (".") + $lastname.ToLower()
#Setting the Path for the OU.
$OU = Read-Host "Enter the OU following to create user"
#Setting the variable for the domain.
$domain = $env:userdnsdomain
Write-Host
$mail = ""
Write-Host
$jobTitle = Read-Host "Enter the Job Title"
Write-Host
$StreetAddress = ""
$city = ""
$state = ""
$zipcode = ""
$country = ""

cls


DO {
    If ($(Get-ADUser -Filter { SamAccountName -eq $logonname })) {
        Write-Host "WARNING: Logon name" $logonname.toUpper() "already exists!!" -ForegroundColor:Green
        $logonname = $firstname.ToLower() + (".") + $lastname.ToLower()
        Write-Host "Changing Logon name to" $logonname.toUpper() -ForegroundColor:Green
        Write-Host
        $taken = $true
        sleep 10
    }
    else {
        $taken = $false
    }
} Until ($taken -eq $false)
$logonname = $logonname.toLower()
 
cls

#Setting minimum password length to 12 characters and adding password complexity.
$PasswordLength = 12

Do {
    Write-Host
    $isGood = 0
    $Password = Read-Host "Enter  the User Password" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    $Complexity = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
 
    if ($Complexity.Length -ge $PasswordLength) {
        Write-Host
    }
    else {
        Write-Host "Password needs $PasswordLength or more Characters" -ForegroundColor:Red
    }
 
    if ($Complexity -match "[^a-zA-Z0-9]") {
        $isGood++
    }
    else {
        Write-Host "Password does not contain Special Characters." -ForegroundColor:Red
    }
 
    if ($Complexity -match "[0-9]") {
        $isGood++
    }
    else {
        Write-Host "Password does not contain Numbers." -ForegroundColor:Red
    }
 
    if ($Complexity -cmatch "[a-z]") {
        $isGood++
    }
    else {
        Write-Host "Password does not contain Lowercase letters." -ForegroundColor:Red
    }
 
    if ($Complexity -cmatch "[A-Z]") {
        $isGood++
    }
    else {
        Write-Host "Password does not contain Uppercase letters." -ForegroundColor:Red
    }
 
} Until ($password.Length -ge $PasswordLength -and $isGood -ge 3)
 

Write-Host
Read-Host "Press Enter to Continue Creating the Account"
#Write-Host "Creating Active Directory account now :)" -ForegroundColor:Magenta

New-AdUser -Name $fullname -GivenName $firstname -Surname $lastname -DisplayName $fullname -SamAccountName $logonname -UserPrincipalName $logonname$mail -AccountPassword $password -ChangePasswordAtLogon $true -Enabled $true -Path $OU -Confirm:$false -EmailAddress $logonname$mail -Title $jobTitle -StreetAddress $StreetAddress -City $city -State $state -PostalCode $zipcode

For ($i = 0; $i -le 100; $i++) {
    Start-Sleep -Milliseconds 15
    Write-Progress -Activity "Create New User in Active Directory" -Status "Progress: $i" -PercentComplete $i -CurrentOperation "Counting..."
}


cls

Write-Host
 
$ADProperties = Get-ADUser $logonname -Properties *
 
 
 
Write-Host "===================================================================" -ForegroundColor:Magenta
Write-Host "The account was sucessfully created with the following properties:"-ForegroundColor:Magenta
Write-Host
Write-Host "Firstname:      $firstname"-ForegroundColor:Magenta
Write-Host "Lastname:       $lastname"-ForegroundColor:Magenta
Write-Host "Display name:   $fullname"-ForegroundColor:Magenta
Write-Host "Logon name:     $logonname"-ForegroundColor:Magenta
Write-Host "OU:             $OU"-ForegroundColor:Magenta
Write-Host "Domain:         $domain"-ForegroundColor:Magenta
Write-Host "E-mail address: $logonname$mail" -ForegroundColor:Magenta
Write-Host "Job Title:      $jobTitle" -ForegroundColor:Magenta
Write-Host "Street Address: $StreetAddress"-ForegroundColor:Magenta
Write-Host "City:           $city"-ForegroundColor:Magenta
Write-Host "State:          $state"-ForegroundColor:Magenta
Write-Host "Zip-Code        $zipcode"-ForegroundColor:Magenta
Write-Host "Country:        $country"-ForegroundColor:Magenta
Write-Host
Write-Host

$User = Get-ADUser -Identity $logonname
$group = "default"

Add-ADGroupMember -Identity $group -Members $User

For ($i = 0; $i -le 100; $i++) {
    Start-Sleep -Milliseconds 15
    Write-Progress -Activity "Adding user to group" -Status "Progress: $i" -PercentComplete $i -CurrentOperation "Counting..."
}

sleep 10

Write-Host "User has been added to group successfully"  -ForegroundColor:Magenta

sleep 10

cls

Start-ADSyncSyncCycle -PolicyType Initial


$totalTimes = 180

$i = 0

for ($i = 0; $i -lt $totalTimes; $i++) {

    $percentComplete = ($i / $totalTimes) * 100

    Write-Progress -Activity 'Sync user with Office365' -Status "Sync will take $i  seconds" -PercentComplete $percentComplete

    sleep 1

}

cls

Install-Module -Name AzureAD -Force
sleep 10
Install-Module MSOnline -Force
sleep 10
Set-ExecutionPolicy Unrestricted -Force
$credential = Get-Credential
Import-Module MsOnline
Connect-MsolService -Credential $credential

$userUPN = "$logonname$mail"
$license = ""
$usageLocation = ""

#Get-AzureADUser -ObjectID $userUpn | Select DisplayName, UsageLocation
Set-MsolUser -UserPrincipalName $userUPN -UsageLocation $usageLocation
sleep 5
Set-MsolUserLicense -UserPrincipalName $userUPN -AddLicenses $license 
Add-UnifiedGroupLinks -Identity members@br-ag.eu -LinkType Member -Links $userUPN

Connect-AzureAD -Credential $credential



