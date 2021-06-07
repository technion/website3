---
layout: post
title:  Intelligent Backend Routes with Rails and nginx
description: How to avoid passing silly URLs to your backend
fullview: true
---

## Introduction
A fairly common deployment involves running nginx as the first hop on an application server, which in turn routes to your backend. This blog is based on Rails as a backend, but the principle could probably be universally applied.

## Common nginx configurations
The standard method of deploying the above strategy is well documented in the [nginx Pitfalls and Common Mistakes](https://www.nginx.com/resources/wiki/start/topics/tutorials/config_pitfalls/) guide. Naturally, it's under a *GOOD* section, specifically, under the "proxy everything" strategy. The code they list is:

```
server {
    server_name _;
    root /var/www/site;
    location / {
        try_files $uri $uri/ @proxy;
    }
    location @proxy {
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_pass unix:/tmp/phpcgi.socket;
    }
}

```

What this will do is check for a static asset first (in the form of a file) and then proxy it to the backend.

## The immediate annoyance
What you will very quickly notice, or at least you should if you watch your logs, is the incredible annoyance of dumping an entire stack trace when a route isn't matched. Such as when an apple device goes looking for their touch icon automatically, and you don't have one setup.

```
ActionController::RoutingError (No route matches [GET] "/apple-touch-icon.png"):
  actionpack (4.2.5) lib/action_dispatch/middleware/debug_exceptions.rb:21:in `c
all'
  actionpack (4.2.5) lib/action_dispatch/middleware/show_exceptions.rb:30:in `ca
ll'
  railties (4.2.5) lib/rails/rack/logger.rb:38:in `call_app'
  railties (4.2.5) lib/rails/rack/logger.rb:20:in `block in call'
  activesupport (4.2.5) lib/active_support/tagged_logging.rb:68:in `block in tag
ged'
  activesupport (4.2.5) lib/active_support/tagged_logging.rb:26:in `tagged'
  activesupport (4.2.5) lib/active_support/tagged_logging.rb:68:in `tagged'
  railties (4.2.5) lib/rails/rack/logger.rb:20:in `call'
  actionpack (4.2.5) lib/action_dispatch/middleware/request_id.rb:21:in `call'
  rack (1.6.4) lib/rack/methodoverride.rb:22:in `call'
  rack (1.6.4) lib/rack/runtime.rb:18:in `call'
  activesupport (4.2.5) lib/active_support/cache/strategy/local_cache_middleware
.rb:28:in `call'
  rack (1.6.4) lib/rack/sendfile.rb:113:in `call'
  actionpack (4.2.5) lib/action_dispatch/middleware/ssl.rb:24:in `call'
  railties (4.2.5) lib/rails/engine.rb:518:in `call'
  railties (4.2.5) lib/rails/application.rb:165:in `call'
  puma (2.15.3) lib/puma/configuration.rb:79:in `call'
  puma (2.15.3) lib/puma/server.rb:541:in `handle_request'
  puma (2.15.3) lib/puma/server.rb:388:in `process_client'
  puma (2.15.3) lib/puma/server.rb:270:in `block in run'
  puma (2.15.3) lib/puma/thread_pool.rb:106:in `block in spawn_thread'

```

There's a direct solution to this default configuration, which is well documented at a number of easily Google'd documents.

[This document](http://rubyjunky.com/cleaning-up-rails-4-production-logging.html) appears to have the same initial feeling I had - that *FATAL* errors should be reserved for application crashes, not the billions of bots that hit my sites daily looking for phpmyadmin.

There is also a lot of misinformation about this situation, with a number of stackoverflow posts addressing single issues (you should go and create that file) rather than the source.

## A more comprehensive solution

The existing solutions just didn't quite satisfy me. To be clear, there's nothing immediately terrible about just creating a 404 page as described, but the idea that a backend designed to service certain endpoints ends up with all unknown traffic routed to it worked strongly against the way I like to run systems.

In some cases it's easy. For my [Erlvulnscan](https://erlvulnscan.lolware.net), there is a single endpoint, and I can manually code up my nginx.conf as such:

```
    location /netscan {
        proxy_pass http://localhost:8081;
    }
```

Research can dig up enterprise solutions involving embedded LUA and Redis. That's way overkill for my needs however.

## Problem 1: What does a good route look like?

For my [ctadvisor interface](https://github.com/technion/ct_advisor_int), I create this quick rake task. You can implement it yourself by adding the [task file](https://github.com/technion/ct_advisor_int/blob/master/lib/tasks/nginxmap.rake) in to the lib/tasks/ directory.

The general goal here is: print out a mapping of valid endpoints for later use. It looks like this:

```
$ bundle exec rake nginxmap
map $uri $rails_route_list {
    default "false";
    ~^/assets "true";
    ~^/registrations/verify/ "true";
    ~^/registrations/verify "true";
    ~^/registrations/unsubscribe "true";
    ~^/registrations/destroy/ "true";
    ~^/registrations "true";
    ~^/registrations/new "true";
    ~^/rails/info/properties "true";
    ~^/rails/info/routes "true";
    ~^/rails/info "true";
    ~^/rails/mailers "true";
    ~^/rails/mailers/ "true";
    ~^/$ "true";
}
```

The output is somewhat like running "rake routes", but there you see routes like this:

```
/registrations/destroy/:id/:nonce(.:format)
```

Although it's possible to build complex regex's in nginx to try to be very specific, that's not the goal here. It's "good enough" to reach the goal of ensuring it's a valid endpoint by stopping at the first symbol (:id) and ensuring the path matches everything before it.

The code also has a special handler for /, because this should only match in its entirety (otherwise, everything matches).

There's a big TODO here in that this path shows a few additional routes (such as /assets) which aren't present in "rake routes". I could just regex these out, but I'd like to better see the root cause.

## Problem 2: How to actually set these routes up in nginx

The obvious solution involves either a whole series of location { } blocks matching each, or one massive regex. Neither of these are particularly pretty, or scaleable.

It turns out nginx has a reasonably good alternative in the [map](http://nginx.org/en/docs/http/ngx_http_map_module.html) directive.

The task we created formats our routes appropriate for use in the map directive, allowing us to configure nginx like this:

```

    include 'railsmap.conf';

    server {
        ...
        try_files $uri @rails;
        location @rails {
            if ($rails_route_list = "false") {
                return 404;
            }
          proxy_pass http://localhost:8082;
        }
    }
```

Where the `railsmap.conf` can be created by running:

```
bundle exec rake nginxmap > railsmap.conf
```

I re-run this every time I add a route in Rails. In practice, on an established application, this isn't highly common.

## In practice

The described system has now been running on the [ctadvisor](https://ctadvisor.lolware.net) page for a couple of days and I'm quite happy with the results. Obviously, your environment may be different. Or you may just care less about how specific your routing is.

A non-trivial amount of traffic hitting Rails for me comes in the form of rediculous bots. It should be clearly stated that you're not providing a significant security benefit by "firewalling" off hundreds of scans for vulnerable Wordpress plugins against a Rails server, but you are blocking unwanted traffic, which is never a bad thing.

