---
title: Secure Active Directory management with PAM and JEA
description: Active Directory Domain Just Enough Administration and Privileged Administration
date: 2019-07-13
social_image: '/media/images/somuchwin.png'
tags: [active directory, jea, pam ]
---

## Introduction to the tooling

This tutorial is going to involve combining two Microsoft features: Privileged Access Management, and Just Enough Administration. To explain why this is useful, here's the set of the goals we should be able to acheive with this implementation:

- Compromising an administrator's password shouldn't be overly useful to an attacker
- Compromising an administrator's NTLM hash shouldn't be overly useful to an attacker
- Compromising an administrator's desktop shouldn't be overly useful to an attacker
- Obtaining domain admin access to the production domain doesn't actually grant the highest level of authority
- Admins can avoid typing their passwords as much as possible

Several easy solutions (such as MFA) solve half the puzzle, but not all of it. Let's look at what we're dealing with here.

## Privileged Access Management
Microsoft document this here:
[https://docs.microsoft.com/en-us/microsoft-identity-manager/pam/environment-overview](https://docs.microsoft.com/en-us/microsoft-identity-manager/pam/environment-overview).
To be clear, this is a feature built directly into modern versions of Windows, and an implementation guide is described in the above link. It's when it comes to actually using PAM on a day to day basis, MS' advice runs to "just deploy our MIM product". We're going to describe how to run PAM without MIM.

## Just Enough Administration
This really great feature is sorely lacking in examples. Quoting Sean Metcalf's Blackhat 2017 talk "JEA doc only provides info on how to configure DNS service administration on DCs". In 2019, nothing has changed. You can see this on [Microsoft's JEA landing page](https://docs.microsoft.com/en-us/powershell/jea/overview), which has a link to a "samples" page with a total of two samples.
Let's build a JEA module and change that.

## High level overview
The short summary of what we are going to do here:

- Build a PAM domain. Depending what documentation you read, you may find this referred to as a Microsoft ESAE domain, a red domain, a bastian domain, and probably other names. This is essentially domain that's "in charge" of the production domain.
- Setup a Privileged Access Workstation for a sysadmin
- Create a JEA policy that allows a time limited privileged escalation

## The lab
Our domains are going to be called PRODLAB, and ESAELAB.
   
### Building the production domain
For our first magic trick, we're going to build an entirely boring new domain representing our production network. As a side note, it's interesting that Windows 2019 still presents this warning about Windows NT 4.0 compatibility.

![Promote a Domain Controller](/media/images/pam/1-promotelab.png)

### Promoting an ESAE DC
Of all the various terminology options, we're going to call our PAM domain an ESAE domain throughout this guide. Straight away it should be recognised, this whole domain should be void of any of the issues that cause weaknesses. For example, there won't be a vendor on this domain requiring SMBv1. And if there is, go back to the whiteboard.

![Promote a Domain Controller](/media/images/pam/2-promoteesae.png)

### Stub Zones
Both of these domains need to talk to each other - setup stub zones to make resolution easy.

![Stub DNS zones](/media/images/pam/3-stubzone.png)

Your finished product should look a bit like this.

![Stub DNS zones](/media/images/pam/4-stubsetup.png)

## Enabling the PAM feature
Privileged Access Management is an optional Active Directory feature. Running a single command enables this feature, as we see below.

![Enabling PAM feature in production](/media/images/pam/5-prodenablepamfeature.png)

## ESAE enable PAM 
The PAM feature should be enabled in both domains.

![Enable PAM feature in ESAE domain](/media/images/pam/6-esasenablepamfeature.png)

## Creating a PAM trust
A PAM trust is a special kind of one way trust - it gives the ESAE domain full privileges over the production domain. Microsoft's own documentation for PAM refers to a series of Powershell scripts we haven't installed, but the "netdom" documentation has everything you need.

![Creating a PAM trust](/media/images/pam/7-createtrust.png)

### Enable AES support on the trust
Enable AES support on the trust for added security.

![Enabling AES support on the PAM trust](/media/images/pam/8-aesontrust.png)

### Shadow Principal Script
This is the first part of the guide where some of the real magic occurs. Remember the ESAE domain, based on the above trust, is now "in charge". It even has the ability to decide that a user in a group on the ESAE domain is a "Domain Admin" in the PROD domain.
This is done by use of a "Shadow Principal", in tihs case, a shadow principal for Domain Admins. You can save yourself a Sharepoint deployment by running the Powershell examples found around the web. A copy of the script on the ["Prevenity" Github account](https://github.com/Prevenity/AD-Hardening/blob/master/5_Shadow_Principal_set_up.txt) is going to be our guideline.


### Creating shadow principals
Here we make a shadow of the PRODLAB\Domain Admins group in the ESAE domain. Users added to the shadow become Domain Admins in the production domain. It's just a paste of the above script.

![Creating a shadow of Domain Admins](/media/images/pam/10-makeshadows.png)

## Privileged Access Workstation Implementation
We haven't implemented the entirety of the MS PAM lockdown, but we have taken a "bang for your buck" approach and implemented a small number of the most effective security policies.
We achieve one of the goals of our deployment just by ensuring noone is surfing the Internet, reading email, or generally performing "high risk" activities on the PAW.

![PAM GPOs](/media/images/pam/11-pawgpos.png)

### Domain Controller Management
A key firewall rule here on the Domain Controllers limits remote access to our PAM machines. This effectively implements another of our security requirements: we've made the PAW hard to compromise, and now we make management require access to the PAW. Of course, you can add a whole network segment if you have enough admins.

![WinRM Firewall Rules](/media/images/pam/12-dcwinrm.png)

### Restricted Admin Control
Setting up Restricted Admin on our production servers allows us to logon without typing the password again. I know what you're thinking, "not requiring a password" is usually a bad thing in our security requirement. The thing we get out of Restricted Admin is that when a server is never given an admin's password, it's sevely limited against leaks from that server. It also prevents various forms of lateral movement from that server.
If we accept the PAW is already a privileged machine, passing through the current crential isn't a threat.

![Restricted Admin Access](/media/images/pam/14-restrictedadmin.png)

### Restricted Admin on client
This GPO will tell the client to use Restricted Admin.

![Remote Desktop Client](/media/images/pam/15-clientadmin.png)

### Banning Domain Admins on PAW
The PAW machine (like all workstations should) bans logons as Domain Admin. Despite calling it "privileged", we're not actually logging on as a Domain Admin every time we use it.

![Deny Domain Admin access](/media/images/pam/16-adminbannedonpaw.png)

### Time Limited Group Membership
One of PAM's greatest features is the "time limited group member". This allows us to implement another of our security goals - compromise of the administrator's credential hash is mitigated (but not removed) by a time limited escalation.
The below command will add the user "prodadmin" Domain Admin Shadow Principal with a TTL of 300 seconds. In effect, you have made a five minute domain admin.

![Time limited group membership](/media/images/pam/17-ttladd.png)

### Creating a JEA policy
And although there are several guides on using PAM, the above is as far as it goes. However, the exact method by which a user performs this activity is a bit open.
Here, we're going to create a JEA policy. Given the above firewall rule, this is a JEA policy which can only actually be run from the PAW.

``` powershell

# Create a module in Program Files for the JEA roles
$modulePath = "$env:ProgramFiles\WindowsPowerShell\Modules\JEARoles"
New-Item $modulePath -ItemType Directory -Force
New-ModuleManifest -Path (Join-Path $modulePath "JEARoles.psd1") -Description "Contains custom JEA Role Capabilities"

# Create a folder for the role capabilities
$roleCapabilityPath = Join-Path $modulePath "RoleCapabilities"
New-Item $roleCapabilityPath -ItemType Directory

# Define the function for checking out permissions
$adminFnDef = @{
    Name = 'Make-Admin'
    ScriptBlock = {
      $ProdPrincipal = "Domain Admins"
      $ProdDC = "prod.prod.lab.net"
      $ShadowSuffix = "PROD-"
      $ProdShadowPrincipal = Get-ADGroup -Identity $ProdPrincipal -Properties ObjectSID -Server $ProdDC
      $ShadowPrincipalContainer = "CN=Shadow Principal Configuration,CN=Services,"+(Get-ADRootDSE).configurationNamingContext
      $prodcn =(Get-ADUser prodadmin).DistinguishedName
      Set-ADObject -Identity "CN=$ShadowSuffix$ProdPrincipal,$ShadowPrincipalContainer" -Add @{'member'="<TTL=300,$prodcn>"}
      }
}

New-PSRoleCapabilityFile -Path (Join-Path $roleCapabilityPath "makeAdmin.psrc") -FunctionDefinitions $adminFnDef
# Pick location for file and security groups
$jeaConfigPath = "$env:ProgramData\JEAConfiguration"
$accessGroup   = "ESAELAB\Production Admins"

 
# Create the session configuration file
New-Item $jeaConfigPath -ItemType Directory -Force
New-PSSessionConfigurationFile -Path (Join-Path $jeaConfigPath "makeAdmin.pssc") -SessionType RestrictedRemoteServer -TranscriptDirectory (Join-Path $jeaConfigPath "Transcripts") -RunAsVirtualAccount -RoleDefinitions @{ $accessGroup = @{ RoleCapabilities = 'makeAdmin' }; }
 
# Register the session configuration file
Register-PSSessionConfiguration -Name MakeAdmin -Path (Join-Path $jeaConfigPath "makeAdmin.pssc") -Force
```
### Using JEA to escalate privileges
With the policy in place, the "prodadmin" user on the PAW can run a simple command to give themselves time limited Domain Admin membership.

![Using JEA to escalate privileges](/media/images/pam/19-useescalation.png)

### And now we are a domain admin
Here we can see ourselves in the Domain Admins group for the PROD domain - just for five minutes. Even though we are actually an account on the ESAE domain.

![Now we are a domain admin](/media/images/pam/20-nowadmin.png)

### Before escalation
Before running the privilege escalation script, you'll note you cannot RDP to the production environment. This is what you've expect if an average user tries to RDP to a Domain Controller.

![No privileges](/media/images/pam/21-nologon.png)

### After escalation
After escalation, the RestrictedAdmin setup passes you straight through to the server.

![RDP Restricted Admin](/media/images/pam/22-nopassword.png)

## Improvements
The glaring thing in the above is that we didn't deploy a CA and signing infrastructure in our lab - but in production you'd expect to do so. A key improvement after that would be to look at MFA on the ESAE domain.
