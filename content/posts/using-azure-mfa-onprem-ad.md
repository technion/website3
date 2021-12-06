---
title: Using Azure MFA for on premises Active Directory
description: Protecting assets with Azure MFA without going cloud
date: 2021-12-02
social_image: '/media/images/somuchwin.png'
tags: [onprem, active directory, mfa]
---
## On premise Active Directory - Getting MFA 
This question, "how can I implement MFA with my on premise Active Directory", has come up an awful lot recently. Much of this comes down to Microsoft's great MFA offerings in the cloud, and people wanting their more "at risk" environments to utilise similar capabilities. A very common answer is "just deploy DUO on RDP for servers", but in my view this is a really poor solution. It doesn't cover the majority of practical ways an attacker can abuse privileges.

I recommend this article on why a lot of "easy" solutions don't work: [https://syfuhs.net/mfa-is-hard-to-do-right](https://syfuhs.net/mfa-is-hard-to-do-right).

Microsoft *does* offer an NPS plugin, which is designed for use with specific services such as Remote Desktop Gateways and VPNs. It's done a lot of good for security across the board, but building the functionality and then leaving it there doesn't quite close the gap people need.
## Download the Microsoft NPS MFA Extension
You'll be greeted with two interesting bugs here. Firstly, there's no setup.exe here (as per installation instructions) as the installer is named NpsExtnForAzureMfaInstaller.exe. But also, it doesn't matter what you put in this install location. It's going to install in `C:\Program Files\Microsoft\AzureMfa\` no matter what.

![Installing Azure MFA NPS Extension](/media/images/mfaext/extensioninstall.jpg)

In fact to complete this guide you don't need the full installation, you just need the installation Powershell script Microsoft supplies. And believe it or not, you can run this NPS extension perfectly fine on a server with no NPS role. Below shows what this looks like.

```
PS C:\Program Files\Microsoft\AzureMfa\Config> .\AzureMfaNpsExtnConfigSetup.ps1
# Verbose nonsense
Connecting to Microsoft Azure.  Please sign on as a tenant administrator.
Starting Azure MFA NPS Extension Configuration Script
Provide your Tenant ID For Self-Signed Certificate Creation: 5cf5711c-b183-4db4-ad89-X
Generating client certificate

Thumbprint                                Subject
----------                                -------
5DF88FF86F6041DD8D8AD6023673087B1CBCDC85  CN=5cf5711c-b183-4db4-ad89-4c0635737d3f, OU=Microsoft NPS Extension
Client Certificate successfully generated
Client Certificate associated with Service Principal: 981f26a1-7f43-403b-a875-f8b09b8cd720
Starting registry updates
Completed registry updates
Client certificate : CN=5cf5711c-b183-4db4-ad89-4c0635737d3f, OU=Microsoft NPS Extension successfully associated with Azure MFA NPS Extension for Tenant ID: 5cf5711c-b183-4db4-ad89-X
Granting certificate private key access to NETWORK SERVICE
Successfully granted to NETWORK SERVICE
Restarting Network Policy Server (ias) service
Restart-Service : Cannot find any service with service name 'ias'.
At C:\Program Files\Microsoft\AzureMfa\Config\AzureMfaNpsExtnConfigSetup.ps1:106 char:1
+ Restart-Service -Force ias
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : ObjectNotFound: (ias:String) [Restart-Service], ServiceCommandException
        + FullyQualifiedErrorId : NoServiceFoundForGivenName,Microsoft.PowerShell.Commands.RestartServiceCommand

        Configuration complete.  Press Enter to continue...:
```
There's one error output, where it fails to restart the service that doesn't exist right at the end. We can ignore that.

## Replicating the MFA push

This section details how we worked out the process, which you can skip if you just want to impelement it. And frankly, it shows you there's nothing to this more than writing Powershell to use existing functionality.

If you look through the script we just ran, you can see it activated an Azure application. It setup a Service Principal for using that application, and it created a certificate to act as a key to that application. You can see all these things in the Azure portal, and you can see that certificate here:

```
PS C:\Program Files\Microsoft\AzureMfa\Config> Get-ChildItem cert:LocalMachine\My | fl


Subject      : CN=5cf5711c-b183-4db4-ad89-4c0635737d3f, OU=Microsoft NPS Extension
Issuer       : CN=5cf5711c-b183-4db4-ad89-4c0635737d3f, OU=Microsoft NPS Extension
Thumbprint   : 5DF88FF86F6041DD8D8AD6023673087B1CBCDC85
FriendlyName :
NotBefore    : 1/12/2021 8:07:39 PM
NotAfter     : 1/12/2023 8:07:39 PM
Extensions   : {System.Security.Cryptography.Oid}

```

Once you have an authentication certificate for Azure, you can use the awesome `MSAL.PS` module to interact with it. There's a great guide on it here.

https://blog.darrenjrobinson.com/microsoft-graph-using-msal-with-powershell-and-certificate-authentication/

The convenient thing about the NPS extension script is it creates some convenient registry keys we can use directly with MSAL.PS. Below shows how to grab an authentication token using the keys and information the NPS extension builds for us:

```

Import-Module -name MSAL.PS
$AzureConfig = Get-ItemProperty HKLM:\SOFTWARE\Microsoft\AzureMfa\
$ClientCertificate = Get-Item "Cert:\LocalMachine\My\5DF88FF86F6041DD8D8AD6023673087B1CBCDC85"
$myAccessToken = Get-MsalToken -ClientId $AzureConfig.CLIENT_ID -TenantId $AzureConfig.TENANT_ID -ClientCertificate $ClientCertificate -Scopes "https://adnotifications.windowsazure.com/StrongAuthenticationService.svc/Connector/.default"
$headers = @{ "Authorization" = "Bearer $($myAccessToken.AccessToken)" }
$headers

Name                           Value
----                           -----
Authorization                  Bearer xxx... 

```
The only thing that wasn't obvious is the Scope parameter. I'll get to that.

So given we had a fully working authorisation and just needed the API to use it, the obvious thing to do is open up the .dll that ships with the extension. Specifically, `MfaNpsAuthzExt.dll`. A quick string search shows some obvious candidates.

![MfaNpsAuthzExt.dll strings](/media/images/mfaext/ghidrastrings.jpg)

By looking at where those strings are used, you can find a complete XML template in the midst of the string assembling it.

![MfaNpsAuthzExt.dll XML](/media/images/mfaext/mfaxml.jpg)

Armed finally with some key phrases, you find the one single hit on Google that describes the XML in question. On page that that seemed buried during hours of searches on this problem, it seems someone's used a different reverse engineering process and produced a working script with similar goals.

![MfaNpsAuthzExt.dll XML](/media/images/mfaext/onesinglegoogle.jpg)

I'm going to stick with our authentication and setup (certificates are much more secure after all) but we'll grab the URL from there to save a few hours in Ghidra.

Indeed, the following immediately sends an MFA push to my phone:

```
$EmailToPush = "technion@lolware.net"
$XML = @"
<BeginTwoWayAuthenticationRequest>
<Version>1.0</Version>
<UserPrincipalName>$EmailToPush</UserPrincipalName>
<Lcid>en-us</Lcid><AuthenticationMethodProperties xmlns:a="http://schemas.microsoft.com/2003/10/Serialization/Arrays"><a:KeyValueOfstringstring><a:Key>OverrideVoiceOtp</a:Key><a:Value>false</a:Value></a:KeyValueOfstringstring></AuthenticationMethodProperties><ContextId>69ff05bf-eb61-47f7-a70e-e7d77b6d47d0</ContextId>
<SyncCall>true</SyncCall><RequireUserMatch>true</RequireUserMatch><CallerName>radius</CallerName><CallerIP>UNKNOWN:</CallerIP></BeginTwoWayAuthenticationRequest>
"@

$obj = Invoke-RestMethod -uri 'https://adnotifications.windowsazure.com/StrongAuthenticationService.svc/Connector/BeginTwoWayAuthentication' -Method POST -Headers $headers -Body $XML -ContentType 'application/xml'
```

Unfortunately at this point this project experienced some additional technical difficulties as seen below.

![MfaNpsAuthzExt.dll XML](/media/images/mfaext/marcel.jpg)

## Using it for privilege management
But, I hear you ask, "I was promised a way to use this in a domain". Fortunately I already had Microsoft JEA (Just Enough Administration) scripts lying around for use in temporarily elevating privileges. Based loosely on scripts [previously described here](/blog/2019-07-13-ad-security-with-pam/) you can find one below which uses the above process to temporarily promote a user to a Domain Admin, with an MFA check.

Any time limited group membership will require the PAM feature enabled in AD:
```
Enable-ADOptionalFeature 'Privileged Access Management Feature' -Scope ForestOrConfigurationSet -Target ad.lolware.net
```

You've got three small issues that complicate things. The first is that a token from Get-MSALToken has a lifespan of 24 hours. It's not something you're meant to constantly request new. The second is that MSAL.PS refuses to operate from JEA, or apparently when doing ["run as user"](https://github.com/AzureAD/MSAL.PS/issues/44). Our workaround is going to start with a scheduled task, which continues the pattern of storing content under the AzureMfa registry key. I have it run every six hours.

```
$ErrorActionPreference = "Stop"

$AzureConfig = Get-ItemProperty HKLM:\SOFTWARE\Microsoft\AzureMfa\
$ClientCertificate = Get-Item "Cert:\LocalMachine\My\5DF88FF86F6041DD8D8AD6023673087B1CBCDC85"
$myAccessToken = Get-MsalToken -ClientId $AzureConfig.CLIENT_ID -TenantId $AzureConfig.TENANT_ID -ClientCertificate $ClientCertificate -Scopes "https://adnotifications.windowsazure.com/StrongAuthenticationService.svc/Connector/.default"
New-ItemProperty "HKLM:\SOFTWARE\Microsoft\AzureMfa\"  -Name "AzureToken" -Value $myAccessToken.AccessToken -Force

```

## Using the Access Token with JEA

Below we have a Powershell script that registers a JEA configuration, which uses an MFA verifier before promoting a user temporarily to Domain Admin.

```
# Create a module in Program Files for the JEA roles
$modulePath = "$env:ProgramFiles\WindowsPowerShell\Modules\JEARoles"
New-Item $modulePath -ItemType Directory -Force
New-ModuleManifest -Path (Join-Path $modulePath "JEARoles.psd1") -Description "Contains custom JEA Role Capabilities"

# Create a folder for the role capabilities
$roleCapabilityPath = Join-Path $modulePath "RoleCapabilities"
New-Item $roleCapabilityPath -ItemType Directory

# Define the function for checking out permissions
$adminFnDef = @{
    Name = 'MFA-Elevate'
    ScriptBlock = {
        param([Parameter(Mandatory)]$username)
        $ErrorAction = 'Stop'
        $aduser = Get-ADUser $username -properties memberof, mail -ErrorAction SilentlyContinue
        if (! $aduser ) {
            Write-Output "Unable to find user $username"
            return
        }
        if ($aduser.MemberOf -notcontains "CN=CanElevate,CN=Users,DC=ad,DC=lolware,DC=net") {
            Write-Output "User is not in required group"
            return    
        }
        $AzureConfig = Get-ItemProperty HKLM:\SOFTWARE\Microsoft\AzureMfa\
        $headers = @{ "Authorization" = "Bearer $($AzureConfig.AzureToken)" }
        $EmailToPush = $aduser.mail
$XML = @"
<BeginTwoWayAuthenticationRequest>
<Version>1.0</Version>
<UserPrincipalName>$EmailToPush</UserPrincipalName>
<Lcid>en-us</Lcid><AuthenticationMethodProperties xmlns:a="http://schemas.microsoft.com/2003/10/Serialization/Arrays"><a:KeyValueOfstringstring><a:Key>OverrideVoiceOtp</a:Key><a:Value>false</a:Value></a:KeyValueOfstringstring></AuthenticationMethodProperties><ContextId>69ff05bf-eb61-47f7-a70e-e7d77b6d47d0</ContextId>
<SyncCall>true</SyncCall><RequireUserMatch>true</RequireUserMatch><CallerName>radius</CallerName><CallerIP>UNKNOWN:</CallerIP></BeginTwoWayAuthenticationRequest>
"@

         $obj = Invoke-RestMethod -uri 'https://adnotifications.windowsazure.com/StrongAuthenticationService.svc/Connector/BeginTwoWayAuthentication' -Method POST -Headers $headers -Body $XML -ContentType 'application/xml'
         if($obj.BeginTwoWayAuthenticationResponse.AuthenticationResult -eq $true) {
             Write-Output "Making you a domain admin"
             Add-ADGroupMember -Identity "Domain Admins" -Members $aduser -MemberTimeToLive (New-TimeSpan -Minutes 15)
         } else {
             Write-Output "Unfortunately your request was denied or failed"
         }
      }
}

New-PSRoleCapabilityFile -Path (Join-Path $roleCapabilityPath "MFA-Elevate.psrc") -FunctionDefinitions $adminFnDef -ModulesToImport ActiveDirectory
# Pick location for file and security groups
$jeaConfigPath = "$env:ProgramData\MFAElevateConfiguration"
$accessGroup   = "LOLWARE\CanElevate"

 
# Create the session configuration file
New-Item $jeaConfigPath -ItemType Directory -Force
New-PSSessionConfigurationFile -Path (Join-Path $jeaConfigPath "MFA-Elevate.pssc") -SessionType RestrictedRemoteServer -TranscriptDirectory (Join-Path $jeaConfigPath "Transcripts") -RunAsVirtualAccount -RoleDefinitions @{ $accessGroup = @{ RoleCapabilities = 'MFA-Elevate' }; } -ModulesToImport ActiveDirectory
 
# Register the session configuration file
Register-PSSessionConfiguration -Name MFA-Elevate -Path (Join-Path $jeaConfigPath "MFA-Elevate.pssc") -Force
```

## In Action

With all the above in place, the below shows how it looks. In this example, you can see that the "noprivs" user has no special privileges. It's an ordinary user account, notably in the "CanElevate" group. This should be thought of as your admin user (ie, not your desktop account) due to its ability to perform the elevation.

```
PS C:\Users\noprivs> whoami
lolware\noprivs

PS C:\Users\noprivs> Get-ADUser noprivs -properties memberof |select -ExpandProperty memberof
CN=CanElevate,CN=Users,DC=ad,DC=lolware,DC=net

Enter-PSSession WIN-4TR8CBBT8SH -ConfigurationName MFA-Elevate
[WIN-4TR8CBBT8SH]: PS>MFA-Elevate

cmdlet MFA-Elevate at command pipeline position 1
Supply values for the following parameters:
username: noprivs
Making you a domain admin

PS C:\Users\noprivs> Get-ADUser noprivs -properties memberof |select -ExpandProperty memberof
CN=CanElevate,CN=Users,DC=ad,DC=lolware,DC=net
CN=Domain Admins,CN=Users,DC=ad,DC=lolware,DC=net
```
So after opening the JEA configuration and running the `MFA-Elevate` function, you become Domain Admin. But with the caveat:
- Only if you can pass a Microsoft Authenticator based MFA check
- This permission is time limited for 15 minutes. Note, group membership applies at logon. If you logon to a server and you're still fixing something in 20 minutes, you won't lose privileges.

Using this you can go and RDP to a domain controller or whatever you need to do that requires a secure account.
## Breaking Glass

For obvious reasons you will want a break glass around to avoid the MFA requirement. A good process here is to setup an Azure Sentinel monitor on the built-in Administrator account. This can ensure it isn't being abused. I recommend the below KQL as a starting point:

```
SecurityEvent
| where EventID == 4624
| where AccountType == "User"
| where Account has "Administrator"
| project TimeGenerated, Computer, Activity, IpAddress, TargetAccount
```
## Secure
This strategy solves an awful lot of problems that "add MFA to common things". It doesn't help security quite as much as deploying Microsoft S2D/Microsoft Azure Stack HCI of course.

![Installing Azure MFA NPS Extension](/media/images/mfaext/azhci.jpg)
