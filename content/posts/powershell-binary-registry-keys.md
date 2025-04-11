---
title: Using Powershell to manage binary registry keys
description: Getting and setting REG_BINARY keys
date: 2025-04-11
social_image: '/media/images/somuchwin.png'
tags: [powershell, registry] 
---
# Managing Binary Registry Keys

Microsoft has a guide here on [Working with registry entries](https://learn.microsoft.com/en-us/powershell/scripting/samples/working-with-registry-entries?view=powershell-7.5).

It's pretty good for most purposes but I found it needed an example for a common issue: I have a binary key set correctly on one machine, how do I deploy this? This is pretty common trying to manage certain settings with Intune for example. In this case, we have a printer config.

First, let's get a copy of the current key in hex. It will output a large string.

```powershell
$settings = Get-ItemPropertyValue  -Path "HKCU:\Printers\DevModePerUser" -Name "PrinterName"
$($settings -join ',')

```

Now here's the script we deployed. Just paste the output above into the assignment.

```powershell

If (-Not (Test-Path 'HKCU:\Printers\DevModePerUser'))
{
    New-Item 'HKCU:\Printers\DevModePerUser' -Force | Out-Null
}

$sHex = @(<insert string>)
$sBin = [byte[]]($sHex)

New-ItemProperty -Path "HKCU:\Printers\DevModePerUser" -Name "PrinterName" -Value $sBin -PropertyType Binary -Force

```
