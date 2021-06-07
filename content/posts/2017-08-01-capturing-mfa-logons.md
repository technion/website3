---
title: Intercepting and Capturing MFA Logons
description: That push notification isn't a silver bullet
date: 2017-08-01
tags: [intercept, MFA]
---

# Intercepting and Capturing MFA Logons

One of the interesting classes of vulnerabiltiies are those that are fairly well known to security professionals, and yes, generally equally well known to criminals. Yet bizarrely, usually considered non-issues, or impossible by decision makers and standards groups. We're going to talk about one of those.

## MFA with Office365

Office 365 runs its own app with push notifications to support MFA. Let's be clear, the fact this exists at all puts them a long way ahead of businesses running [domain registries](https://lolware.net/2017/05/10/netregistry.html).

But to the man who claimed he was "physically intimate" with Microsoft's MFA solution, we're going to show how an attacker can still phish themselves an account.

## Open sourcing a toolkit

In order to prove this is a real thing, I've released a toolkit. You can grab it [from Github](https://github.com/technion/3652fa).

Credit where it's due, the main HTML/CSS template came out of the fantastic [phishing frenzy project](https://github.com/pentestgeek/phishing-frenzy-templates), which should be used a lot more by the world.

The app itself is a small Sinatra server, with far more Javascript than should be wielded by a sane mind.

## Running the attack

Not included: A decent phishing scam. Here's one we made earlier. Do note, people in general care a lot less about fake speeding fines and requests to reset passwords, and a lot more about free iphones.

This email has been about 80% successful in at least getting a link clicked in testing.

<amp-img alt="Steve Jobs Email"
  src="/assets/images/phish_email.png"
  width="668"
  height="619"
  layout="responsive">
</amp-img>

With that out in the field, fire up the capturing service.

<amp-img alt="MFA capture server"
  src="/assets/images/capture_server.png"
  width="643"
  height="149"
  layout="responsive">
</amp-img>

Now here is the somewhat convoluted part. As an attacker, open up the legitimate website, and enter the victim's email address. Office 365 does a series of Javascript magic with this before it allows a password to be entered, and I don't hate myself enough to come up with the Javascript to automate dealing with it.

With that done, grab the .js file and - after setting the URL appropriately - paste it into the console. Your attacker's window will now poll the attacking server for a set of credentials. It should all end up looking a bit like this.

<amp-img alt="MFA Attacker Logon"
  src="/assets/images/attacker_login.png"
  width="1606"
  height="632"
  layout="responsive">
</amp-img>

Being a good victim, the recipient of the phishing email is meanwhile sitting on this password capture page.

<amp-img alt="MFA Victim Logon"
  src="/assets/images/victim_login1.png"
  width="929"
  height="588"
  layout="responsive">
</amp-img>

The user of course, will happily enter a password. And in more basic solutions, the password would be captured, and that's the end of the story. But this isn't a basic solution, because the user did the right thing and setup MFA.

Fortunately, our more advanced phishing page has a fake MFA page, which is in line with a user's expectations based on their normal logon.

<amp-img alt="MFA Victim Logon2"
  src="/assets/images/victim_login2.png"
  width="901"
  height="581"
  layout="responsive">
</amp-img>

The magic of our attacker's console Javascript kicks in here, as it obtains the user's password, posts the logon form - and has the attacker trigger and MFA logon for the account.

<amp-img alt="MFA Attacker Logon2"
  src="/assets/images/attacker_login2.png"
  width="1061"
  height="675"
  layout="responsive">
</amp-img>

Where the story ends of course is that the victim approves the MFA notification, and the attacker is suddenly looking at their inbox.

## Further work

Microsoft ever so conveniently released an opt-in "New Sign On" page that started appearing right as I was proofing this blog. It's been asserted that this totally negates this blog and project. We shall agree to disagree.

The templates aren't perfect. The legitimate MFA page has this series of dots that move while you're waiting. If your victim is likely to notice this (most users are not) spend $20 on Upwork or whatever and get the victim page improved.

## Defence

Calling out attacks like this is only meaningful if you can call out a workaround. Let's start by describing what's not a workaround: Customised logon pages.

Recall the Javascript magic I described above that occurs when a username is entered. If setup appropriately by an administrator, [this is where you will be shown company branding, as described here](https://support.office.com/en-us/article/Add-your-company-branding-to-Office-365-Sign-In-Page-a1229cdb-ce19-4da5-90c7-2b9b146aef0a). A common argument is that users will look for company branding.

There's a few places this falls down. First, if an attacker really wanted to, I'll refer you back to the fact you could easily just modify your victim page suitably. But the other issue is that Microsoft has broken this feature several times, as you'll see my scrolling to [the comments section here](https://docs.microsoft.com/en-au/azure/active-directory/active-directory-add-company-branding). When users get used to Microsoft breaking a feature, it's extraordinarily unlikely they'll get used to panicking when it doesn't occur.

Your real defence here is in the form of U2F based MFA. It does have an increased friction of push based - which is why I'm not here declaring the death of push based apps. I am however suggesting businesses protecting critical data should offer at least the same level of security I can get on [Facebook](https://www.yubico.com/why-yubico/for-individuals/facebook/), which has supported U2F as an early adopter.

## Other services

Although you can Google "Amazon U2F" and get a whole lot of options for buying keys online, AWS appears to [currently only offer TOTP or SMS based MFA](https://aws.amazon.com/iam/details/mfa/). It's ironic that you can sink money into hardware tokens for a feeling of "extra security", but noone can explain why this attack couldn't be adapted to a page that looks like this:

<amp-img alt="AWS MFA Logon"
  src="/assets/images/awslogon.png"
  width="1152"
  height="648"
  layout="responsive">
</amp-img>

These are the types of articles that sales people like to use as proof of some kind of advantage of FIPS compliance. I don't know if I should laugh or cry.
