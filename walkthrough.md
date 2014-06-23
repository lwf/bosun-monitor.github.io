---
layout: page
title: Walkthrough
order: 2
---

The web interface of Bosun is designed around a workflow that goes from selecting a metric to defining an alert on that metric. Although you certain don't have to follow this workflow and can skip steps, it is a good starting point. For this walkthrough, we will create a simple alert that says:

> If the average bandwidth over the past 5 minutes for any monitored interface is a above 100 megabit/s then send an alert.

## Step 1: The Items Page

![]({{site.github.url}}/assets/walkthrough/items.png)

When we select the metric we want to work with, os.net.bytes, it will take us to our next stop, the graphing page.

## Step 2: The Graphing Page

The graphing page will initially look as follows:
![]({{site.github.url}}/assets/walkthrough/blank_graph.jpg)

At this point lets note some of the most important fields that will apply to our alert:

* Metric: This is the thing that is being recorded. In our example, os.net.bytes is data sent from scollector
* Aggregator: This the function used to do a pointwise aggregation of the raw time series. When a tag value is omitted, then the raw time series get aggregated to together using this function.
* Series Type: Counter/Gauge. If the data you are sending is a constantly increasing number, selecting counter makes it so a person rate is returned. This is the default.
* host, iface, and direction: They are all tag keys. They will change depending on the metric you have selected. The boxes next to them are optional tag values. Since we have left them blank above, everything gets summed together. So what we are viewing a a bytes graph that is the sum of: All hosts, all interfaces on that hosts, and both the in/out direction of each iface.

We will now change our graphing parameters to be closer to the alert we are after:

![]({{site.github.url}}/assets/walkthrough/changed_graph.jpg)

We changed the time field to be the "last five" minutes since that is what we specified is what we wanted for this alert. The most interesting change is that we add \* to both the host and iface fields. This means to return a different time a series (a line in the graph) for each unique host and interface pair. Since we left direction blank, that gets aggregated using the sum function (since aggregator is set to sum). If we had left iface blank, we would get the total bandwidth per host and not per host/iface. Below that graph we can see each unique time series that our graph has created, such as `os.net.bytes{iface=IntelRGigabitETQuadPortServerAdapter,host=ny-web01}`. We can also notice that our query function at the bottom has changed. By clicking expression next to the query, we are taken to the next step, our expression page.

## Step 3: The Expression Page

When we first click the link the page looks like this:
![]({{site.github.url}}/assets/walkthrough/blank_expr.jpg)

We can see each instance our query created is a row. The group is the tag *group*. Groups are an important concept in Bosun because they are how multiple expressions are joined, but it isn't very important to understand that now. The import thing to understand is that our query created multiple instances (as will our alerts) and that we call this multiplexing. The other important thing to note is the result. There are two types of results of Bosun, **series** and **scalars**. Series are an array of timestamp,value pairs, and a scalar is a single value. **Alerts trigger when a scalar != 0**. We can't create an alert until we have a scalar for each instance. So in the next image we will do 2 things:

1. Use the `avg()` reduction function to turn the series into a scalar
2. Multiply the result by 8 to turn bytes into bits, since that is what we said we want in our alert.

![]({{site.github.url}}/assets/walkthrough/changed_expr.jpg)

Lastly, we can use a comparison operator to to test if our alert result is greater > 100 mb/s (10e7 is 100,000,000):

![]({{site.github.url}}/assets/walkthrough/changed_expr2.jpg)

We can now move onto the rule page by clicking the rule button as highlighted in the above image.

##Step 4: The Rule Page

The rule page is where you do the bulk of the work. It allows you to start using all of the alert directives and the ability to test out notification templates. It preloads with a minimal alert and notification template:

![]({{site.github.url}}/assets/walkthrough/blank_rule.jpg)

For example, we can use variable interpolation, and set different thresholds and timespans for critical and warning:

![]({{site.github.url}}/assets/walkthrough/changed_rule.jpg)

You can also edit the notification template to look like whatever you want. At the bottom of the page are all the variables that can be included. You can even have queries evaluated that were not even used in the alert.