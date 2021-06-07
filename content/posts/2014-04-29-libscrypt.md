---
title: libscrypt - password hashing library
description: libscrypt - password hashing library
date: 2014-04
tags: [libscrypt]
---

### Introduction

Several recent - highly publicised compromises - have involved mass leakage of passwords. This is a major annoyance - consider in the case of everyone with a LinkedIn account - who had their passwords pasted in cleartext on the Internet as a result of said hack. Every website these days is expected to hash passwords, but what constitutes a valid hash? 

### Hash options

MD5 is often referred to online as a valid fix to the issue. Let's put this aside for a moment and consider "MD5Crypt". This is a based on MD5, the purpose of which was to work around some of the inadequacies of MD5. The author of MD5Crypt has himself pubically stated that it should not be considered secure. Given this, do you really want to proclaim MD5 as a solution?
 Up until recently, bcrypt was *the* solution. As we've recently seen however, great CPU hard solutions regularly become broken due to increased CPU power availability. A solution was proposed in the form of a memory hard and CPU hardalgorithm. It's a great solution but it hasn't been overly accepted. I'm hoping to change that. 

### Libraries!

Although the creator has written an "example implementation", it doesn't satisfy the "simple library" requirement that prompts developers to implement it. Therefore, I've written my adaptation, which quite simply pulls the relevant parts from the original implementation, then adds a number of harnesses and simplified interfaces. 
 The hope is that through this, any developer can utilise scrypt. 

### API

To consolidate documentation, the technical documentation can be found on the project's github page, https://github.com/technion/libscrypt 


### Download STABLE1 now

I have removed direct download links from here to keep things easier to maintain. I have packaged and maintain Libscrypt as a Fedora RPM (yum install libscrypt libscrypt-dev). Micah from Debian has generously maintained a .deb distribution, and libscrypt has also been accepted into the FreebSD ports tree. If neither of these options are suitable, please see the source at Github. 

### Talk

I gave a talk on this library at Sydney Ruxmon. You can [get the slides here](/Secure%20Password%20Storage.pptx). 

### Contact

If you feel that code is poetry and you would like to assert that scanning for vulnerabilities prevents your codebase from rhyming, contact technion [at] lolware.net.

