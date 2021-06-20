---
title: React XSS Protection Cheat Sheet
description: Secure use of React and XSS
date: 2021-06-20
social_image: '/media/images/somuchwin.png'
tags: [react. xss]
---

## SEO is a funny thing

Although I never set out to write a 'React XSS Cheat sheet', this blog for some reason is the third Google hit for this term. In fact when I started digging into website analytics I found there are some really interesting backlinks going on. [This Avast forum](https://forum.avast.com/index.php?topic=176686.0) for example links my nginx page in regards to some defaced website.

So here's something that's close: A React XSS Cheat sheet that is more of a *complete React input security* discussion. Not really a Cheat Sheet, but React simply doesn't have the huge range of ways it can be exploited to produce a big spreadsheet of potential vulnerabilities. I feel however there's a few interesting places we can talk about user input.
## The general use case

Throughout this guide, you should consider the "name" variable to be any untrusted user input. Now as per my previous work in this space, the below is perfectly safe. Aside from any unknown zero day, there is no way to make this exploitable.

```javascript
const Hello = () => {
  const name = `User Input "; alert('1');`;

  return (
    <div>Hello {name} </div> 
  );
}
```
There's a wide range of things you could try here, which I wrote about testing [on this page](https://lolware.net/blog/2015-08-19-reactjs-xss-testing/). Handling unsafe input here is a core tenet of React - you shouldn't have to think about it.
## Style props
This allows a user to change a font size, presumably from a default.
```javascript
const Hitext = () => {
  const name = "24"
  const fontstyle = { fontSize: `${name}px`}
  return (
    <font style={fontstyle}> Hello</font>
  )
}
```
Now this depends what you call a vulnerability. In terms of executing code, there's no way to do this. However, a user setting a font size of 960 is going to leave you with a bad time. Not all security ends up being fun. Let's make sensible validator:
```javascript
const safeSize = (x) => {
  const fontinteger = parseInt(x);
  if(Number.isInteger(fontinteger) && fontinteger > 4 && fontinteger < 25) {
    return fontinteger;
  }
  return 18; //Default
}
const Hitext = () => {
  const name = "22";
  const fontstyle = { fontSize: `${safeSize(name)}px`}
  return (
    <font style={fontstyle}> Hello</font>
  )
}
```
## Image sources

The following needs more discussion - here we take a user input as an image source.

```javascript
const Hello = () => {
  const name = `https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png`;

  return (
    <div>Hello world.
      <img src={name} />
    </div> 
  );
}
```
Now there's an obvious risk here, and it looks like this:
```javascript
const Hello = () => {
  const name = `https://www.google.com/broken.png" onerror="alert('1')"`;

  return (
    <div>Hello world.
      <img src={name} />
    </div> 
  );
}
```
Contrary to what looks obvious to an attacker, React handles this fine. It does however present in my view as pretty broken that your code ever tries to pass this clearly broken image URL to an image source. A bit like attempting to parse an email address, there are some interesting falsehoods around what a valid image URL may look like. It's entirely possible to have a " mark in such a URL, and it's entirely possible to contain the word "onerror". It's even possible to contain s a space, although you'd expect to see it URL encoded. There are an awful lot of Google hits for "check valid image URL" and I'm afraid that no, you can't check it ends with a certain extension either.

So what does a valid URL look like? I'm going to cheat and suggest you read the next section, then reuse the function.
I would like to add a note regarding another particularly trollish behavior - posting forum images five pages with and twelve pages deep. You won't know the height and width of a user input, but you can use something like this:
```javascript
const Hello = () => {
  const name = `https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png`;

  return (
    <div>Hello world.
      <img src={name} style={{ maxWidth:200, maxHeight:200 }} />
    </div>
  );
}
```
Adjust the maximums for your use case and you'll be protected against this form of issue.
## Links
The href attribute probably comes up the most in React XSS discussions. You can probably treat anything that looks like a link in a similar fashion, for example iframe sources.
```javascript
const Hello = () => {
  const name = "https://www.google.com/"
  
  return (
    <div>Hello world.
    <a href={name}>Click here</a>
    </div> 
  );
}
```
Now this is safe against the first and most obvious vulnerability:
```javascript
const name = `#" onmouseover="alert('1')`;
```
An interesting input however is this one:
```javascript
const name = "javascript:alert('1')"
```
This will produce the following piece of text in your browser console:
```
"Warning: A future version of React will block javascript: URLs as a security precaution. Use event handlers instead if you can.
```
The React team knew this was an issue, and went and [signalled intent to deprecate](https://reactjs.org/blog/2019/08/08/react-v16.9.0.html#deprecating-javascript-urls) but this hasn't been completed. Even if it had, I'd really urge people not to write code that relies on the latest version of React. *Even* if you used other features that only worked there, because at some point someone will copy your component.

Your browser actually has a built in URL parser that can be leveraged to utilise a "Parse, don't validate" workflow:
```javascript
const Hello = () => {
  const name = "https://www.google.com";
  let safeURL;
  try {
    safeURL = new URL(name);
    if (! ["http:", "https:"].includes(safeURL.protocol) ) {
      throw new Error("Invalid protocol")
    }
  } catch(e) {
    console.log(`Bad URL ${e}`);
    return null
  }

  return (
    <div>Hello world.
    <a href={safeURL.href}>Click here</a>
    </div> 
  );
}
```
There's several key items in this piece of code, which are highly valuable when thinking about security:
- We didn't try to regex it or whatever the string. We used the browser's built in parser
- We've checked the protocol against an allow list, not a block list. The latter is a sure way to miss something
- We used our parser's href value, as opposed to deciding it "passed" then using the original string

This will very clearly ensure we have a valid, secure HREF to put in place.
It's worth reviewing [the API for the URL function](https://developer.mozilla.org/en-US/docs/Web/API/URL/URL) here. A special case to consider is that a URL is usually relative. For example, `<a href=/mypage.html>` from here should land you on `https://lolware.net/mypage.html`.
That's usually desirable when I'm writing my own website, and you can get this behaviour by coding in a base URL. eg, `const safeURL = new URL(name, "https://lolware.net")`. However when you're taking user input, it's usually not desirable,it usually means the user made a mistake and the above feature will throw an error in a way that may be more in line with what you'd like to see.
There's a second special edge case here. What if a URL was `google.com` ? The browser's built in parser considers it invalid unless it contains a protocol. Which is "correct" for code you write yourself, but a user may just write "www.google.com". Here's a way to satisfy that:
```javascript
  safeURL = new URL(name.indexOf(':') == -1 ? `https://${name}` : name)
```
## Blocklists
A naive solution that several blogs propose looks a bit like this:
```
if(name.match("javascript:") {
  // Invalid
}
```
There are a range of ways this could fall over, resulting in some proposals for large and confusing regexs. I'll have to start by asking at what point your unreadable regex is simpler than the few lines of "doing it properly" I've proposed above, but at this point I'll ask if you meant to allow the file:// protocol it just didn't realise it should probably go on the block list. It turns out, the list of valid protocols you don't want to allow is huge: [https://en.wikipedia.org/wiki/List_of_URI_schemes](https://en.wikipedia.org/wiki/List_of_URI_schemes).

There's a [particularly horrible valid URI on this stack overflow question](https://stackoverflow.com/questions/33644499/what-does-it-mean-when-they-say-react-is-xss-protected). That right there is an XSS in a large amount of potential answers, but in this given code, it's blocked.

## Third party libraries
The Javascript community has a fetishim with using third party modules for everything, under the guise of "tried and tested". A colleague I spoke to suggested this whole problem would best be solved with the `url-parse` module. Sure enough, you can find here a blog featuring someone who used it and then found exploitable edge cases:
https://medium.com/javascript-security/avoiding-xss-in-react-is-still-hard-d2b5c7ad9412

There's no reason for it. The code is only shorter because it doesn't use a try/catch, and will crash with an exception on invalid input.

## Homoglyph attacks
This is a class of attack where a person substitutes a similar character into a common URL. Using this, you can create a link easily confused for another site.
Consider the following homoglyph attack: `const name = "https://www.lolwaʀe.net";`. Now it turns out modern browsers do a pretty good job of recognising this. When you mouseover this, the shortcut down the bottom will display itself as `https://www.xn--lolwae-t6c.net/`, the punycode equivalent.

However, another way you may choose to render this component is with `<a href={name}>Click to visit {name}</a>`.
Remember I said above we explicitly used the parsed URL? Here's one example of the value of that. Rendering this way using `name` will output `Click to visit https://www.lolwaʀe.net`, complete with the 'r' homoglyph. Thus allowing users to be tricked in where they visit. Any variation on filtering or validating this URL will have this same issue.
The alternative `<a href={safeURL.href}>Click to visit {safeURL.href}</a>` implementation however, will output the punycode formatted `Click to visit https://www.xn--lolwae-t6c.net/`.

## IP based URLs
There's a good case for blocking IP based URLs. They are rarely seen on legitimate websites, but are often seen in:
- Exploits against common consumer modems, APs and routers
- AWS instance metadata related attacks

Now there are some very complex regex's to ensure an IP address is "valid", but we don't really need that. We've already verified a URL is valid, and I don't believe a valid URL can match this basic test without being an IP address. The additional check in this version should avoid it.
```javascript
  try {
    safeURL = new URL(name);
    if (! ["http:", "https:"].includes(safeURL.protocol) ) {
      throw new Error("Invalid protocol");
    }
    const ipcheck = /^[0-9.:]+$/;
    if(safeURL.host.match(ipcheck)) {
      throw new Error("IP Address")
    }
  } catch(e) {
    console.log(`Bad URL ${e}`);
    return null
  }
```
## Safe != Safe
It's important in these security discussions to define the threat we are addressing. That being specifically that user input is protected against XSS and similar attacks. Do you want the URL to meet a different definition of "safe" ? Google's Safe Browsing API can be used free for non commercial use: [https://developers.google.com/safe-browsing/v4](https://developers.google.com/safe-browsing/v4).

You may also wish to consider whether the http: protocol should be allowed. If your site operates strictly under https:, browsers will reject mixed content.
