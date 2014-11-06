---
layout: page
title: Home
order: 1
---

Bosun is an open-source advanced monitoring system targeting site reliability engineers and professional system administrators. It has been developed by [Matt Jibson](https://twitter.com/mjibson) and [Kyle Brandt](https://twitter.com/kylembrandt) at [Stack Exchange](http://stackexchange.com/).

###Features

* An expression language for evaluating time series that allows for highly flexibile alerts so you can control alert noise
* Templates for notifications that allow you to make alerts as detailed and informative as you want
* An interface for testing alerts and templates. You can see if alerts would have triggered over a range of history before deploying the changes
* High resolution metrics that never need to be rolled up that are stored in [OpenTSDB](http://opentsdb.net/)
* Is bundled with a collector called [scollector](http://bosun.org/scollector/) that treats Linux and Windows both as first-class systems and call also pull SNMP devices such as Cisco; running this collector provides you with a rich library of metrics from day 1
* Can run on any operating system which supports [Go](http://golang.org/) (which includes Windows and Linux)
* Auto-detects new services and starts sending metrics immediately; properly designed alerts will also apply to these new services and allow for minimal maintenance on the side of the operator
* Easily ingests metrics from services with a simple JSON/REST API so you can easily get application layer and business metrics into the system
* Aggregation support so your monitoring need not be purely host-based (and you don't need to worry about aggregating metrics from multiple servers yourself)  


### Early Access Monitoring System  

*Get instant access and start .. monitoring; get involved with this monitoring system as it develops.*  
*Note: This Early Access monitoring system may or may not change significantly over the course of development. If you are not excited to play with this monitoring system in its current state, then you may want to wait until the ga...monitoring system progresses further in development.*

Bosun is already practically very useful to us, and we are relying on it more and more at Stack Exchange. However, we want Bosun to be a general monitoring solution, and therefore we are depending on the creativity and experience of our users to start to influence it's design at this point. This means we want to be able to go back and make changes that may break existing configuration. Also we are still updating Bosun regularly so there may be regressions from time to time. 
