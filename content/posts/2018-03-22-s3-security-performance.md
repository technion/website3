---
title: Security and Caching headers with S3 websites
description: Lambda @ Edge 
date: 2018-03-22
tags: [AWS, S3, static hosting]
---

# Using Lambda @ Edge to add headers to S3 websites

There are a lot of advantages to running a website on Amazon S3. Unfortunately, for a long time, users were limited in their ability to manage security and performance headers.

# Security Headers

There are several great blogs on adding headers like HSTS. Rather than steal their thunder, I'll refer you to a few:

[https://iangilham.com/2017/08/22/add-headers-with-lambda-edge.html](https://iangilham.com/2017/08/22/add-headers-with-lambda-edge.html)
[https://medium.com/@tom.cook/edge-lambda-cloudfront-custom-headers-3d134a2c18a2](https://medium.com/@tom.cook/edge-lambda-cloudfront-custom-headers-3d134a2c18a2)

# Performance headers

The remaining issue is performance related headers. It's common, and easy, for nginx or Apache users to have certain extensions automatically add caching related headers.

In particular, people have commented that getting high pagespeed scores is difficult. This is ironic, when static sites are usually the fastest options available.

I've put such a script together. You can see below, a Lambda @ Edge function that will:

- Add standard security headers
- Match specific extensions
- Add max-age header for pagespeed scores to returned value

Because all this ends up cached at Cloudfront, you only ever need the script to execute on fetching from the origin.

```javascript

'use strict';

exports.handler = (event, context, callback) => {
    console.log('Adding additional headers to CloudFront response.');
    const response = event.Records[0].cf.response;
    const request = event.Records[0].cf.request;
    const headers = response.headers;

    headers['strict-transport-security'] = [{
        key: 'Strict-Transport-Security',
        value: 'max-age=63072000; includeSubDomains',
    }];
    headers['x-content-type-options'] = [{
        key: 'X-Content-Type-Options',
        value: 'nosniff',
    }];
    headers['x-frame-options'] = [{
        key: 'X-Frame-Options',
        value: 'DENY',
    }];
    headers['x-xss-protection'] = [{
        key: 'X-XSS-Protection',
        value: '1; mode=block',
    }];
    headers['referrer-policy'] = [{
        key: 'Referrer-Policy',
        value: 'no-referrer',
    }];

    const longterm = /\.(png)|(css)|(js)/;

    if (request.uri.match(longterm) ) {
            headers['max-age'] = [{
                key: 'max-age',
                value: '3153600',
            }];
    } else {
            headers['max-age'] = [{
                key: 'max-age',
                value: '86400',
            }];
    }
    callback(null, response);
};
```

# So.. Javascript

You can't understate how terrible it is working with Javascript like this. You can't usefully use Typescript or similar alternatives when you have no firm typing on what event.Records actually holds. Amazon's "testing" functions, out of the box, send a response field or a request field, but never both. So testing is a disaster.

I'm hoping Amazon can really improve the field here. I'm not naive enough to suggest a safer language will come into play, but I'd really like to see:

- Typescript support, including full types for the event structure
- Some form of "capture and replay" function, so we can test Lambda using actual web traffic

In the meantime, hopefully my script helps out.
