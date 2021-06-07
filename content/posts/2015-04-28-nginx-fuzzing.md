---
layout: post
title: Fuzzing nginx - Hunting vulnerabilities with afl-fuzz
description: Fuzzing nginx with afl-fuzz for vulnerabilities
fullview: true
---

### No 0day here

If you were looking for it, sorry. As of 48 hours of fuzzing, I've got 0 crashes.


### AFL - successful fuzzing

[American Fuzzy Lop](http://lcamtuf.coredump.cx/afl/) has a very impressive history of finding vulnerabilities. The trophy case is gigantic. An ELI5 of the design of the product is: Give it a program a valid input file, and it will mess with that input file until using it crashes the example program. [My first attempt at using it almost immediately found a crash situation in lci - Lolcode interpreter](https://github.com/justinmeza/lci/commit/8c66da06673d4017e718d3db15247361a7930e80).

Unfortunately, successful use against something which is not a command line application that runs and quits is more difficult.

### Compile and build

Our first step here will be to compile afl. I'm going to assume you can already do this. When building nginx, I used the following commands:

    export CC=/path/afl-clang
    ./configure --prefix=/path/nginxinstall --with-select_module

The use of the prefix is simple - we don't want to install this as root, as a proper service, or run it as such. The select module, I'll get back to. With nginx built and installed,  there are some very helpful config options:

    master_process off;
    daemon off;
    events {
        worker_connections  1024;
	use select;
	multi_accept off;

    }

By starting your config file like this, nginx will helpfully avoid forking to background, and start itself at a console where it belongs.

Your first server section should look like this:

    server {
	    listen       <ip>:8020;
	    ...
    }

We do this because:

	* We want the parser to decide it's happy to run as non-root
	* Without specifying the IP, something doesn't bind properly in our later process.

### Operate with stdin/stdout

Following the suggested build gets you halfway there, but the remaining problem is that nginx wants to take input from a network port, not from stdin. Fortunately, this project exists:

<a class="btn btn-default" href="https://github.com/zardus/preeny">Preeny on Github</a>

Preeny _almost_ solves our issues. I say almost because of two things:

* Preeny intercepts accept(), but, where it exists (my system), nginx uses accept4()
* nginx's default polling mechanism simply doesn't recognise connections that have been redirected and never triggers the event loop

For the first of these, I wrote this patch. Given accept() and accept4() are equivalent enough for our purposes, this patch just pushes accept4() to the intercepted accept().

*Update: @floyd_ch points out this patch is more correct than my original one*

{% highlight c %}

diff --git a/src/desock.c b/src/desock.c
index 36b3db7..4b267ef 100644
--- a/src/desock.c
+++ b/src/desock.c
@@ -209,6 +209,11 @@ int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen)
        else return original_accept(sockfd, addr, addrlen);
 }

+int accept4(int sockfd, struct sockaddr *addr, socklen_t *addrlen, int flags)
+{
+      return accept(sockfd, addr, addrlen);
+}
+
 int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen)
 {
        if (preeny_socket_threads_to_front[sockfd])
{% endhighlight %}

Again, compile as per the Preeny instructions, I won't walk you through this.

### Running it

With this in place, you can run nginx from the command line, and have it take HTTP syntax from stdin.


{% highlight bash %}

$ LD_PRELOAD="/home/technion/attack/preeny/Linux_x86_64/desock.so "  ./nginx
--- Emulating bind on port 8020
GET / HTTP/1.0

HTTP/1.1 200 OK
Server: nginx/1.8.0
Date: Tue, 28 Apr 2015 09:18:51 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Mon, 27 Apr 2015 08:45:32 GMT
Connection: close
ETag: "553df72c-264"
Accept-Ranges: bytes

<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
	            width: 35em;
			           margin: 0 auto;
					           font-family: Tahoma, Verdana, Arial, sans-serif;
						       }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>

{% endhighlight %}

This is successful.. almost. The problem you now see is that nginx never actually exits. To get around this, we had to patch nginx itself. Specifically, at line 262, I added this:

{% highlight c %}

    static int first_fd = 0;
    if (first_fd == 0)
            first_fd = max_fd;

    if(max_fd > first_fd) {
            printf("Exiting cleanly\n");
            exit(0);
    }
{% endhighlight %}

I'm sure there's a better place to patch, but this seemed to be the easiest for me to find. Specifically, when it knows it's been through the event loop once before and actually accepted a connection already, it'll log as such and exit.

Now, let's get a proper test case up and running. I created _testcases/in.txt_, based on a standard HTTP connection:

{% highlight bash %}

GET / HTTP/1.1
Acceptx: text/html, application/xhtml+xml, */*
Accept-Language:en-AU
User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko
Accept-Encoding: gzip, deflate
Host: lolware.net
DNT: 1
Connection: Keep-Alive
Cookie: A=regregergeg

{% endhighlight %}

Now let's execute it and see how that looks:

{% highlight bash %}

$ LD_PRELOAD="/patch/preeny/Linux_x86_64/desock.so "  ./nginx < testcases/in.txt
--- Emulating bind on port 8020
HTTP/1.1 200 OK
Server: nginx/1.8.0
Date: Tue, 28 Apr 2015 09:43:26 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Mon, 27 Apr 2015 08:45:32 GMT
Connection: keep-alive
ETag: "553df72c-264"
Accept-Ranges: bytes

<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
Exiting cleanly
$
{% endhighlight %}

That right there is perfect. It takes the input file from stdin, and passes it to nginx, outputs the HTML web content, then quits.

Now all that's neccessary is to run it under afl-fuzz:

	$ LD_PRELOAD="/home/technion/attack/preeny/Linux_x86_64/desock.so " /home/technion/afl-1.61b/afl-fuzz -i testcases -o findings ./nginx

Now hang on, this'll run for a while.
