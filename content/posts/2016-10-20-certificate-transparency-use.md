---
title: The improving state of SSL deployment
description: Certificate Transparency monitoring service gives us great new insights into the increasing deployment of SSL certificates
date: 2016-10-20
tags: [Certificate Transparency]
---

## Increase in SSL use

There have been a number of blogs lately regarding the increasing SSL deployment across the Internet. Rather than review another survey, I noted this same pattern by its impact on my monitoring service.

## Certificate Transparency - Background

To attack a number of the weaknesses in the SSL/CA system, a service known as [Certificate Transparency](https://www.certificate-transparency.org/) was developed.


In order to provide immediate, actionable monitoring from the CT system, I launched [CT_advisor](https://ctadvisor.lolware.net) in November 2015. This service alerts you the moment a certificate is issued for your domain. Several commercial services have since disrupted this space with a paid version of the same thing. As a side effect of this, I've been watching the major transparency logs quite closely since.

There's been a lot of discussions around mass increases of SSL's pervasiveness across the web recently, such as from the great [Let's Encrypt team](https://letsencrypt.org/2016/06/22/https-progress-june-2016.html). Here in the transparency, we've seen further evidence of this.

## A capable monitor

CT_Advisor is designed with Erlang's "let it crash" mentality in mind. When it polls a monitoring server, it limits the amount of certificates it will grab in an cycle. That number has always sat at 32, meaning, when some form of failure occurs, no more than 32 certificates need to be reprocessed.

This was particularly important in the early days, as there were a lot of certs that didn't fit the template I originally built the service to handle, which showed up in logs.

The original polling interval was set to ten seconds, and then shortly afterwards, configured to one minute. What I'm saying is, parsing a maximum of 32 records every minute was perfectly capable in the early days.

At some point this was reduced to 30 seconds, and then 15, and until recently, this was sufficient to handle polling all logged certificates.

## Suddenly lagged

Last week I logged onto the service backend, and found it was more than two million certificates behind in its parsing. The reason here, is the explosion of certificates in the CT logs.

You can use [this URL](https://crt.sh/?ctid=1000000) to identify the one millionth certificate in a given monitor. For our discussions, we're referring to the Google Aviator log. We're starting at a million because it's a number some time after the initial ingest into the monitor. We can see the certificate logged on 2013-09-30.

Certificate 5,000,000 was logged on 2014-11-29, taking over a year to get another four million certificates logged.

The ten millionth certificate was logged on 2015-10-13. With just under a year producing five million certificates.

Fifteen million came along at 2016-04-25, roughly demonstrating a halving of the time taken to hit the next five million.

**Let's Encrypt** very clearly kicked into play at this point, with 2016-06-10 being the logging date of certificate number twenty million, less than two months from the earlier block. This is well reflected in [their own graphs](https://letsencrypt.org/images/le-certs-issued-june-22-2016.png) on issuance.

The pattern continues:

- 2016-08-05 to reach 25000000
- 2016-09-22 to reach 30000000
- 2016-10-19 to reach 38000000

## Not necessary "number of certificates"

There are a few things to consider in reviewing these numbers. Firstly, Let's Encrypt's short lifespan means a lot more certificates issued. Secondly, not every certificate is guaranteed to be logged, but more responsible CAs are ensuring that happens.

Cloudflare are also notable, as their SAN certificates need to be reissued every time another user signs up to a free plan.

Finally, believe it or not, S/MIME certificates are a thing that show up in certificate transparency logs from time to time.

## But that's still an increase

Even with average certificates coming down from two years for legacy vendors, to three months for LE, eight million certificates logged in less than a month is something unprecedented.

One of the major causes in the last two months track back to [cPanel launching the AutoSSL feature](https://blog.cpanel.com/announcing-cpanel-whms-official-lets-encrypt-with-autossl-plugin/), which automates Let's Encrypt certificates to all the cPanel users that never had access to it.

In short, there are an awful lot more websites using SSL, than there were a few years ago.

## Closing remarks

I'll leave you with classic community responses in regards to [CT Advisor](http://ctadvisor.lolware.net).

- *This guy claims "fraudulent SSL certificates" are a vulnerability but can't even quote a CVE. What an embarrassment to the security industry.*

- *Anyone who understands SSL will know it's not possible to get a fraudulent certificate. This service might as well claim to monitor time travellers because it'll never happen. The fact he thinks otherwise shows what an amateur he is.*

