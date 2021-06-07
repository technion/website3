---
title: Property based tests, contracts with Ruby
description: Property based tests, contracts with Ruby
date: 2015-07-19
tags: [tests, ruby]
---

### Base App

For this demonstration, we are going to be using the venerable Fizzbuzz application. For those who haven't seen it, it's a common programming koan - see here [the Wikipedia page](https://en.wikipedia.org/wiki/Fizz_buzz).

Despite being a very single function, it can be surprising the issues you pick up.

With thanks to @Kerrick on Github, I've taken the first example code found on Google. Here's our sample file *fb.rb*:

{% highlight ruby %}
#!/usr/bin/env ruby

def fizz_buzz(max)
  arr = []
  (1..max).each do |n|
    if ((n % 3 == 0) && (n % 5 == 0))
      arr << "FizzBuzz"
    elsif (n % 3 == 0)
      arr << "Fizz"
    elsif (n % 5 == 0)
      arr << "Buzz"
    else
      arr << n
    end
  end
  return arr
end
{% endhighlight %}

For a quick demonstration, let's see how it looks:


{% highlight ruby %}
2.2.2 :001 > require_relative 'fb'
 => true
2.2.2 :004 > fizz_buzz(5)
 => [1, 2, "Fizz", 4, "Buzz"]

{% endhighlight %}

## Contracts
So far so good. The first thing I'm going to do is setup contracts. Let's create this *Gemfile*:

    source 'http://rubygems.org'
    gem 'contracts'

And install the gem (locally for this app, keeping the global space clean):

    bundle install --path=vendor/bundle

Using contracts involves placing this at the start of your script:

    require 'contracts'
    include Contracts

And then we need to think about our function. In this case, the input parameter is a positive integer, and it returns an array of strings. So I placed this directly before the function definition:

    Contract Pos => ArrayOf[String]

Now let's try and run it. It sounds simple and should "just work", but let's see:

    2.2.0 :003 > fizz_buzz 5
    ReturnContractError: Contract violation for return value:
        Expected: (a collection Array of String),
        Actual: [1, 2, "Fizz", 4, "Buzz"]
        Value guarded in: Object::fizz_buzz
        With Contract: Pos => CollectionOf
        At: /home/technion/fizzbuzz_tests/fb.rb:7

Turns out, the current code doesn't return an array of strings, it mixes integers with strings. I can hear it already. "But my code works fine". Really? Let's go back to the pre-contract code and try something:

    2.2.0 :007 > puts "The third Fizzbuzz output is " + fb[2]
    The third Fizzbuzz output is Fizz

Sounds legit..

    2.2.0 :008 > puts "The fourth Fizzbuzz output is " + fb[3]
    TypeError: no implicit conversion of Fixnum into String

Purists will point out that string interpolation would have resolved this, but that's not the point. The point is seeing unexpected behaviour because the return type differents from what was expected. With that in mind, let's put our contract in place, and alter the final branch of our statement on line 17 accordingly:

    arr << n.to_s

Running it in irb:

    2.2.0 :002 > fizz_buzz 5
    => ["1", "2", "Fizz", "4", "Buzz"]

Much better.

##Some basic tests

Before we do any new, exciting tests, let's get some basic ones in place. This is a boilerplate *Rakefile* for minitest:

{% highlight ruby %}
require 'rake'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.test_files = Dir.glob('spec/*.rb')
end
task(default: :test)
{% endhighlight %}

The two test applications were added to our Gemfile. We'll be using minitest, and we'll come back to explaining rubycheck.

    gem 'rubycheck'
    gem 'minitest'

Re-run bundler as above to install these gems.
We also created *spec/fbtests.rb*. Rather than walk you through each individual test, we've annotated them in comments.


{% highlight ruby %}

#!/usr/bin/env ruby

require 'minitest/autorun'
require 'rubycheck'
require_relative '../fb'

#Boilerplate
class FBTest < MiniTest::Test
  #The most basic test is a matter of identifying a simple input and 
  #confirming that a simple output matches exactly.
  #A small number like 5 can be fully typed out
  def test_5
    fb = fizz_buzz 5
    assert_equal ["1", "2", "Fizz", "4", "Buzz"], fb
  end
  #A larger fizzbuzz test needs to be considered more methodically. Noone
  #Will sit there typing out the expected results for fizz_buzz 100.
  def test_100
    fb = fizz_buzz 100
    #One thing we can say about fizzbuzz 100 is the length. Check it
    assert_equal 100, fb.length
    #This test verifies every element in the array matches one of the valid
    #results. This is a great way of checking every single value in some way.
    assert fb.all? { |e| /(\d+)|(FizzBuzz)|(Fizz)|(Buzz)/.match(e) }
  end
  def test_negative
    #We said earlier our contract shouldn't allow this. Check for an exception.
    assert_raises {fizzbuzz -1 }
  end

{% endhighlight %}

And that's a simple guide to writing tests. We recommend running them:

    bundle exec rake test

But that's where a lot of guides would stop.

## Property based testing

One of the great things about the fizzbuzz 100 test we wrote is that it's fairly generic. It should work for fizzbuzz 10, or fizzbuzz 1000 in the same way. So why not write a test that tests this property?

As a first example, we'll write simple a test that checks against one random number. Add in this test:

{% highlight ruby %}
  def test_random
    r = RubyCheck.gen_uint
    fb = fizz_buzz r
    assert fb.all? { |e| /(\d+)|(FizzBuzz)|(Fizz)|(Buzz)/.match(e) }
  end
{% endhighlight %}

All we've done here is made '100' into a random variable 'r'. The output however is interesting:

{% highlight bash %}
]$ bundle exec rake test
Run options: --seed 11306

# Running:

...rake aborted!
SignalException: SIGKILL
{% endhighlight %}

It'll take you a while to track down that segfault, and when you do, you'll see a huge dump sitting in the server logs, ending in this:

    kernel: Out of memory: Kill process 2994 (ruby) score 896 or sacrifice child
    kernel: Killed process 2994 (ruby) total-vm:2610792kB, anon-rss:1895804kB, file-rss:2024kB

What you are looking at is the fact that a huge, random number is able to crash our fizz_buzz application. We're just lucky the OOM killer killed the right app. Win one, for property based testing.

To pick a, somewhat arbitrary, upper bound, I've placed this in the first line of our updated fizzbuzz function:

    fail if max > 65536

And then we baked in a test for it:

{% highlight ruby %}

  def test_too_high
    assert_raises { fizz_buzz 65538 }
  end
{% endhighlight %}

If you comment out the random_test for a moment, you should be able to run a successful:

    bundle exec rake test

So what to do about getting the random test running again? Well this sort of thing should work:

    r = RubyCheck.gen_uint % 65537

However, I really feel property based testing should have a "property" for a 16 bit integer, so I've submitted a PR to rubycheck. If it gets through, this will be equivalent:

     r = RubyCheck.gen_uint16

Whichever you use, you should not find yourself able to check a random number with your fizzbuzz application.

You can probably see where I'm going with this - if you can test one random number, why not test many? rubycheck does have a "for_all" function, however, for various reasons, I prefer to implement this myself. Let's run a series of numbers through the checker.

Obviously, the more the better, but any more than a few hundred makes this a very boring test to sit through. So, I will be implementing some general tests, then more tests for the upper and lower bounds.

{% highlight ruby %}
  def test_random
    200.times do
      r = RubyCheck.gen_uint16
      fb = fizz_buzz r
      assert_equal r, fb.length
      assert fb.all? { |e| /(\d+)|(FizzBuzz)|(Fizz)|(Buzz)/.match(e) }
    end
  end
  def test_low_random
    100.times do
      r = RubyCheck.gen_uint16%256
      fb = fizz_buzz r
      assert_equal r, fb.length
      assert fb.all? { |e| /(\d+)|(FizzBuzz)|(Fizz)|(Buzz)/.match(e) }
    end
  end
  def test_high_random
    100.times do
      r = RubyCheck.gen_uint16%256 + 65280 #2e16 - 256
      fb = fizz_buzz r
      assert_equal r, fb.length
      assert fb.all? { |e| /(\d+)|(FizzBuzz)|(Fizz)|(Buzz)/.match(e) }
    end
  end
{% endhighlight %}

{% highlight bash %}
$ bundle exec rake test
Run options: --seed 30688

# Running:

......E

Finished in 76.904164s, 0.0910 runs/s, 7.7109 assertions/s.

  1) Error:
FBTest#test_low_random:
ParamContractError: Contract violation for argument 1 of 1:
        Expected: Pos,
        Actual: 0
        Value guarded in: Object::fizz_buzz
        With Contract: Pos => CollectionOf
        At: /home/technion/fizzbuzz_tests/fb.rb:7

{% endhighlight %}

Yes, we've found another issue. Our contract states "positive integer" - that means it does not accept a 0. Now you've entered a philosophical discussion: is there a fizzbuzz(0) ? If you believe not, then the contract served its purpose, and we should update the tests accordingly.

In the interests of shirking this convention, I have declared that on this project, fizzbuzz (0) is in fact an empty array. To this end, here is my final fizzbuzz code:

{% highlight ruby %}
Contract Or[Pos, 0] => ArrayOf[String]
def fizz_buzz(max)
  fail if max > 65536
  arr = []
  return arr if max == 0
  (1..max).each do |n|
    if ((n % 3 == 0) && (n % 5 == 0))
      arr << "FizzBuzz"
    elsif (n % 3 == 0)
      arr << "Fizz"
    elsif (n % 5 == 0)
      arr << "Buzz"
    else
      arr << n.to_s
    end
  end
  return arr
end
{% endhighlight %}

Of course, that deserves one more test:

{% highlight ruby %}
  def test_0
    assert_equal [], fizz_buzz(0)
  end
{% endhighlight %}

Regardless of the position you take on this, the point is that randomised testing forced a developer to at least consider an edge case, and plan accordingly. That in turn, is what we call "less bugs".
