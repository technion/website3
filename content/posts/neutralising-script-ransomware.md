---
title: Neutralising Script Based Ransomware
description: Neutralising Script based ransomware
date: 2021-07-25
social_image: '/media/images/somuchwin.png'
tags: [ransomware, scripts]
---

## Scripts causing ransomware

In modern times, Microsoft Windows has gotten better about protecting users from untrustworthy executables. You may be familiar with this warning, which is more effective than the community often gives it credit for:

![Smartscreen Alert](/media/images/smartscreen.jpg)

Due to this, a substantive portion of security incidents, including ransomware, rely on Windows Scripting Host and it's relatively legacy design that does not behave like this. For an example, if I email a person a link to a .zip file containing a .vbs file, there's a very good chance it will end up executed.

## Conti Ransomware

To demonstrate this isn't one of those theoretical nothings, here's a great write up from the DFIR report describing a Conti ransomware incident in which they say: _We assess with moderate confidence that the initial vector used by the threat actor was a zip file, which included a malicious JavaScript file_.

[https://thedfirreport.com/2021/05/12/conti-ransomware/](https://thedfirreport.com/2021/05/12/conti-ransomware/)

## REvil

Not to be outdone, here's a discussion of a particular REvil ransomware campaign utilising the same method:

https://www.bleepingcomputer.com/news/security/gootkit-malware-returns-to-life-alongside-revil-ransomware/

## Existing Mitigations

The best known mitigation is somewhat of a hack - assign these extensions to notepad. Here we see this recommended by Sophos: [https://nakedsecurity.sophos.com/2016/04/26/ransomware-in-your-inbox-the-rise-of-malicious-javascript-attachments/](https://nakedsecurity.sophos.com/2016/04/26/ransomware-in-your-inbox-the-rise-of-malicious-javascript-attachments/)

And here is webroot, who include it in a Malware Prevention Guide:
[https://answers.webroot.com/Webroot/ukp.aspx?pid=17&app=vw&vw=1&solutionid=2637](https://answers.webroot.com/Webroot/ukp.aspx?pid=17&app=vw&vw=1&solutionid=2637)

There are many various blogs and security companies with similar recommendations, but the above two are the most telling as these large vendors have a financial incentive towards selling commercial products as opposed to having people roll out such effective mitigations at no cost.

There are two issues with this hack however:
- The output to the user is a big screen of obsfuscated scripting. They likely have no idea what it means.
- There is no alerting to defender and no way of monitoring when this protection is tripped

## An Evolution on Notepad

To this end, I've written a fairly simple application named open\_safety. 

What this will, in the case of a file named example.js:
- Rename the file to _DANGEROUS example.js.txt_, neutralising it from being run
- Create a file named _example.js.com_, containing the EICAR string. This will set off alarms on hopefully every AV and EDR product in existence, and send a blue team to come running to your defence.

## Using it

The principle is the same - link these risky extensions to my application instead of notepad. I have created a Powershell script to completely automate the download and install, or a bigger network should have their own more automated option.

When a user tries to double click a script, expect sirens:

![Defender Alarm](/media/images/defender.png)

## Obtaining It

The application, including its source, pre-built binary and an installation script can be found here:

[https://github.com/technion/open\_safety](https://github.com/technion/open_safety)
