---
layout: page
title: Home
order: 1
---

Bosun is an open-source advanced monitoring system targeting site reliability engineers and professional system administrators. It has been developed by [Matt Jibson](https://twitter.com/mjibson) and [Kyle Brandt](https://twitter.com/kylembrandt) at StackExchange. It has the following features and characteristics:

* An expression language for evaluating time series that provides extreme flexibility in alerting
* High resolution metrics that never need to be rolled up
* Is bundled with a collector that treats Linux and Windows both as first-class systems and call also pull SNMP devices such as Cisco; running this collector provides you with a rich library of metrics from day 1
* Can run on any operating system which supports [Go](http://golang.org/)
* Auto-detects new services and starts sending metrics immediately; properly designed alerts will also apply to these new services and allow for minimal maintenance on the side of the operator
* Easily ingests metrics from services with a simple JSON/REST API so you can easily get application layer and business metrics into the system
* Templates for notifications that allow you to make alerts as detailed as you want
* Aggregation support so your monitoring need not be purely host-based (and you don't need to worry about aggregating metrics from multiple servers yourself)
* Grouping of "unknown" alerts to prevent alert flooding

## Problems with Alerting

Most alerting system really only let you do one thing: send an alert if a current value (or the few most recent values) are above or below a certain hard-coded, constant number. Because of this limited ability to express alert conditions, we don't get alerts or we get too many alerts. Bosun's expression language allows operators to create richer alerts, and tune false alerts with conditions to prevent alert noise.

As an example, here are some alerts that you could define in increasing complexity in plain english:

* CPU on any server is higher than 80%
* CPU on any server is higher than what it normally is during this hour of the week as compared to the last few weeks
* CPU on any server is higher than what it normally is during this hour of the week as compared to the last few weeks and the "FooIndexJob" is not running on that respective server
* Internet bandwidth is high for this time of the day, and neither SQL replication nor Redis replication across the WAN is occurring
* For a cluster of nodes, one node has a relatively high or low percent of the load compared to the other nodes in the cluster (this can be defined by one alerts that applies to all "clusters", and scales according the number of nodes in the cluster)

Due to aggregation, alerts can be cluster friendly. For example, you can have alerts operate on a metric-like web hits-per-second through our load balancers, and not have to specify the load-balancer host. Because of this, your alert will work regardless of which machines in the cluster happen to be active at the moment.

## What is Next

* Metadata for metrics