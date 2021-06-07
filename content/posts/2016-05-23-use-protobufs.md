---
layout: post
title:  Use protobufs - now
description: Benchmarking protobufs against JSON
fullview: true
---

## Introduction
If you've ever touched any form of web development, ever, you've probably used JSON to get data from a server to a client. Ajax queries nearly always pull data in this format.

Recently, Google [Google invented the Protobuf standard](https://developers.google.com/protocol-buffers/docs/overview), which promises a number of advantages. This seems to have been largly ignored by the community for a while, with most discussions degrading to a complaint one Python library's performance.

I took an interested primarily when noting that [Riak KV](http://basho.com/products/riak-kv/) recommends its protocol buffer interface for performance. I also note, I'm not a Python user.

## Typed data
Aside from a potential performance increase, Protocol Buffers are typed. As someone who literally couldn't handle Javascript until things are [rewritten in Typescript](https://github.com/technion/erlvulnscan/blob/master/frontend/assets/erlvulnscan.tsx), this feature is worth a lot.

## Smaller
If you're performing a 32 byte Ajax query, you probably don't care if JSON included overhead. If you're doing a much larger query, you might.

## Test bed
In order to obtain a fair test, I'm comparing against two JSON libraries: JSX, which is pure Erlang, and Jiffy, which is C.

The protobuf implementation we are using is from [Basho.](https://github.com/basho/erlang_protobuffs).

I'd very much like to go on the record and state, I feel in most cases, microbenchmarks should be taken with a grain of salt. Including this one. Anyone who tries to rewrite anything based just on this blog is in for a bad time. Do your own tests.

In order to use Protocol Bufers, we start by defining the types. This is the contents of my things.proto file.

I've used some Ruby as a quick demonstration of what our data structure may look like:

{% highlight ruby linenos %}
irb(main):002:0> something = {:counter => 1, :number => 50}
    => {:counter=>1, :number=>50}
irb(main):003:0> something.to_json
    => "{\"counter\":1,\"num\":50}"
{% endhighlight %}

Using this, I can create a protobuf definition. This is the below file. Straight away, you can see that I've defined not only that the variables are of the in32 type, but that there are exactly two of them, and they are required. There's an obvious advantage at this point of knowing exactly what you're receiving over the wire.

```javascript
message Counternumber {
    required int32 counter = 1;
    required int32 num = 2;
}
```

And now here's our test bed application. It was run up in a few minutes so it's not meant to be a shining example of Erlang. If you're not familiar with Erlang or just want a tl;dr, it builds a list (an "array", if you will) of 100 of these structures, and serialises it 100000 times with to create a benchmark.

```erlang
-module(data).
-compile(export_all).
-define(TIMES, 100000).

-type ourthing() :: {'counter',pos_integer()} | {'num',1..1000}.

-spec fullrun() -> 'ok'.
fullrun() ->
    X = makedata(),
    {Jiffy, _} = timer:tc(data, withjiffy, [X]),
    {JSX, _} = timer:tc(data, withjsx, [X]),
    {Props, _} = timer:tc(data, withprop, [X]),
    io:fwrite("Jiffy time: ~p, JSX time: ~p props time: ~p~n", [Jiffy, JSX, Props]),
    Proplen = byte_size(iolist_to_binary(withprop_node(X, []))),
    JSONlen = byte_size(jsx:encode(X)),
    io:fwrite("JSON is ~p long and Protobuf is ~p long~n", [JSONlen, Proplen]).

-spec makedata() -> [ourthing()].
makedata() ->
    Y = [ [{counter, X}, {num, rand:uniform(1000) }] || X <- lists:seq(1,100)],
    lists:flatten(Y).

-spec withprop_node([ourthing()], any()) -> [any()].
withprop_node([], Acc) ->
    Acc;

withprop_node(X, Acc) ->
    [{counter, A} , {num, B} | Tail] = X,
    Encode = thing_pb:encode_counternumber({counternumber, A, B}),
    withprop_node(Tail, [Acc | Encode]).

-spec withprop([ourthing()]) -> [any()].
withprop(X) ->
    withprop(X, ?TIMES).

-spec withprop([ourthing()], non_neg_integer()) -> [any()].
withprop(X, 0) ->
    iolist_to_binary(withprop_node(X, []));

withprop(X, T) ->
    iolist_to_binary(withprop_node(X, [])),
    withprop(X, T-1).

-spec withjsx([ourthing()]) -> any().
withjsx(X) ->
    withjsx(X, ?TIMES).


-spec withjsx([ourthing()], non_neg_integer()) -> any().
withjsx(X, 0) ->
    jsx:encode(X);

withjsx(X, T) ->
    jsx:encode(X),
    withjsx(X, T-1).

-spec withjiffy([ourthing()]) -> any().
withjiffy(X) ->
    withjiffy(X, ?TIMES).

-spec withjiffy([ourthing()], non_neg_integer()) -> any().
withjiffy(X, 0) ->
    jiffy:encode({X});

withjiffy(X, T) ->
    jiffy:encode({X}),
    withjiffy(X, T-1).

```

## Results

With that testbed run, here is the output I'm seeing:

```bash
Jiffy time: 6936403, JSX time: 25947210 props time: 5145719
JSON is 2283 long and Protobuf is 486 long
```

There's an obvious benefit that's immediately visible here: the Protobuf output is less than a quarter of the size of the JSON.

To help review the timeframes, I've reformatted them as below. Elapsed time is presented in microseconds.

| Implementation | Time |
| -------------- | ---- |
| Jiffy          | 6,936,403 |
| JSX            | 25,947,210 |
| Protobuf       | 5,145,719 |

In a world where performance counts, these differences are non-trivial. It's hard to argue about the benefits here.

## Downsides

There are of course downsides. Working with protobufs is obviously more work, and they'll have to be converted on the client side. I'll suggest a "development mode" that still uses JSON, so you can use the network monitor usefully when you need it.

In an upcoming blog, I'll be converting the erlvulnscan frontend to read protobuf AJAX queries.

