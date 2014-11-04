---
layout: page
title: Home
order: 1
---

Bosun is an open-source advanced monitoring system targeting site reliability engineers and professional system administrators. It has been developed by [Matt Jibson](https://twitter.com/mjibson) and [Kyle Brandt](https://twitter.com/kylembrandt) at [http://stackexchange.com/](Stack Exchange). It has the following features and characteristics:

* An expression language for evaluating time series that provides extreme flexibility in alerting
* High resolution metrics that never need to be rolled up
* Is bundled with a collector that treats Linux and Windows both as first-class systems and call also pull SNMP devices such as Cisco; running this collector provides you with a rich library of metrics from day 1
* Can run on any operating system which supports [Go](http://golang.org/)
* Auto-detects new services and starts sending metrics immediately; properly designed alerts will also apply to these new services and allow for minimal maintenance on the side of the operator
* Easily ingests metrics from services with a simple JSON/REST API so you can easily get application layer and business metrics into the system
* Templates for notifications that allow you to make alerts as detailed as you want
* Aggregation support so your monitoring need not be purely host-based (and you don't need to worry about aggregating metrics from multiple servers yourself)
* Grouping of "unknown" alerts to prevent alert flooding
