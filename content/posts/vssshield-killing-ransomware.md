---
title: How vssshield kills ransomware
description: Live demonstration of vssshield protecting shadow copies
date: 2022-11-05
social_image: '/media/images/somuchwin.png'
tags: [ransomware, shadow copies]
---
## Ransomware using vssadmin

Ransomware has a long history of deleting shadow copies from an infected machine, in an attempt to hinder recovery. It's relevant to keep in mind that doing so requires local administrator permissions, so where it does not have those, some ransomware can be recovered from using Shadow Copies. A famous ransomware example is Wannacry, documented below to use this attack.

https://www.mcafee.com/blogs/other-blogs/executive-perspectives/analysis-wannacry-ransomware-outbreak/

Where it is documented:

*By using command-line commands, the Volume Shadow copies and backups are removed:*

`Cmd /c vssadmin delete shadows /all /quiet & wmic shadowcopy delete & bcdedit /set {default} bootstatuspolicy ignoreallfailures & bcdedit /set {default} recoveryenabled no & wbadmin delete catalog -quiet`

You can also see a discussion here on the rise of relevant malware:

https://www.bleepingcomputer.com/news/security/why-everyone-should-disable-vssadminexe-now/

## Prior Art

I'm taking no credit for this stragegy - Raccine implements a similar protection feature. It's written by an extremely good security professional, and if you have concerns about my code, by all means use that.

https://github.com/Neo23x0/Raccine

The goal here is not to lock vssadmin from being run - the goal is to kill the application attempting to use it to delete shadow copies.


## vssshield

vsshshield was built as an absolutely minimal Rust application, designed to perform this one functionality.

https://github.com/technion/vssshield

It was also a "learn Rust" project, so always code feedback is welcome.

## Demonstration Lab

Windows 2019 with vssshield. We've obtained a sample of the Avvadon ransomware, which at this point has a lot of alarm bells on virustotal:

![Avadon virustotal](/media/images/vssshield/avadon_virustotal.png)

We have of course disabled Windows Defender from eating our sample, and we've installed vssshield using the supplied Powershell script on the Github repo:

```
PS C:\Users\Administrator\Downloads> .\Install-vssshield.ps1

    Directory: C:\Program Files


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
d-----        5/11/2022   7:36 PM                vssshield
Vssshield has been installed


PS C:\Users\Administrator\Downloads>
```

Now lets test it's functional, and that shadow copies can still be created and listed:

```
PS C:\Users\Administrator\Downloads> . "c:\Program Files\vssshield\vssshield.exe"
Intercepting with vssshield version v0.2

    ====================
    Lolware.net
    ====================


PS C:\Users\Administrator\Downloads> vssadmin create shadow /for=c:
Intercepting with vssshield version v0.2
vssadmin 1.1 - Volume Shadow Copy Service administrative command-line tool
(C) Copyright 2001-2013 Microsoft Corp.

Successfully created shadow copy for 'c:\'
    Shadow Copy ID: {df5fb887-f8fc-469c-a34f-0afab7ed7577}
    Shadow Copy Volume Name: \\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy1
PS C:\Users\Administrator\Downloads> vssadmin list shadows
Intercepting with vssshield version v0.2
vssadmin 1.1 - Volume Shadow Copy Service administrative command-line tool
(C) Copyright 2001-2013 Microsoft Corp.

Contents of shadow copy set ID: {97c32e98-9ee9-470f-aa54-b95b09407c02}
   Contained 1 shadow copies at creation time: 5/11/2022 8:23:44 PM
      Shadow Copy ID: {df5fb887-f8fc-469c-a34f-0afab7ed7577}
         Original Volume: (C:)\\?\Volume{fcefd24b-086c-4cf5-a3db-4f945446fd91}\
         Shadow Copy Volume: \\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy1
         Originating Machine: WIN-K94VJNSR5PA
         Service Machine: WIN-K94VJNSR5PA
         Provider: 'Microsoft Software Shadow Copy provider 1.0'
         Type: ClientAccessible
         Attributes: Persistent, Client-accessible, No auto release, No writers, Differential

```

And before we run anything dangerous, we have of course deployed sysmon. I recommend the configuration here, particularly considering the MDE augmentation for business deployments:

https://github.com/olafhartong/sysmon-modular

## Running the sample

I would be irresponsible of course, to point out that despite my confidence this is safe, this activity was performed on an isolated virtual server, ready to be deleted after actions.

We've also included in our screenshot a SHA256 check, so you can confirm we did in fact run the virustotal sample.

Of course I was literally about to hit "go" when this happened.

![Screwed by Windows Update](/media/images/vssshield/windows_update.png)

Anyway, half an hour later, here we go.

![Running Avaddon Ransomware](/media/images/vssshield/abexecute.png)

This sample did something I found uncommon, and launched its attempts to clear shadow copies in a console session, allowing you to see the debugging vssshield ran. This was on the screen for a few seconds before everything was killed.

![Killing Avaddon Ransomware](/media/images/vssshield/avkill.png)

## Confirming the machine's status

Here we see my perfectly reasonable spreadsheet hasn't been encrypted, and the shadow copies are still on disk.

![Data intact](/media/images/vssshield/intact.png)

Now of course, seeing this scenario play out is going to depend on the specifics of the malware in question, but that's why we call this a mitigation as opposed to anything else.
