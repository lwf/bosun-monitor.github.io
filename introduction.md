---
layout: page
title: Introduction
order: 4
---

# Core concepts
Bosun is meant to be a highly flexible and powerful alerting system. This power does come with the cost of some complexity. The authors have attempted to ease the complexity as much as possible, but in order to be productive there are some core concepts about how bosun works that users must understand. 

Those are:
 - Bosun's Data types
 - How OpenTSDB metrics and tags work
 - Bosun's Grouping and Multiplexing

Each of these things builds upon the other. So make sure you basically understand on section before moving onto the next. Once you understand these core concepts, you can move onto the *TODO: ALERT WRITING TUTORIAL*

## Bosun's Data Types
There are 2 data types in Bosun:

 * A Series
 * A Scalar

Series are basically arrays of timestamps and values (they are time series), and scalars are a single values. This is quite straightforward, but if you keep these types in mind as you work with Bosun it will make things far less confusing. Certain functions such as our OpenTSDB query function `q(...)` return series and other functions such `avg(q(...))` return a scalar (generally by reducing a series into a scalar).
  
## OpenTSDB Metrics, Tags and Querying
Alerts are generally going to based around OpenTSDB queries, so a good command of how OpenTSDB works is essential. When you query OpenTSDB and actually get something back, one of four things will be returned from a *single* query:

1. A single time series as it has been recorded in OpenTSDB
2. A single time series representing a *pointwise aggregation* of times series as it has been recorded in OpenTSDB
3. Multiple time series as they were recorded in OpenTSDB
4. A combination of 3 with either 2 or 1 from above: Multiple time series, where the individual time series represent an aggregation of time series. 

All of the above could also be down sampled (Meaning you get less data points by telling it to average every 30 minutes), but lets focus on the above 4 possibilities to clarify:

### A Single time series
A single time series is just like our series datatype, a bunch of timestamp,value pairs in an array.

### A Single time series representing a *pointwise aggregation*
OpenTSDB will "line up" the datapoints from different series by timestamp (with interpolation), and perform an aggregation such as the sum or avg.

### Multiple time series
There are queries that will return more than one time series. So in a graph you would see multiple lines, but each line represents a pointwise aggregation of time series as they existed in OpenTSDB.

### A Combination of Aggregation and Multiple Time Series
Some queries return multiple time series, and those individual time series an an aggregation of other time series. 

##Metrics and Tags
Which of the above you get back depends on what "tags" you ask for with your metric when querying OpenTSDB. So what are metrics and tags?

###Metrics
The metric is the label for what the time series is a recording of.  Lets say we were collecting desserts eaten. The metric might be something like "desserts.eaten". 

###Tags
Tags are made up two values the tag *key* and the *tag* value. Tags are for tracking various facets of the metric. So for example, our tag keys for desserts.eaten might be as follows:

 - person_name,dessert_type

Our values of person_name would be things like Kyle, Pete and Tom. and our tag values for dessert_type might be pie, cake, and ice cream.

##Querying OpenTSDB
When you query OpenTSDB, you may optionally provide it with tags in different ways. If you provide it with no tags or only some of the tags, it does the **pointwise aggregation** of the tags **you left out**. So if you just ask it for the metric, "desserts.eaten", and the mandatory aggregation option is set to sum, you will get the *pointwise* sum of desserts.eaten of by all person and all dessert_types.  This would be option number 2 from above.

If we want a specific time series as recorded by OpenTSDB, option 1 from above, we must provide all the tag keys with specific tag value pairs. For example, desserts.eaten and person_name=Kyle and dessert_type=Ice_Cream.

If we want a combination of the above, you could ask for just person_name=Kyle and leave out dessert_type (this option number 4). This would tell how many Desserts Kyle consumed but aggregate all the types of desserts.

If you have been keeping track, the final thing is getting multiple times series back. This is done by providing the tag key with a tag value of \*, or | separated values. So for instance if I ask for desserts.eaten, person_name=Kyle, and dessert_type=*, I will get back multiple time series, each repressing how many of each dessert_type Kyle ate. If I did the same but left out person_name, I would get back multiple time series, each representing a specific dessert_type and the aggregation of all people, since leaving out a tag causes OpenTSDB to aggregate.

This is a fair amount to take in. If you don't understand this yet I recommend reading the OpenTSDB docs on the topic, and maybe playing with querying some metrics either via Bosun or OpenTSDB to get started. Then once you feel you have a grasp move onto the next section.

## Bosun's Grouping and Multiplexing