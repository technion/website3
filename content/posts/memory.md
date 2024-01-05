---
title: Windows 11 - Enable "Firmware Protection" by InTune or otherwise
description: Using InTune or otherwise, you may struggle to enable Microsoft's feature "Firmware Protection"
date: 2024-01-05
social_image: '/media/images/somuchwin.png'
tags: [InTune, Windows 11, Firmware Protection]
---
## Windows 11 - Firmware Protection setting is not simply a setting

Most of these can be turned on using fairly obvious means. However, if you find yourself staring a screen like you this may not be alone:

![Firmware Protection Off Windows 11](/media/images/firmwareprotectionoff.png)

Seeing the warning *Firmware Protection is off. Your device may be vulnerable* is something you probably would like to fix. And you may come across a lot of threads on various forums explaining the InTune or Group Policies associated with this. You may find yourself helpfully looking through a series of Reddit threads with people asserting it's easy, only to find you just can't make the setting stick.

A good first place to look is `msinfo32`, where you may see `Secure Launch` is `Configured` but not `Running`. It's not that you haven't figured out how to use InTune properly to enable Firmware Protection (known as System Guard). Microsoft does note that older CPUs don't support the feature, but I known mine does, it's clearly in the spec sheet:

https://www.intel.com/content/www/us/en/products/sku/226259/intel-core-i71255u-processor-12m-cache-up-to-4-70-ghz/specifications.html

## Windows 11's feature requires TXT support in your BIOS
I'm sitting on a business class, HP Elitebook only a few months old, but it turns out this issue is because the Intel Trusted Execution Technology (TXT) feature, which ships with the CPU, isn't supported by the BIOS. You'll see this here, with an event log I cannot find a reference to anywhere online.

![TXT Disabled in BIOS](/media/images/txtdisabled.png)

I have no knowledge of whether this persists across other vendors, but threads complaining noone can setup InTune right for this feature are common. As far as I can see, InTune only keeps coming up because people working on new baselines for Windows 11 are probably using InTune.

The manual for this model of laptop actually describes a BIOS setting to enable the TXT feature - but with the latest BIOS it simply isn't there. I've had a case open for a while and it appears to be acknowledged, and I'll update this blog as information becomes available.