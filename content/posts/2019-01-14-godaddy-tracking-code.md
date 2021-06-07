---
title: Reverse engineering GoDaddy's tracking script
description: Reverse engineering GoDaddy's tracking script
date: 2019-01-14
tags: [godaddy, tracking]
---

# Background
An article by Igor Kromin has provided an insight into a practice by GoDaddy involving injecting Javascript into customer sites. Several people expressed interest in a breakdown of the script - so here it is. [Please review Igor's original blog for further background](https://www.igorkromin.net/index.php/2019/01/13/godaddy-is-sneakily-injecting-javascript-into-your-website-and-how-to-stop-it/)

Despite this having blown up just this week, GoDaddy have clearly been doing this for a while. Here's an apparent copy of the code dated September 4, 2017:
[Your Javascript](http://yourjavascript.com/uploaded/file.php?i=1504529813&f=tcc-l.js.html). It predates any other mention of the code, such that I have to wonder if it involves the original developer.

You can also enjoy seeing an ARG that were thrown off by it in September 2018:
[Game Theorists Thread](https://www.reddit.com/r/GameTheorists/comments/9gcv53/game_theory_what_is_matpat_hiding_the_game/). Alternatively you may enjoy seeing a malicious site [that shipped with this code in a sandbox](https://www.hybrid-analysis.com/sample/e6a3d76e46c3aadb5cfe79cb64af39df833f323efde93cb83645d00347d23b32?environmentId=100)

# Baseline

I've built an empty website and copied the tracking code onto it. You can find the source in [this repo](https://github.com/technion/trackingsadness). There's a commit for every major step if you'd like to play along.

The good news is, uBlock blocks this tracking by default. By disabling uBlock, you can get a view of exactly what this script is doing. You can see the callout in the network monitor below, along with the long list of information it provides.

<amp-img alt="Network monitor on GoDaddy tracking"
    src="/assets/images/trackingsadness1.jpg"
    height="622"
    width="1905"
    layout="responsive"
    >
</amp-img>

It's obvious a lot of this is performance related, but at this point, I can't account for every parameter.

<amp-img alt="Tracking Parameters"
    src="/assets/images/trackingsadness2.jpg"
    height="624"
    width="821"
    layout="responsive"
    >
</amp-img>

# Cleanup

## Source map - 404
The script is interestingly worked. It's minified, in that all the variables are garbage. However, several comments remain. There's a source map referenced:

    //# sourceMappingURL=tcc_l.combined.1.0.6.min.js.map

But it doesn't appear to exist online. We can't be surprised about this for code that's published online, but it never hurts to look.

## Prettier
So our first job has been to run it through prettier, to make it nice and readable. This makes no actual code changes, and can be seen on the initial commit.

This acheives quite a bit on its own.

## IFFEs

Javascript gets a lot of crap, but it doesn't get nearly enough crap specifically about the IFFE. Refactoring to remove the outer IIFE makes the code a lot more readable. It also moves all the functions to the global space. You generally don't want that, but for us, it means we can access everything directly from the browser. Below you can see that the entire codebase is about exporting three different functions, noting we just wrote a() and b() ourselves.

<amp-img alt="Exported functions"
    src="/assets/images/trackingsadness3.jpg"
    height="574"
    width="833"
    layout="responsive"
    >
</amp-img>

# Disecting the remaining code

Let's skip to line 7 of the original codebase.

``` javascript
        function c() {
            var a = new Date,
                b = Math.round(a.getTime() / 1e3); //to seconds rounded
            b = parseInt(b.toString().slice(1)), //remove leading precision .. todo: substring
                b = b.toString(16), //to hex
                //should never exceed 8.. sanity check
                b.length > 8 && (b = b.substring(0, 8));
            b = "00000000" + b; //zero pad the value so 1234567 = 01234567
            var c = b.length - 8; //make sure we output time + random if we are less than 8 characters
            return b = b.substring(c)
        }
```
I hesitate to describe this as "functional" because of getTime(), but you can see this function doesn't use any external variables, and takes no input. So we can safely play with it.

Doing this:

```javascript
for (let i =0; i < 10; i++) { console.log(c()); }
```

Produces the same ten console logs every time. But if you keep running c(); from the console, you get a different eight values. Let's just call this whole thing an eight character pseudorandom.

Line 18 looks very similar, in fact there's a comment telling us what happens.

``` javascript
        //second guid fragment .. use MS time from EPOCH
        function d() {
            var a = new Date,
                b = a.getTime(); //get time in MS
            return b = b.toString(), b = b.substr(b.length - 4)
        }
```

d is similarly a pseudorandom function, but this one appears guaranteed to generate four numeric characters.

It turns out we have five different randomness functions just to feed:

``` javascript
        function b(a) {
            return c() + "-" + d() + "-" + e() + "-" + f() + "-" + g(a)
        }
```

tl;dr Everything down to line 61 does just what it says, provides a function that generates a GUID. You can play with this in the Chrome console:

``` javascript
c().generateGuid(1)
"20a18e2f-7446-4ac2-b86b-10a9f7480d78"
c().generateGuid(undefined)
"20a18e44-7772-4e42-b7cc-04d13d79fdc1"
```

I included the second example to show it doesn't seem to matter what parameter you feed it. It does impact the algorithm used to generate the last set of numbers, where that parameter is 'a':

``` javascript
    //fifth segment is either 0+Random(11) or 1+Hash(Shopper)+Random(3)
    function g(a) {
      if (a) {
        var b = i(a);
        b && b.length > 8 && (b = b.substr(0, 8));
        return ("1" + b + h(11)).substr(0, 12);
      }
      return "0" + h(11);
    }
```

With that massive tl;dr out of the way, I'm going to replace the whole of c() with a GUID function pulled off SO here:

[https://stackoverflow.com/questions/105034/create-guid-uuid-in-javascript](https://stackoverflow.com/questions/105034/create-guid-uuid-in-javascript)

We've reloaded and run our console test, so by [this commit](https://github.com/technion/trackingsadness/commit/a180601eb63b636331a5b2b9996b5f0dd6acb0eb) code is looking a lot easier.

# "Node testabiity check"
This exists in a few places:

``` javascript
  void 0 !== b &&
    //node testability hack
    (b.tcg = c);
```

I'll be blunt, I can't work out what this does, but I don't believe it's significant in the browser. If a node person wants to add input here, please do.

# Function 'd'

You can cheat with this function by looking at the return, where you're shown this is basically a class with a series of functions. By using the known names to rename each function, we can make it a lot more readable.

This was harder than it should have been, because single letter variables are used many times, and sometimes they are the variable you want. And sometimes they are shadowed in scope. And Javascript responds to all those things by just doing nothing and having no errors.

A nice solution here is.. run it through the Typescript compiler. No types, no effort into anything, except for where it easily tells you [this commit](https://github.com/technion/trackingsadness/commit/677828b0a0ba581cf7a249b6aca10d1b88c6b61a) is necessary to fix things.

If you think Typescript is just about making people write types.. moments like this make me think otherwise.

With that in place, most of function d() is self explanatory. The _eventObject() function does however look pretty interesting.

# Function 'e'

There's something odd going on in a big try/catch block. If you look at this code, you get a sudden understanding of the intent for every non-obvious parameter supplied to the tracker from the initial screenshot.

```javascript

              (e.tce = a.performance.timing.connectEnd || 0),
              (e.tcs = a.performance.timing.connectStart || 0),
              (e.tdc = a.performance.timing.domComplete || 0),
              (e.tdclee = a.performance.timing.domContentLoadedEventEnd || 0),
              (e.tdcles = a.performance.timing.domContentLoadedEventStart || 0),
              (e.tdi = a.performance.timing.domInteractive || 0),
              (e.tdl = a.performance.timing.domLoading || 0),
              (e.tdle = a.performance.timing.domainLookupEnd || 0),
              (e.tdls = a.performance.timing.domainLookupStart || 0),
              (e.tfs = a.performance.timing.fetchStart || 0),
              (e.tns = a.performance.timing.navigationStart || 0),
              (e.trqs = a.performance.timing.requestStart || 0),
              (e.tre = a.performance.timing.responseEnd || 0),
              (e.trps = a.performance.timing.responseStart || 0),
              (e.tles = a.performance.timing.loadEventStart || 0),
              (e.tlee = a.performance.timing.loadEventEnd || 0),
```

# Further cleanup

This is odd:

``` javascript
var e = {};
```

Happily blowing away our function when done. Let's remove and the associated 'if'. We've got one more IFFE to make sensible, and then i'll reprettify the whole thing.

As of [this commit](https://github.com/technion/trackingsadness/tree/4fd4f3bc7d3e02cc59be982de6942211c79582b4), we know we're basically dealing with our new "trackrun" function, which uses the already reviewed functions to generate performance and tracking information.

# Sent Data

Based on the above, we can break down the following which is sent to GoDaddy's servers after visiting an infected website. You may be interested in [the performance API](https://developer.mozilla.org/en-US/docs/Web/API/Window/performance) for some of these details.

```
cts: new Date().getTime()
tce: performance.timing.connectEnd
tcs: performance.timing.connectStar
tdc: performance.timing.domComplete
tdclee: performance.timing.domContentLoadedEventEnd
tdcles: performance.timing.domContentLoadedEventStart
tdi: performance.timing.domInteractive
tdl: performance.timing.domLoading
tdle: performance.timing.domainLookupEnd
tdls: performance.timing.domainLookupStart
tfs: performance.timing.fetchStart
tns: performance.timing.navigationStart
trqs: performance.timing.requestStart
tre: performance.timing.responseEnd
trps: performance.timing.responseStart
tles: performance.timing.loadEventStart
tlee: performance.timing.loadEventEnd
nt: performance.navigation.type
ht: The string "perf"
dh: window.location.hostname
ua: window.navigator.userAgent
vci: rand()
cv: internal version number
z: rand()
vg: a random GUID named "visit"
vtg: a random GUID named "visitor"
ap: The string "cpsh"
trfd: {"cts": new Date().getTime(),"tccl.baseHost":"secureserver.net","ap":"cpsh","server": unique customer ID}
dp: window.location.pathname
```

## Cookies Retained

The two cookies stored by this code are \_tccl\_visit and \_tccl\_visitor, both which appear to hold a GUID referencing your user.

# The final function

The minifier here made extensive use of unintelligible hoisting rules - variables were usually declared below where they were used, or assigned in different functions. Breaking something never produced any warnings or errors, the browser would just say "this is fine" and not execute the function. 

I've done some rearrangement to make this cleaner, and cleanup will continue on the repo. That said, it's in a state I feel you can confirm the script works as advertised: it tracks the user on the site, and it sends performance data as per the above information. 
