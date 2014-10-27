---
layout: page
title: Send Data
order: 5
---

Sending data to bosun is done by treating your bosun host exactly like an OpenTSDB host. That is, POST to `http://bosun:80/api/put` with formats described at [http://opentsdb.net/docs/build/html/api_http/put.html](http://opentsdb.net/docs/build/html/api_http/put.html).

Note that the host and port may be changed in your bosun configuration. Defaults shown above.

For metrics and tags to appear in bosun's search boxes, the data must be correctly typed. That is, timestamp should be a number. [Full JSON description.](http://godoc.org/github.com/StackExchange/scollector/opentsdb#DataPoint)

## Metadata

Metadata (units, gauge/rate/counter, description, etc.) can be POST'd to the `/api/metadata/put` endpoint, with the request body as a JSON list of objects. The objects have the following properties:

* **Metric** (string): metric name
* **Tags** (object, optional): key=value tag pairs
* **Name** (string): metadata key name, for example: `desc`, `rate`, `unit`
* **Value** (string): metadata value

For example, to set the rate and unit of various metrics:

```
[
  {"Metric":"win.disk.spltio","Name":"unit","Value":"per second"},
  {"Metric":"linux.mem.drop_pagecache","Name":"rate","Value":"counter"}
]
```

### rate

To send metric rate information (used to specify if a metric is a gauge, rate, or counter), use `rate` as the Name and `gauge`, `rate`, or `counter` as the Value. Tags should be omitted.

### unit

To send metric unit information (used to specify a metric's units), use `unit` as the Name and the unit value as Value (for example, `bytes`, `per second`). Tags should be omitted.
