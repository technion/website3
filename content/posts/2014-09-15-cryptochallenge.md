---
title: Taking the Matasano Crypto Challenge
description: Blog on the process of taking the cryptopals / matasanto crypto chalenge
date: 2014-09-15
tags: [crypto, challenge]
---

### Salespeople

Yes, I'm putting this first. Even before introduction. If you're in sales, the moment you see something slightly technical you'll tune out, and I want you here.The Matasano Crypto challenge has some interesting elements for you to consider too. You probably won't want to even attempt it, but there's something you can learn from it anyway.
 Think about what you tell me when you want to sell security. You invariably use the letters "AES", you tell me it's invincible and you tell me that's all the technical details that matter. I've probably heard this from three different vendors in the last few weeks. Now let me draw your attention to challenges 12, 13, 14, 16, 17 and 20. Every one of these challenges a person to actually implement a different, practical method of cracking AES. And before someone chimes in telling me none of these attacks would work in the real world, a quick search on Github pointed me at three different vulnerabilities I could easily exploit.
 So if you want to talk to me about selling security, you better have something better than the letters AES. 

### Introduction

As per the title, I've worked my way through the [Matasano Crypto Challenge](http://cryptopals.com/). When this was announced last year, I was pretty excited by the description. Here's why. [Allow me to point you at a a well respected cryptanalysis paper](http://eprint.iacr.org/2009/317.pdf). Bored yet? Me too. I would say "you'd need a math degree to make sense of it", but I majored in maths and still can't follow. So when an opportunity comes to write a practical cryptographic attack, it's interesting. I'd like to extend an absolutely huge thanks to the Matasano crew for putting this together.
 Now that the rules have been lifted (I never managed to get my hands on it before it went public) I'd like to write up some "tips", for those interested in help without taking a major spoiler. Of course, if you just want code, complete solutions to the Matasano Crypto Challenge can be found [here](https://github.com/technion/matasano_challenge). 

### Some notes on Ruby

This exercise served a dual purpose - I used it to learn Ruby as much as study cryptography. When I hit challenge 1, I couldn't write hello world. These challenge is an absolutely amazing way to learn a language. When I started this, I just didn't accept anything other than C would manage. When you hit the later exercises, I shudder to think how long that would have taken me in C. Even things like actually working with (and cracking!) 768 bit RSA was trivial on my entry-level Linode. The language really is incredibly powerful. One thing about ruby- get used to writing this a lot: .force_encoding("ascii-8bit"). Plenty of functions worked great for one input, and died with encoding errors on another. 

### Set one

The temptation here is to say "this is easy, I'll skip it". You're only going to hurt yourself. Everything here is going to be cut and pasted into a later challenge anyway, so bite the bullet and do it. I learned Ruby throughout these exercises (it probably shows, my set 1 code is far more terrible than the latter), and I'd encourage you to use the opportunity similarly. 

Challenge 6: Look at the wording on point four. It suggests averaging the result across four blocks. I don't know if it was just me, but four blocks pointed firmly at an incorrect keysize. I struggled with this for a while until I average much more blocks, for a much larger keysize. 

### Set two

Challenge 9: I thought I completed this correctly, until later code which used this implementation broke. What's not described here is that the PKCS #7 standard defined what to do when input is exactly a blocksize in length. Instead of naively appending 0 null bytes (how would that even work), append an entire block fo BLOCKSIZE. 

### Set three

Challenge 23 was an utter pain in the ass. It's the one challenge I somewhat thre in the towel on and ported someone elses code for. If anyone can point me at a sensible description of the maths, I'd love to see it. 

### Set four

- Challenge 29: Keep your solution lying around. Seriously, sooooo much is vulnerable to this.
- Challenge 31: Even with the artificial delay cranked up to one and a half seconds, I couldn't reliably determine the key. The protip here is: Webrick is terrible. After changing to Unicorn, the same peice of code was effective down to about 300ms. That's still higher than the suggested 50ms, and I could see how to improve the code, but that's already the next exercise.
- Challenge 32: It's amazing how accurate you can get this using not just an average, but an average that trims outliers, of which there always seems to be a few. My code was able to determine the key even down to 2ms. 

### Set Five

Things get a lot slower here. That said, although it's a lot more work, don't let the warnings scare you. I wouldn't personally call this set any harder than set three, although I can see how people drop out due to the time investment.
 For an invmod function, check rosettacode.org. 

Challenge 33: This algorithm is interesting to implement in Ruby. Variable names in the algorithm are "a" and "A". Except trying to use that in Ruby gives you a big fat warning about assigning a constant. Sure, you can just use a different letter, but it's surprising how mentally draining it gets reading one letter and writing another every time. 

Challenge 38: This is a good demonstrating in understanding why certain algorithms do certain things. Having B depend on the password is done for a good reason. 

### Set Six

- Challenge 42: I thought I was being smart utilising SHA256 as the hash in this challenge, where every write up used SHA1. Turns out, not only is SHA256's digest longer, the ASN identifier is longer. The end result is that there is barely any room for trash at the end and as far as I can see, this won't work. That cost me a few days. The other interesting thing is, for every "string to integer" algorithm I could put together (and observed in other people's answers) that leading null byte dissapears. Todo: What's the proper solution here?
 Finally, the cube root. Turns out it's not trivial to do this using big integers. The suggestion here is, find an "nthroot" implementation in your language. In Ruby, it will try to use floats, which will give you "Infinity" answers. Forcing integers loses precision, but perfectly suits this use case.
- Challenge 43: See that string, the hash and the integer they get from it? There's a catch there. That string has TWO different \n characters. One on the line break you see, and one on the end. Yep, that had me questioning whether I borked SHA1 in every previous challenge for a few hours.
- Challenge 47: Boy they weren't kidding about this being a lot harder. If you want to peek at solutions, there are a total of two of them I found on Github. There's one python solution where the writer actually implemented challenge 48 and then commented that parts of his code just weren't needed until the next challenge. Also, it wouldn't execute on my machine and I didn't want to get bogged down in Python to investigate. In short, that didn't help. The second solution I found was done in Java, which, to me, is unreadable. In short, you really are on your own. Where this is exceedingly hard is that there's no way to check the intermediate steps. If your "step2a" is broken, the rest of your code just won't work.
 Again, pay attention to wording. "Probably not going to need to handle multiple ranges". With a working solution in place, half the time my solution cracks a plaintext correctly, and half the time it runs into multiple intervals and produces garbage. In short, where your range of 'r' is greater than one, at least raise an exception so you don't go on a bug hunt. Secondly, I don't understand step 4. The actual paper provides it as part of the solution, but you have a working, cracked plaintext without it. Of the other two solutions I've reviewed, one of them implements it, one doesn't, both claim to solve the problem equivalently, leading to much confusion. 

### Set Seven

- Challenge 49: I had absoutely no idea that anyone anywhere was using CBC-MAC. It can be shocking what you'll find on Github.
- Challenge 50: See that "extra credit". Let's just say the list of "things I would rather do than any challenge starting with 'Write Javascript'" is an exceedingly large list. That said, if anyone else implements it, I'd be interested in using it to test my solution. 

### Closing

Things I don't pretend to be good at: Front end web dev. This page is terrible. I know it. I'd rather continue to get better at the backend and let the creative guys do what they do.
 Seriously though, everyone should try these challenges. If you're an entry level dev and you think it's over your head - good. Maybe you won't try and argue with someone about encryption implementations. If you're a crypto genious, how about taking a break from the maths and writing some code. 
And yes, literally hours after writing this, set 7 got released. Obviously, I haven't done it yet.
