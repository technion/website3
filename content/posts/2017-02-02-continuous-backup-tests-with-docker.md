---
title: Continuous Backup Tests with Docker 
description: Using docker to automate a database restoration and continuously test backups
date: 2017-02-02
tags: [Continuous, Backup, Docker]
---

Side issue: These snippets would ideally be embedded gists for ease of management - but AMP prevents this. At some point I'll come up with a fix, which may well be to ditch AMP.

# Continuous Backup Tests with Docker
Recent news has left the topic of testing your backups a bit of a hot topic. Asking around, I'm hearing the same sort of answer from everyone. "Of course I test my restores. Occasionally. I'm sure I did it once. I usually do it from a development environment already setup for it".

That's basically where I was at with the [ctadvisor](https://ctadvisor.lolware.net) backups. I use [wal-e](https://github.com/wal-e/wal-e) to manage database backups, which is an awesome backup solution for Postgresql by the way, and I've definitely tested restores on development boxes.

Now sing along with me as we deploy an empty Docker container and try it now.

* Just how did I get Postgresql 9.6 on Ubuntu when 9.5 is the latest in the latest repository?
* [Seems covered here](http://askubuntu.com/questions/831292/how-to-install-postgresql-9-6-on-any-ubuntu-version#831293)
* add-apt-repository just errors out with not being a valid command
* It's ok, [apparently you need python-software-properties](https://ubuntuforums.org/showthread.php?t=1320536)
* Still not there. [Actually it's now in software-properties-common.](https://github.com/docker/docker/issues/5383)
* How do I install wal-e?
* pip install wal-e
* apt-get install pip
* No it's apt-get install python-pip
* pip install wal-e
* Error out. Apparently on Ubuntu, "pip" is python2 pip, and wal-e requires Python3
* apt-get install python3-pip
* pip3 install wal-e
* Complains about requiring boto
* pip3 install boto wal-e
* Can we run it yet?
* No, it now complaint about lzop
* apt-get install lzop
* Great it works. Now we just need this envdir command
* apt-get install envdir
* Google envdir
* apt-get install daemontools


Nothing here is undocumented, or even particularly hard to Google once you get through the first two or three links providing bad information. Everything here however, is stuff noone wants to deal with during an incident.

Now surely someone's going to say that in their enterprise they've got this nailed. And in a large enough company, you probably do have this process documented to death and tested regularly. Meanwhile, I'm not the only person with small side-projects and no time to deal with such a thing.

The beautiful thing about Docker is that once you've walked through a process once, you can paste it into a Dockerfile which both services as full documentation, and provides and automated build.

Here's what I've ended up with, one suitable for performing a restoration from wal-e. Furthermore, if we know this works, we know it's build process can be used to build a dedicated VM in future.

{% highlight bash %}
FROM ubuntu:xenial

RUN apt-get update && apt-get install -y python3 python3-setuptools \
        daemontools python3-pip lzop software-properties-common \
        apt-transport-https wget

RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-k
ey add -

RUN add-apt-repository "deb https://apt.postgresql.org/pub/repos/apt/ xenial-pgd
g main"

RUN apt-get update && apt-get install -y postgresql-9.6
RUN pip3 install boto wal-e

COPY recovery.conf /var/lib/postgresql/9.6/main/
RUN chown postgres /var/lib/postgresql/9.6/main/recovery.conf
COPY restoretest.sh /restoretest.sh

CMD "/restoretest.sh"

{% endhighlight %}

There are two additional files this imports. The first is recovery.conf, largely built from the wal-e documentation:

{% highlight bash %}
restore_command = 'envdir /etc/wal-e /usr/local/bin/wal-e wal-fetch "%f" "%p"'
{% endhighlight %}

More interesting however, is the restoretest.sh. Rather than booting a container capable of performing the restore, let's just do it.

This script will grab the latest backup, perform a restore, start the service, and perform an SQL query that ensures the relevant table exists and has data. Obviously, you'd need to customise this to suit your application.

{% highlight bash %}

#!/bin/sh

su postgres -c \
   "envdir /etc/wal-e wal-e backup-fetch /var/lib/postgresql/9.6/main/ LATEST"
service postgresql start
sleep 120
su postgres -c \
    "psql ct_advisor_int_live -c \"select count(1) from registrations;\" "


{% endhighlight %}

The "sleep" command is an unfortunate hack. When you start the postgresql service, it pulls in archive logs as per recovery.conf, and if a query runs before that finishes, there'll just be a "still starting" error. This workaround involves either sleeping pointlessly for too long, or risking not sleeping enough. I'd be interested in a better solution.

Moving on however, you can start and run this container at any time and see the output below. I use a volume to pass in the environment so there are no secrets in the container.

{% highlight bash %}
$ docker run -t -v /etc/wal-e:/etc/wal-e --rm -i wale
wal_e.main   INFO     MSG: starting WAL-E
        DETAIL: The subcommand is "backup-fetch".
        STRUCTURED: time=2017-02-01T22:33:45.595827-00 pid=7
wal_e.worker.s3.s3_worker INFO     MSG: beginning partition download
        DETAIL: The partition being downloaded is part_00000000.tar.lzo.
        HINT: The absolute S3 key is archives/basebackups_005/base_000000010000001D00000082_00000040/tar_partitions/part_00000000.tar.lzo.
        STRUCTURED: time=2017-02-01T22:33:46.164632-00 pid=7
 * Starting PostgreSQL 9.6 database server                               [ OK ]
 count
-------
  <redacted>6 
(1 row)

{% endhighlight %}

For the moment, I have a cronjob running this daily, and emailing the results. So a restore onto a reproducibly built server is tested every day. With this in place, there are still some considerations that will be improved over the coming weeks:

* Top priority, these backups should be encrypted. It would have been all too easy to accidentally paste the S3 credentials into this blog.
* Daily emails just get ignored after a while. A short script could check key outputs - the backup it restores is < 24 hours old, the query runs and returns a sane value, and we can go raise an alert only in an error condition
* Let's think about compromise. Somewhere on this production server, even if it's not accessible by the postgres user, if a set of S3 credentials used with wal-e's delete command. It's a problem I've seen missed in a lot of backup strategies - an attacker with root access to the server can wipe the database and the backups. For the moment, I'm just keeping secondary copies. Moving the delete capability elsewhere might be part two of this blog if there's interest.

As always, I encourage readers to focus on improving efficiency in their own systems, so that "doing it properly" doesn't become onerous and ignored.

##Update

Douglas Hunley contacted with a solution to the sleep hack - an all to obvious command I never knew existed. I've replaced the sleep with the following.

```
while ! pg_isready
do
    echo "waiting for database to start"
        sleep 5
done
echo "Database started"
sleep 2
```
