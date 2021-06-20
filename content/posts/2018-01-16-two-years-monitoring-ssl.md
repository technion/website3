---
title: Open Source marketing after two years
description: CT Advisor has been auditing transparency for two years
date: 2018-01-16
tags: [Open Source]
---

## A quick history of CT Advisor

I initially jumped on the [CT Advisor](https://ctadvisor.lolware.net/) idea as soon as I read Google's Certificate Transparency announcements. The CT Log is a great security acheivement, and the ability to get an email the moment someone issued a cert for your domain is a great security offering.

According to the [commit logs](https://github.com/technion/ct_advisor/commits/master), the application was first usable more than two years ago.

Last week a colleague came to me excited. "Have you heard the news, Facebook this incredible new service. It monitors for SSL certificates issued for your domain". This sounds like a good time to reflect on the last two years.

## The lack of awareness

The excited tone from a security professional *who knew me personally* discussing Facebook's incredible new service, whilst being apparently unaware my own site was first to market, is an interesting dilemma.

My first announcement came in the form of a [Hacker News thread](https://news.ycombinator.com/item?id=10796432) that was immediately followed by Linode's DDoS. Shortly after I moved to AWS, but the thread had already died.

I made precisely two posts on Reddit, the first of which was deleted as spam. More recently, another vendor offering the service manages to show up persistently on Reddit whilst apparently not being spamming. It's been a frustrating thing to see.

On a technical level, everything has performed substantively better than expected. The service has been absolutely rock solid. I've supported products with six figure licensing agreements that couldn't run a week without a reboot. CT Advisor gets a reboot when there's a kernel security update.

To be clear, I don't consider anything an abject failure. There are several thousand domains being monitored and that's a good thing.

Nothing is "shutting down" because the site pretty much runs itself - I'm not Troy Hunt loading new databases three times a day.

## What's on offer

Whilst I have no skills that one would associate with making the UI more reasonable, any existing user should be able to attest to one fact: They will have never received an email from me that didn't say a certificate had been issued for them.

I've been fiercely defensive of security and privacy of users, something which for obvious reasons does not apply to alternate CT Monitors.

# Service Challenges

Once I finally got to the bottom of [this issue](https://github.com/epgsql/epgsql/issues/80) it became incredible just how capable Erlang is for this type of work.

The Certificate Transparency logs, to this day, continue to surprise me with their content. Did you know are quite a few certificates issued by trusted CAs directly to IP addresses. I do, thanks to crash logs.

Certificates for email addresses have always been a thing, but the fact I made it a full few weeks before seeing one should cast aside some of the marketing about these things.

However, everything has been effectively bulletproof. Aside from two incidents.

## Outages

The above mentioned Linode DDoS was a pain. It was however, a good driver to force the move to AWS. Aside from just a VPS, I have a VPS with a scheduled snapshot backup, and databases being sent to S3. And yes, it's definitely a locked down bucket.

The second issue, last week, was more interesting.

```
$ ruby
-bash: ruby: command not found
```


I don't know what situation led to Ruby suddenly not existing, but the web interface didn't run for obvious reasons. The backend however, continued running and sending alerts.

## Wins

I've done upgrades from OTP 18 to 21, and from Rails 4.2 to 5 to 5.1, without anything breaking at any point. In the case of Ruby, you could pin this on the site being so basic. In the case of the backend, well credit goes to Ericsson.

# Looking to the future

There are two impending goals for myself, with no firm ETA:

- Implement Amazon KMS to encrypt stored email addresses, (the only PII actually stored at all)
- Consider replacing Google Analytics with Piwik

You can see here, the general point is to continue to look after your data, and your identity.

## Lend a hand

Send out a tweet, it would be great for [CT Advisor](https://ctadvisor.lolware.net) to one day have more concurrent users than [Get Cryptolocker](https://getcryptolocker.com).

