---
title: Enumerating Azure Federated Domains
description: Discovering more than just subdomains 
date: 2018-05-09
tags: [AzureAD, enumeration]
---

## Enumeration Introduction

There are a wealth of blog posts and tools for enumerating domains. This is often the first step of an engagement and can allow things to play out like this:

- Your target is lolware.net
- You cannot find any vulnerabilities at https://lolware.net
- There is a waiting vulnerability at https://ctadvisor.lolware.net, if only you knew the domain existed


Most of the automated tooling however is focused on subdomains.

## Outside the Subdomain

Several notable write ups have identified totally separate domains utilising sheer luck. For example, looking at any facebook.com page will probably lead an attacker to knowing about the existence of fbcdn.net.

## Enter Microsoft Exchange Federation

Microsoft Exchange includes a "Federation" feature. Microsoft document the feature here: [https://technet.microsoft.com/en-us/library/dd335047(v=exchg.150).aspx](https://technet.microsoft.com/en-us/library/dd335047(v=exchg.150).aspx)

Although this is an optional feature for Exchange on-premises, the advantage we have is:

- Workers are increasingly requesting this feature
- It is enabled by default in Exchange Online

## Federation Involves Telling the World What You Have

The crux of this article is in the form of the [Get-FederationInformation](https://docs.microsoft.com/en-us/powershell/module/exchange/federation-and-hybrid/get-federationinformation?view=exchange-ps) command.

Simply connect to Exchange Online, or open Powershell on any Exchange server.

```powershell
PS > $UserCredential = Get-Credential

cmdlet Get-Credential at command pipeline position 1
Supply values for the following parameters:
Credential
PS > $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office36
5.com/powershell-liveid/ -Credential $UserCredential -Authentication  Basic -AllowRedirection
PS > Import-PSSession $Session
```

And with that in place, let's run the command against a domain currently making front page news:

```powershell
PS > $fedinfo = Get-FederationInformation -DomainName amp.com.au
PS > $fedinfo.DomainNames
mws-email.amp.com.au
amp.com.au
ampadvice.com.au
ampbanking.com.au
ampcapital.com
hillross.com.au
ipac.com.au
```

If you were pentesting AMP, you have a range of domains to be throwing traditional subdomain enumeration tools at right there.

For a particularly interesting example look at Microsoft - just be aware the command will lag your session for a while.

```powershell
PS > $fedinfo = Get-FederationInformation -DomainName microsoft.com
PS > $fedinfo.DomainNames
microsoft.onmicrosoft.com
microsoft.com
service.microsoft.com
xbox.com
microsoft.mail.onmicrosoft.com
skype.net
perceptivepixel.com
healthvault.com
nuvolarosa.eu
fieldone.com
adxstudio.com
msfts2.mail.onmicrosoft.com
microsoftstudios.com
shadmorris.com
linkedin.com
domains.microsoft
acompli.com
Intentional.com
```
