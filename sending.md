---
layout: page
title: Send Data
order: 5
---

Sending data to bosun is done by treating your bosun host exactly like an OpenTSDB host. That is, POST to `http://bosun:4242/api/put` with formats described at [http://opentsdb.net/docs/build/html/api_http/put.html](http://opentsdb.net/docs/build/html/api_http/put.html).

Note that the host and port may be changed in your bosun configuration. Defaults shown above.

For metrics and tags to appear in bosun's search boxes, the data must be correctly typed. That is, timestamp should be a number. [Full JSON description.](http://godoc.org/github.com/StackExchange/scollector/opentsdb#DataPoint)