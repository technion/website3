---
title: Time to Shutdown CT Advisor
description: Shutting down certificate monitoring
date: 2023-02-16
social_image: '/media/images/somuchwin.png'
tags: [CTAdvisor, Certificate Transparency]
---
## Time to Shutdown CT Advisor

In 2015, I built [CTAdvisor](https://ctadvisor.lolware.net/) for a couple of reasons.

The first is that the new Certificate Transparency standard had some incredible potential, but I wasn't aware of a method of being proactively alerted to any breaches it may uncover. As far as I'm aware, the only lookup tool at the time was Comodo's (now Sectigo) service [https://crt.sh/](https://crt.sh/). We were even seeing advisory bodies recommend proactive monitoring at a time when I'm not aware any such tool existed.

The second reason is that it offered a great development opportunity, with a Rails frontend and Erlang backend, that's been mostly kept online in the eight years since.

## The change change: Competition

The major thing that's changed is that there are now alternatives. And to be clear, I don't see that as bad. I'd really love a world where this sort of monitoring is the norm, and having one guy run a service on a T2.micro doesn't facilitate that.

The first service I became aware was out there was launched by [Facebook/Meta](https://developers.facebook.com/tools/ct/). It offered an advantage, in that it also could alert you on similar, potentially phishing related domains. Still, people told me businesses wouldn't trust Facebook in a business setting and I stayed online.

We've since seen the more enterprise product offering by [Censys](https://search.censys.io/), and Scott Helm's [Report-URI](https://docs.report-uri.com/setup/certificate-transparency/) now offers CT Monitoring. The vast majority of signed up domains are .gov or .gov.au domains, which are exactly the sort of groups that should seeking these enterprise solutions.

Where I really knew better options were available to everyone was this [announcement by Cloudflare](https://developers.cloudflare.com/ssl/edge-certificates/additional-options/certificate-transparency-monitoring). With that out there, it's time to move on.

## Your data is always your data

I've been proud to run a service that collected email addresses for eight years and use them exactly as designed, and only in that manner. I even had to debate whether a shutdown email was appropriate, as I've never sent an email that wasn't directly an issuance report. I'd very much appreciate it if anyone using a canary address on the service can speak out and validate this.

When we get to the shutdown process where we drop the database, it'll be gone for good. There are backups sitting in an S3 an bucket with a 120 day lifecycle rule that will need to wait out that period before all data is gone for good.

## Shutdown process

I'll be updating the landing page and Github repos to reflect this project's status in the coming days. CT Advisor has one trick left in it however - a production canary of the new Ruby jit. To that end, I'll be updating the code to run with Ruby 3.2.1 and the jit enabled. Whether this takes two days or two months depends on how much of a Just Works(tm) situation we have.

I'm aiming to shutdown the backend - and therefore any alerting - on March 31st. At that point I'll truncate all existing accounts from the database. The Rails frontend will continue serving an informational page for a period of TBA.

## A note on the challenges

People that have spoken to me about this tool have all held a similar assumption: That scaling server load would be my biggest challenge. In reality, the Erlang backend absolutely hammers and even on my very low spec AWS server, I'm usually seeing load averages around 0.3. Likewise, keeping Rails bumped has always been very low effort. To be honest I've spent more time fiddling with Javascript dependencies on this blog's build process over the years than bumping Rails versions.

### Mail Hygiene

Easily the biggest challenge is mail hygiene. The MVP solution when the application was built simply had email bounces go into a mailbox. When I get around to it, I go through that mailbox and run a script that disables your account if you appear to be getting alerts sent to a dead address. I've put up with this far longer than I should, because I'm constantly surprised by how often I need to do this.

The second issue is spam complaints. Despite the fact that a sign up requires you complete a Captcha then double opt-in, and the fact every single alert has an [unsubscribe link](https://github.com/technion/ct_advisor/blob/master/apps/ct_advisor/src/ct_mail_alert.erl#L24), I've seen enough spam complaints that I've been on the border of having Amazon SES terminate my service on several occasions.

### CPU Issues

A weird load issue that cropped up every few months is the kswapd service running to 100% CPU. It's basically everything [described here](https://askubuntu.com/questions/259739/kswapd0-is-taking-a-lot-of-cpu). Naturally I did everything there. The CT Advisor Server was originally Arch Linux, then I moved it to Amazon Linux when I wanted an approach requiring less maintenance. This bug has persisted through eight years of kernel updates, but since a reboot always makes it go away for a couple of months I've never gotten to the bottom of it.

### SEO Spam

SEO Spam is out of control.

![SEO Spam is out of control](/media/images/seojunk.jpg)

We need to evict these people from the Internet, to the point I'd encourage search engine vendors to be more vocal about rejecting some of the claims they make.