---
layout: post
title: Testing ReactJS for XSS vulnerabilities
description: A test hardness to smoketest ReactJS for XSS vulnerabilities
fullview: true
---

## Introduction

React is a Javascript framework from Facebook. Although it can be utilised natively, I'm going to focus on its front-end use. If you're not familiar with React, [Facebook has a pretty good tutorial](https://facebook.github.io/react/docs/tutorial.html) available.

The simplest explanation of React, is to consider it a natural progression from AJAX queries that try to render output by hand.

## React - XSS handling

One of React's features is that it handles XSS escapes by default. On the surface this is a good thing - new developers are far less likely to introduce XSS vounerabilities in code that escapes everything by default. [They make very obvious the risks associated with bypassing this filter](https://facebook.github.io/react/tips/dangerously-set-inner-html.html).


There are a few obvious downsides here, namely, you have to trust React to properly escape everything it's given. If you utilise any form of web security application scanner, you'll quickly notice it continually flagging alerts that it believes are XSS vulnerabilities, as it sees json come down the wire with unescapated HTML. Burp Suite did exactly this on a recent application test, which is the purpose for this testing. Unfortunately I'm not very good at shrugging my shoulders and declaring Facebook probably secured my services.

## The React XSS Smoke test

Facebook's code is generally very good, and I had every expectation I was going to get the result I did. That said, sometimes it's good to be testing. This service can also serve as an ongoing test for regressions.

As a source, I am utilising [the OWASP XSS Filter Evasion cheat sheet](https://www.owasp.org/index.php/XSS_Filter_Evasion_Cheat_Sheet). This page is updated regularly and hence the developed process includes grabbing the latest.

### Extracting the latest XSS list

I've created a short Ruby script which will parse the OWASP page, and create a .json file. This file is used by the front end.

### Frontend

With assistance from Babel and Gulp, we have a short peice of React front end that will:

- Perform an ajax query on the generated json
- Render each element on screen

This single script will attempt to execute each element from the OWASP cheat sheet. The fact you can view it without any issues including popups or network activity, shows the current version of React is intact.

## Get it

You can view it all on my Github.
<a class="btn btn-default" href="https://github.com/technion/reactxss">https://github.com/technion/reactxss</a>

## Update

This code has been overhauled for React 16. We've also moved to Webpack and Typescript. It sounds like framework churn - but Typescript really is more maintainable even for code this small.

The current code base is also running live at [http://lolware-content.s3-website-ap-northeast-1.amazonaws.com/reactxss/](http://lolware-content.s3-website-ap-northeast-1.amazonaws.com/reactxss/). No, it doesn't look like much. That's still a TODO.

## Conclusion

With a third party smoke test in place, I have a higher level of confidence in trusting React to sanitise frontends. I'll be expanding capabilities over the coming weeks, to ensure it tests the latest release, and to automate the testing.
