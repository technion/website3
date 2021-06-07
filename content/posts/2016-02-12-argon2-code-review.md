---
title: Argon2 code audits - part one - Infer
description: Using Facebook Infer static analysis tool against argon2
date: 2016-02-12
tags: [argon2, code review]
---

## Introduction
This article is the first part in a series in which we use popular tools to audit the Argon2 library.

Let's start with a quick background on what Argon2 is with a quote from their README:

> This is the reference C implementation of Argon2, the password-hashing function that won the Password Hashing Competition (PHC).

> Argon2 is a password-hashing function that summarizes the state of the art in the design of memory-hard functions and can be used to hash passwords for credential storage, key derivation, or other applications.

<a class="btn btn-info" href="https://github.com/P-H-C/phc-winner-argon2">More information at the official Argon2 Github</a>

In today's article, we review with a static code analysis tool. Such tools are often seen in a negative light, and hopefully the findings of this article can increase the use of such tools.

## Infer

Infer is a static analysis tool for C and Java that was opened source by Facebook.
<a class="btn btn-info" href="http://fbinfer.com/">See the official Infer website here</a>

I had used Infer early in its release, but it was quite frustrating to keep running. Every time I upgraded clang, or glibc, or just about anything, it seemed to break. As an Arch Linux user, that was regularly.

There's a great solution to this problem in modern times - Docker. I checked and it seemed Facebook had the same idea, as now they [publish a Dockerfile](https://github.com/facebook/infer/blob/master/docker/Dockerfile). It actually didn't work when I first tried it, but [my issue was attended to pretty quickly](https://github.com/facebook/infer/issues/270).

With a working file presented, I aren't too interested in Android development, so I created a slimmed down Dockerfile without the Android SDK. You can see this here:

 gist technion/3ad06cf97ae6f864b2c9 

Building using this file basically consists of:

- Place Dockerfile in an empty directory
- Run: `docker build -t infer:0.1 .`

With the container built, you can bring up an Infer container and destroy it safely any time you need to test some code.

## Running it

A docker container with a copy of Infer isn't that useful without a copy of your codebase. Fortunately, I happen to have a cloned git repo in my home directory. We can start the container and mount this code inside the container as follows:

```bash
$ docker run -t -v /path/to/phc-winner-argon2/:/code --rm -i infer:0.1
```

This will bring up a Docker container, in a way that's quite different how you hear about Docker being used in devops scenarios. Specifically, it'll bring you into an interactive shell, and when you run "exit" it will destroy the container.

The first thing we'll want to do is cd to the `/code` directory, from which we can start running the infer analyzer (conveniently in our PATH) against the codebase.

```
$ infer -- clang -c  -Wall -g -Iinclude -Isrc  -pthread src/run.c
Starting analysis (Infer version v0.6.0)
Computing dependencies... 100%
Creating clusters... 100%
Analyzing 1 clusters.Analysis finished in 0.257342s
Analyzed 4 procedures in 1 file
No issues found
```

What you'll see there is, the run file analyzed, and no real output to talk about. We should work through each file in this fashion. It turns out `core.c` is the interesting one.

```
$ infer -- clang -c  -Wall -g -Iinclude -Isrc  -pthread src/core.c
Starting analysis (Infer version v0.6.0)
Computing dependencies... 100%
Creating clusters... 100%
Analyzing 1 clusters.Analysis finished in 0.777034s
Analyzed 17 procedures in 1 file
Found 4 issues
src/core.c:286: error: MEMORY_LEAK
   memory dynamically allocated to thr_data by call to calloc() at line 267, column 16 is not reachable after line 286, column 25
  284.                       rc = argon2_thread_join(thread[l - instance->threads]);
  285.                       if (rc) {
  286. >                         return ARGON2_THREAD_FAIL;
  287.                       }
  288.                   }

src/core.c:286: error: MEMORY_LEAK
   memory dynamically allocated to thread by call to calloc() at line 262, column 14 is not reachable after line 286, column 25
  284.                       rc = argon2_thread_join(thread[l - instance->threads]);
  285.                       if (rc) {
  286. >                         return ARGON2_THREAD_FAIL;
  287.                       }
  288.                   }

src/core.c:302: error: MEMORY_LEAK
   memory dynamically allocated to thr_data by call to calloc() at line 267, column 16 is not reachable after line 302, column 21
  300.                                             (void *)&thr_data[l]);
  301.                   if (rc) {
  302. >                     return ARGON2_THREAD_FAIL;
  303.                   }
  304.

src/core.c:302: error: MEMORY_LEAK
   memory dynamically allocated to thread by call to calloc() at line 262, column 14 is not reachable after line 302, column 21
  300.                                             (void *)&thr_data[l]);
  301.                   if (rc) {
  302. >                     return ARGON2_THREAD_FAIL;
  303.                   }
  304.
```

A quick review of this codebase, with the highly descriptive output above should let you quickly ascertain that, yes, these are genuine issues, and fairly easy to fix.

This became a PR:

<a class="btn btn-info" href="https://github.com/P-H-C/phc-winner-argon2/pull/104">Pull request fixing this issue</a>

## Conclusion     

Hopefully what this demonstrate is that, once the appropriate container is handy, running Infer is something that can be done in minutes. Of course, in a larger scale project, it wouldn't be hard to script the execution, as opposed to running manually for each file.

The practical output here is precisely zero false positives, and four genuine memory leaks. I encourage more developers to look into such solutions. Obviously, a huge amount of credit goes to Facebook for releasing this tool.

The interesting thing here is that I had previously run this codebase through Valgrind - but what that misses is that it will only detect leaks that actually get triggered during the execution.

In our next part, we implement an afl-fuzz harness!
