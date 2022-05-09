---
title: Using Microsoft Sentinel to roll honey tokens on Windows
description: Exploit poc
date: 2022-05-09
social_image: '/media/images/somuchwin.png'
tags: [kusto, sentinel, honeytoken]
---
## Credentials in Your Environment

A recurrent theme in both real life attacks and penetration tests has been the scanning of local networks for spreadsheets full of data. Many people simply don't believe such things aren't worth looking for to real world attackers, but the highly publicised breach on Okta shows just one great counter example: https://techcrunch.com/2022/03/28/lapsus-passwords-okta-breach/

You may also want to consider the existence of tools such as Snarfler.

There are plenty of tools and products designed to alert you *after a credential is used*. However, here we believe we can provide an earlier warning system.

## An Attractive Target

A common tool utilised on engagements is "crackmapexec", or similar tools which absolutely will find those shares that end users typically don't use. This is important because you don't want an end user legitimately stumbling across such a file.

![An example honeypot file](/media/images/honeytoken/honeytoken1.jpg)

Of course that folder is shared, so network users are going to find \\SERVER\ITSupport\Password List.xlsx.

## Generating Event Logs

We're going to use Windows File Access Auditing to generate an event the moment a user opens that file. This needs to be enabled globally on the server, hopefully using a GPO, as here:

![An example honeypot file](/media/images/honeytoken/honeytoken2.jpg)

And then enable auditing on the file properties. Assigning "Domain users" or similar to the ACL ensures that SYSTEM services such as antivirus don't fill your logs.

![An example honeypot file](/media/images/honeytoken/honeytoken3.jpg)

Touching that file should give you an associated event log. Armed with the knowledge that event 4663 logs an event like this, we can setup monitoring.

![An example honeypot file](/media/images/honeytoken/honeytoken4.jpg)

## Microsoft Sentinel Detection

In a default Microsoft Sentinel configuration, the above log is one which is shipped to the cloud and available for interrogation.

Open up Sentinel and hit up "Analytics". Specifically, https://portal.azure.com/#blade/Microsoft_Azure_Security_Insights/MainMenuBlade/Analytics/ and start creating a new rule. I could create a series of screenshots, but they are all here: https://docs.microsoft.com/en-us/azure/sentinel/detect-threats-custom

Here's the simple script that we need:
```kusto
SecurityEvent
| where Computer == "myserver.fqdn.com"
| where EventID == 4663
| where ObjectName == "C:\\ITSupport\\Password List.xlsx"
| project TimeGenerated, Account, Computer, ObjectName
```

You can see it filters down to the node in question, and then the file, and produces a query of only the most useful data.

Also described in the above Microsoft document is "automated responses", from which you may just be able to shutdown an in flight attack before becoming a victim. 