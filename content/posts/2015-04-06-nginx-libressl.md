---
layout: post
title: nginx - Built against LibreSSL
description: nginx - Built against LibreSSL
fullview: true
---

### CentOS

For some time, I've been managing a CentOS RPM of LibreSSL built against nginx. You can still get that at the below link if you're interested, but as of April 2015, I've moved to Arch as my preferred OS.

<a class="btn btn-default" href="https://github.com/technion/libressl_nginx">Nginx LibreSSL RPM Source</a>


### Nginx built against LibreSSL

I don't currently recommend, unless you are running OpenBSD, using LibreSSL. There are too many untested applications. Testing nginx, is something I wanted to take on.

Regardless of whether you want to use by build or anything else, the fact remains: This page used to contain a set of instructions regarding how to patch up nginx and get it running with LibreSSL. At the present time, due both to smarter integration on the nginx side, and [compatibility patches I've submitted to LibreSSL](https://github.com/libressl-portable/portable/pull/40), things currently "just work".

Linking nginx against LibreSSL gives you a very reliable method of implementing Chacha20/Poly1305 cipher in nginx. I've been using this string:

        ssl_ciphers "ECDHE-RSA-CHACHA20-POLY1305 ECDHE-ECDSA-CHACHA20-POLY1305 EECDH+ECDSA+AESGCM EECDH+aRSA+AESGCM EECDH+ECDSA+SHA384 EECDH+ECDSA+SHA256 EECDH+aRSA+SHA384 EECDH+aRSA+SHA256 EECDH+aRSA+RC4 EECDH EDH+aRSA  !aNULL !eNULL !LOW ! 3DES !MD5 !EXP !PSK !SRP !DSS !RC4";

This gives A+ on the SSL labs test, and negotiates with Chacha20 when possible.

### The move to Arch

A reasonably high [component of my contribution to the open source community](https://github.com/nmathewson/libottery/pull/12) has related to [identifying compatibility issues with current versions of CentOS](https://github.com/bsdphk/Ntimed/commit/9caeb38a6f064c8a45f6b295fc16122d85e26b04). I didn't ask for that. I just wanted to try these applications, and found I couldn't. After spending a solid three hours with oclint, I'd had enough and made a platform move.

One of the great things about this is I can submit my build to the AUR without it being a big deal. 

<a class="btn btn-default" href="https://aur.archlinux.org/packages/nginx-libressl/">Get it here</a>
