---
layout: post
title:  cPanel Wordpress version/vulnerability scanner
description: cPanel Wordpress version/vulnerability scanner
fullview: true
---

### Introduction

I've found myself in front of a number of cPanel servers lately. The first thing I became aware of it that cPanel has a series of security checks and scans built in (good thing). You've probably noticed emails from a service called "hackcheck" on a regular basis. There is also a large number of after market security services such as [http://www.configserver.com/cp/csf.html](http://www.configserver.com/cp/csf.html). However, all these systems appeared to focus on either general security, of "after the fact" detections. This seemed to ignore the most obvious vulnerability - nearly everyone with a cPanel account installs Wordpress, then fails to update it. 

### Wordpress - a History of vulnerabilities

You can review a brief history of Wordpress at Secunia's page [http://secunia.com/advisories/product/33191/?task=advisories](http://secunia.com/advisories/product/33191/?task=advisories) - interestingly, not on the Wordpress website as far as I could see. As you can see, prettty much every version update ever released has been a security update. Some of them have been mind blowingly dumb, leading to a view that there is almost certainly more to come. I would generally argue that any "out of date" installation is equivalent to "vulnerable". 

### The scanner

This script is very simple, and parses out Wordpress's version from its flat files. It does assume default paths are used. If someone is going to obscure these paths, they are probably not the customer you are concerned about having an out of date installation. If you have a hosting environment other than cPanel, check the file path contained in the script. 


{% highlight bash %}
root@cpanelserver [~]# /updatescan.pl
The latest version of Wordpress is 3.3.2
Account gooduser is running 3.3.2 - UP TO DATE
Account baduser is running 3.0.3 - OUT OF DATE

Or, to automatically email results from a scheduled task:
root@cpanelserver [~]# yum install mailx
root@cpanelserver [~]# /updatescan.pl | mail -s "Wordpress scan" youremail@domain.com

{% endhighlight %}

### Download it now

[From this link](/assets/downloads/wpupdatescan.pl).

### Now for Joomla

[This version](/assets/downloads/joomlascan.pl) now supports scanning installed Joomla software in the same way. 

### Contact

If you feel that code is poetry and you would like to assert that scanning for vulnerabilities prevents your codebase from rhyming, contact technion [at] lolware.net.

