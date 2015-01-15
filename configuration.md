---
layout: page
title: Configuration
order: 3
---

{% raw %}

* auto-gen TOC:
{:toc}

Syntax is sectional, with each section having a type and a name, followed by `{` and ending with `}`. Key/value pairs follow of the form `key = value`. Key names are non-whitespace characters before the `=`. The value goes until end of line and is a string. Multi-line strings are supported using backticks to delimit start and end of string. Comments go from a `#` to end of line (unless the `#` appears in a backtick string). Whitespace is trimmed at ends of values and keys. Files are UTF-8 encoded.

## Variables

Variables perform simple text replacement - they are not intelligent. They are any key whose name begins with `$`, and may also be surrounded by braces (`{`, `}`) to disambiguate between shorter keys (ex: `${var}`) Before an expression is evaluated, all variables are evaluated in the text. Variables can be defined at any scope, and will shadow other variables with the same name of higher scope.

### Environment Variables

Environment variables may be used similarly to variables, but with `env.` preceeding the name. For example: `tsdbHost = ${env.TSDBHOST}` (with or without braces). It is an error to specify a non-existent or empty environment variable.

## Sections

### globals

Globals are all key=value pairs not in a section. These are generally placed at the top of the file.
Every variable is optional, though you should enable at least 1 backend.

#### backends

* tsdbHost: OpenTSDB host. Must be GZIP-aware (use the [next branch](https://github.com/opentsdb/opentsdb/tree/next)). Can specify both host and port: `tsdb-host:4242`. Defaults to port 4242 if no port specified.
* graphiteHost: Graphite host. Same format as tsdbHost.
* logstashElasticHost: Elasticsearch host populated by logstash. Same format as tsdbHost.

#### settings

* checkFrequency: time between alert checks, defaults to `5m`
* emailFrom: from address for notification emails, required for email notifications
* httpListen: HTTP listen address, defaults to `:8070`
* hostname: when generating links in templates, use this value as the hostname instead of using the system's hostname
* ping: if present, will ping all values tagged with host
* responseLimit: number of bytes to limit OpenTSDB responses, defaults to 1MB (`1048576`)
* smtpHost: SMTP server, required for email notifications
* squelch: see [alert squelch](#squelch)
* stateFile: bosun state file, defaults to `bosun.state`
* unknownTemplate: name of the template for unknown alerts

#### SMTP Authentication

These optional fields, if either is specified, will authenticate with the SMTP server

* smtpUsername: SMTP username
* smtpPassword: SMTP password

### macro

Macros are sections that can define anything (including variables). It is not an error to reference an unknown variable in a macro. Other sections can reference the macro with `macro = name`. The macro's data will be expanded with the current variable definitions and inserted at that point in the section. Multiple macros may be thus referenced at any time. Macros may reference other macros. For example:

~~~
$default_time = "2m"

macro m1 {
	$w = 80
	warnNotification = default
}

macro m2 {
	macro = m1
	$c = 90
}

alert os.high_cpu {
	$q = avg(q("avg:rate:os.cpu{host=ny-nexpose01}", $default_time, ""))
	macro = m2
	warn = $q > $w
	crit = $q >= $c
}
~~~

Will yield a warn expression for the os.high_cpu alert:

~~~
avg(q("avg:rate:os.cpu{host=ny-nexpose01}", "2m", "")) > 80
~~~

and set `warnNotification = default` for that alert.

### template

Templates are the message body for emails that are sent when an alert is triggered. Syntax is the golang [text/template](http://golang.org/pkg/text/template/) package. Variable expansion is not performed on templates because `$` is used in the template language, but a `V()` function is provided instead. Email bodies are HTML, subjects are plaintext. Macro support is currently disabled for the same reason due to implementation details.

* body: message body (HTML)
* subject: message subject (plaintext)

#### Variables available to alert templates:

* Ack: URL for alert acknowledgement
* Expr: string of evaluated expression
* Group: dictionary of tags for this alert (i.e., host=ny-redis01, db=42)
* History: array of Events. An Event has a `Status` field (an integer) with a textual string representation; and a `Time` field. Most recent last. The status fields have identification methods: `IsNormal()`, `IsWarning()`, `IsCritical()`, `IsUnknown()`, `IsError()`.
* IsEmail: true if template is being rendered for an email. Needed because email clients often modify HTML.
* Last: last Event of History array
* Subject: string of template subject
* Touched: time this alert was last updated
* Alert: dictionary of rule data (but the first letter of each is uppercase)
  * Crit
  * Name
  * Vars: alert variables, prefixed without the `$`. For example: `{{.Alert.Vars.q}}` to print `$q`.
  * Warn

#### Functions available to alert templates:

* Eval(string): executes the given expression and returns the first result with identical tags, or `nil` tags if none exists, otherwise `nil`.
* EvalAll(string): executes the given expression and returns all results.
* GetMeta(metric, name, tags): Returns metadata data for the given combination of metric, metadata name, and tag. `metric` and `name` are strings. `tags` may be a tag string (`"tagk=tagv,tag2=val2"`) or a tag set (`.Group`). If If `name` is the empty string, a slice of metadata matching the metric and tag is returned. Otherwise, only the metadata value is returned for the given name, or `nil` for no match.
* Graph(string): returns an SVG graph of the expression with identical tags
* GraphAll(string): returns an SVG graph of the expression
* LeftJoin(expr, expr[, expr...]): results of the first expression (which may be a string or an expression) are left joined to results from all following expressions.
* Lookup("table", "key"): Looks up the value for the key based on the tagset of the alert in the specified lookup table
* LookupAll("table", "key", "tag=val,tag2=val2"): Looks up the value for the key based on the tagset specified in the given lookup table
* HTTPGet("url"): Performs an http get and returns the raw text of the url
* LSQuery("indexRoot", "filterString", "startDuration", "endDuration", nResults). Returns an array of a length up to nResults of Marshaled Json documents (Go: marshaled to interface{}). This is like the lscount and lsstat functions. There is no `keyString` because the group (aka tags) if the alert is used.
* LSQueryAll("indexRoot", "keyString" filterString", "startDuration", "endDuration", nResults). Like LSQuery but you have to specify the `keyString` since it is not scoped to the alert.

Global template functions:

* V: performs variable expansion on the argument and returns it. Needed since normal variable expansion is not done due to the `$` character being used by the Go template syntax.
* bytes: converts the string input into a human-readable number of bytes with extension KB, MB, GB, etc.
* replace: [strings.Replace](http://golang.org/pkg/strings/#Replace)
* short: Trims the string to everything before the first period. Useful for turning a FQDN into a shortname. For example: `{{short "foo.baz.com"}}` -> `foo`.

All body templates are associated, and so may be executed from another. Use the name of the other template section for inclusion. Subject templates are similarly associated.

An example:

~~~
template name {
	body = Name: {{.Alert.Name}}
}
template ex {
	body = `Alert definition:
	{{template "name" .}}
	Crit: {{.Alert.Crit}}

	Tags:{{range $k, $v := .Tags}}
	{{$k}}: {{$v}}{{end}}
	`
	subject = {{.Alert.Name}}: {{.Alert.Vars.q | .E}} on {{.Tags.host}}
}
~~~

#### unknown template

The unknown template (set by the global option `unknownTemplate`) acts differently than alert templates. It receives groups of alerts since unknowns tend to happen in groups (i.e., a host stops reporting and all alerts for that host trigger unknown at the same time).

Variables and function available to the unknown template:

* Group: list of names of alerts
* Name: group name
* Time: [time](http://golang.org/pkg/time/#Time) this group triggered unknown

Example:

~~~
template ut {
	subject = {{.Name}}: {{.Group | len}} unknown alerts
	body = `
	<p>Time: {{.Time}}
	<p>Name: {{.Name}}
	<p>Alerts:
	{{range .Group}}
		<br>{{.}}
	{{end}}`
}

unknownTemplate = ut
~~~

### alert

An alert is an evaluated expression which can trigger actions like emailing or logging. The expression must yield a scalar. The alert triggers if not equal to zero. Alerts act on each tag set returned by the query. It is an error for alerts to specify start or end times. Those will be determined by the various functions and the alerting system.

* crit: expression of a critical alert (which will send an email)
* critNotification: comma-separated list of notifications to trigger on critical. This line may appear multiple times and duplicate notifications, which will be merged so only one of each notification is triggered. Lookup tables may be used when `lookup("table", "key")` is an entire `critNotification` value. See example below.
* ignoreUnknown: if present, will prevent alert from becoming unknown
* squelch: <a name="squelch"></a> comma-separated list of `tagk=tagv` pairs. `tagv` is a regex. If the current tag group matches all values, the alert is squelched, and will not trigger as crit or warn. For example, `squelch = host=ny-web.*,tier=prod` will match any group that has at least that host and tier. Note that the group may have other tags assigned to it, but since all elements of the squelch list were met, it is considered a match. Multiple squelch lines may appear; a tag group matches if any of the squelch lines match.
* template: name of template
* unjoinedOk: if present, will ignore unjoined expression errors
* unknown: time at which to mark an alert unknown if it cannot be evaluated; defaults to global checkFrequency
* warn: expression of a warning alert (viewable on the web interface)
* warnNotification: identical to critNotification, but for warnings

Example of notification lookups:

~~~
notification all {
	#...
}

notification n {
	#...
}

notification d {
	#...
}

lookup l {
	entry host=a {
		v = n
	entry host=b* {
		v = d
	}
}

alert a {
	crit = 1
	critNotification = all # All alerts have the all notification.
	# Other alerts are passed through the l lookup table and may add n or d.
	# If the host tag does not match a or b*, no other notification is added.
	critNotification = lookup("l", "v")
}
~~~

### notification

A notification is a chained action to perform. The chaining continues until the chain ends or the alert is acknowledged. At least one action must be specified. `next` and `timeout` are optional. Notifications are independent of each other and executed in concurrently (if there are many notifications for an alert, one will not block another).

* body: overrides the default POST body. The alert subject is passed as the templates `.` variable. The `V` function is available as in other templates. Additionally, a `json` function will output JSON-encoded data.
* next: name of next notification to execute after timeout. Can be itself.
* timeout: duration to wait until next is executed. If not specified, will happen immediately.

#### actions

* email: list of email address of contacts. Comma separated. Supports formats `Person Name <addr@domain.com>` and `addr@domain.com`.  Alert template subject and body used for the email.
* get: HTTP get to given URL
* post: HTTP post to given URL. Alert subject sent as request body. Content type is set as `application/x-www-form-urlencoded`.
* print: prints template subject to stdout. print value is ignored, so just use: `print = true`

Example:

~~~
# HTTP Post to a chatroom, email in 10m if not ack'd
notification chat {
	next = email
	timeout = 10m
	post = http://chat.meta.stackoverflow.com/room/318?key=KEY&message=whatever
}

# email sysadmins and Nick each day until ack'd
notification email {
	email = sysadmins@stackoverflow.com, nick@stackoverflow.com
	next = email
	timeout = 1d
}

# post to a slack.com chatroom {
	post = https://company.slack.com/services/hooks/incoming-webhook?token=TOKEN
	body = payload={"username": "bosun", "text": {{.|json}}, "icon_url": "http://stackexchange.github.io/bosun/public/bosun-logo-mark.svg"} 
}
~~~

### lookup

Lookups are used when different values are needed based on the group. For example, an alert for high CPU use may have a general setting, but need to be higher for known high-CPU machines. Lookups have subsections for lookup entries. Each entry subsection is named with an OpenTSDB tag group, and supports globbing. Entry subsections have arbitrary key/value pairs.

The `lookup` function can be used in expressions to query lookup data. It takes two arguments: the name of the lookup table and the key to be extracted. When the function is executed, all possible combinations of tags are fetched from the search service, matched to the correct rule, and returned. The first successful match is used. Unmatched groups are ignored.

For example, to filter based on host:

~~~
lookup cpu {
	entry host=web-* {
		high = 0.5
	}
	entry host=sql-* {
		high = 0.8
	}
	entry host=* {
		high = 0.3
	}
}

alert cpu {
	crit = avg(q("avg:rate:os.cpu{host=*}", "5m", "")) > lookup("cpu", "high")
}
~~~

Multiple groups are supported and separated by commas. For example:

~~~
lookup cpu {
	entry host=web-*,dc=eu {
		high = 0.5
	}
	entry host=sql-*,dc=us {
		high = 0.8
	}
	entry host=*,dc=us {
		high = 0.3
	}
	entry host=*,dc=* {
		high = 0.4
	}
}

alert cpu {
	crit = avg(q("avg:rate:os.cpu{host=*,dc=*}", "5m", "")) > lookup("cpu", "high")
}
~~~


# Expressions

## Groups

Groups are OpenTSDB queries that return multiple tag sets. Any query with `*` or `|` in the tag list is such a query. Both scalars and series support groups, which are multiplexed with all other tag sets that are equivalent. Thus, you can do things like `avg([sum:sys.cpu{host=ny-*}]) > 0.8` to check many hosts at once.

If multiple queries appear in the same expression, they can be used together if their groups are equal or one is a strict subset of the other.

## Functions

Data types:

* scalar: a numeric value; not paired with a timestamp
* series: an array of timestamp-value pairs

### Graphite Query Functions

#### GraphiteQuery(query, startDuration, endDuration, format)

Performs a graphite query.  the duration format is the internal bosun format (which happens to be the same as OpenTSDB's format).
Functions pretty much the same as q() (see that for more info) but for graphite.
The format string lets you annotate how to parse series as returned by graphite, as to yield tags in the format that bosun expects.
The tags are dot-separated and the amount of "nodes" (dot-separated words) should match what graphite returns.
Irrelevant nodes can be left empty.

For example:

`groupByNode(collectd.*.cpu.*.cpu.idle,1,'avg')`

returns series named like `host1`, `host2` etc, in which case the format string can simply be `host`.

`collectd.web15.cpu.*.cpu.*`

returns series named like `collectd.web15.cpu.3.idle`, requiring a format like  `.host..core..cpu_type`.

For advanced cases, you can use graphite's alias(), aliasSub(), etc to compose the exact parseable output format you need.
This happens when the outer graphite function is something like "avg()" or "sum()" in which case graphite's output series will be identified as "avg(some.string.here)".

#### GraphiteBand(query, duration, period, format, num)

Like band() but for graphite queries.

### Logstash Query Functions

#### lscount(indexRoot, keyString, filterString, bucketDuration, startDuration, endDuration)

lscount returns the per second rate of matching log documents.

  * `indexRoot` is the root name of the index to hit, the format is expected to be `fmt.Sprintf("%s-%s", index_root, d.Format("2006.01.02"))`.
  * `keyString` creates groups (like tagsets) and can also filter those groups. It is the format of `"field:regex,field:regex..."` The `:regex` can be ommited.
  * `filterString` is an Elastic regexp query that can be applied to any field. It is in the same format as the keystring argument.
  * `bucketDuration` is in the same format is an opentsdb duration, and is the size of buckets returned (i.e. counts for every 10 minutes). In the case of lscount, that number is normalized to a per second rate by dividing the result by the number of seconds in the duration.
  * `startDuration` and `endDuration` set the time window from now - see the OpenTSDB q() function for more details.

#### lsstat(indexRoot, keyString, filterString, field, rStat, bucketDuration, startDuration, endDuration)

lstat returns various summary stats per bucket for the specified `field`. The field must be numeric in elastic. rStat can be one of `avg`, `min`, `max`, `sum`, `sum_of_squares`, `variance`, `std_deviation`. The rest of the fields behave the same as lscount except that there is no division based on `bucketDuration` since these are summary stats.

#### Caveats:
  * There is currently no escaping in the keystring, so if you regex needs to have a comma or double quote you are out of luck.
  * The regexs in keystring are applied twice. First as a regexp filter to elastic, and then as a go regexp to the keys of the result. This is because the value could be an array and you will get groups that should be filtered. This means regex language is the intersection of the golang regex spec and the elastic regex spec.
  * If the type of the field value in Elastic (aka the mapping) is a number then the regexes won't act as a regex. The only thing you can do is an exact match on the number, ie "eventlogid:1234". It is recommended that anything that is a identifier should be stored as a string since they are not numbers even if they are made up entirely of numerals.
  * As of January 15, 2015 - logstash functionality is new so these functions may change a fair amount based on experience using them in alerts.
  * Alerts using this information likely want to set ignoreUnknown, since only "groups" that appear in the time frame are in the results.

### OpenTSDB Query Functions

Query functions take a query string (like `sum:os.cpu{host=*}`) and return a series.

#### band(query, duration, period, num)

Band performs `num` queries of `duration` each, `period` apart and concatenates them together, starting `period` ago. So `band("avg:os.cpu", "1h", "1d", 7)` will return a series comprising of the given metric from 1d to 1d-1h-ago, 2d to 2d-1h-ago, etc, until 8d. This is a good way to get a time block from a certain hour of a day or certain day of a week over a long time period.

#### change(query, startDuration, endDuration)

Change is a way to determine the change of a query from startDuration to endDuration. If endDuration is the empty string (`""`), now is used. The query must either be a rate or a counter converted to a rate with the `agg:rate:metric` flag.

For example, assume you have a metric `net.bytes` that records the number of bytes that have been sent on some interface since boot. We could just subtract the end number from the start number, but if a reboot or counter rollover occurred during that time our result will be incorrect. Instead, we ask OpenTSDB to convert our metric to a rate and handle all of that for us. So, to get the number of bytes in the last hour, we could use:

`change("avg:rate:net.bytes", "60m", "")`

Note that this is implemented using the bosun's `avg` function. The following is exactly the same as the above example:

`avg(q("avg:rate:net.bytes", "60m", "")) * 60 * 60`

#### count(query, startDuration, endDuration)

Count returns the number of groups in the query as an ungrouped scalar.

#### diff(query, startDuration, endDuration)

Diff returns the last point of the series minus the first point.

#### q(query, startDuration, endDuration)

Generic query from endDuration to startDuration ago. If endDuration is the empty string (`""`), now is used. Support d( units are listed in [the docs](http://opentsdb.net/docs/build/html/user_guide/query/dates.html). Refer to [the docs](http://opentsdb.net/docs/build/html/user_guide/query/index.html) for query syntax. The query argument is the value part of the `m=...` expressions. `*` and `|` are fully supported. In addition, queries like `sys.cpu.user{host=ny-*}` are supported. These are performed by an additional step which determines valid matches, and replaces `ny-*` with `ny-web01|ny-web02|...|ny-web10` to achieve the same result. This lookup is kept in memory by the system and does not incur any additional OpenTSDB API requests, but does require tcollector instances pointed to the bosun server.

### Reduction Functions

All reduction functions take a series and return a number.

#### avg(series)

Average.

#### dev(series)

Standard deviation.

#### first(series)

Returns the first (least recent) data point in the series.

#### forecastlr(series, y_val)

Returns the number of seconds until a linear regression of the series will reach y_val.

#### last(series)

Returns the last (most recent) data point in the series.

#### len(series)

Returns the length of the series.

#### max(series)

Returns the maximum value of the series, same as calling percentile(series, 1).

#### median(series)

Returns the median value of the series, same as calling percentile(series, .5).

#### min(series)

Returns the minimum value of the series, same as calling percentile(series, 0).

#### percentile(series, p)

Returns the value from the series at the percentile p. Min and Max can be simulated using `p <= 0` and `p >= 1`, respectively.

#### since(series)

Returns the number of seconds since the latest data point not more than duration old.

#### sum(series)

Sum.

### Group Functions

Group functions modify the OpenTSDB groups.

#### t(number, group)

Transposes N series of length 1 to 1 series of length N. If the group parameter is not the empty string, the number of series returned is equal to the number of tagks passed. This is useful for performing scalar aggregation across multiple results from a query. For example, to get the total memory used on the web tier: `sum(t(avg(q("avg:os.mem.used{host=*-web*}", "5m", "")), ""))`.

##### How transpose works conceptually
Transpose Grouped results into a Single Result:  

Before Transpose (Value Type is Number):  

Group       | Value  |
----------- | ----- |
{host=web01} | 1 |
{host=web02} | 7 |
{host=web03} | 4 |

After Transpose (Value Type is Series):  

Group        | Value  |
----------- | ----- |
{} | 1,7,4 |

Transpose Groups results into Multiple Results:  

Before Transpose by host (Value Type is Number)  

Group        | Value  |
----------- | ----- |
{host=web01,disk=c} | 1 |
{host=web01,disc=d} | 3 |
{host=web02,disc=c} | 4 |

After Transpose by "host" (Value type is Series)  

Group        | Value  |
------------ | ------ |
{host=web01} | 1,3 |
{host=web02} | 4 |

##### Useful Example of Transpose
Alert if more than 50% of servers in a group have ping timeouts

	alert or_down {
		$group = host=or-*
		# bosun.ping.timeout is 0 for no timeout, 1 for timeout
		$timeout = q("sum:bosun.ping.timeout{$group}", "5m", "")
		# timeout will have multiple groups, such as or-web01,or-web02,or-web03.
		# each group has a series type (the observations in the past 10 mintutes)
		# so we need to *reduce* each series values of each group into a single number:
		$max_timeout = max($timeout)
		# Max timeout is now a group of results where the value of each group is a number. Since each
		# group is an alert instance, we need to regroup this into a sigle alert. We can do that by 
		# transposing with t()
		$max_timeout_series = t("$max_timeout", "")
		# $max_timeout_series is now a single group with a value of type series. We need to reduce
		# that series into a single number in order to trigger an alert.
		$number_down_series = sum($max_timeout_series)
		$total_servers = len($max_timeout_series)
		$percent_down = $number_down_servers / $total_servers) * 100
		warnNotificaiton = $percent_down > 25
	}

Since our templates can reference any variable in this alert, we can show which servers are down in the notification, even though the alert just triggers on 25% of or-\* servers being down.

#### ungroup(number)

Returns the input with its group removed. Used to combine queries from two differing groups.

### Other Functions

#### abs(number)

Returns the absolute value of the number.

#### d(string)

Returns the number of seconds of the [OpenTSDB duration string](http://opentsdb.net/docs/build/html/user_guide/query/dates.html).

#### dropna(series)

Remove any NaN or Inf values from a series. Will error if this operation results in an empty series.

#### lookup(table, key)

Returns the first key from the given lookup table with matching tags.

#### nv(number, scalar)

Change the NaN value during binary operations (when joining two queries) of unknown groups to the scalar. This is useful to prevent unknown group and other errors from bubbling up.

## Operators

The standard math (`+`, `-`, `*`, `/`), relational (`<`, `>`, `==`, `!=`, `>=`, `<=`), logical (`&&`, `||`), and unary(`!`, `-`) operators are supported. The binary operators require one side to be a scalar. Arrays will have the operator applied to each element. Examples:

* `q("q") + 1`
* `-q("q")`
* `5 > q("q")`
* `6 / 8`

### Precedence

From highest to lowest:

1. `()`, `!`, unary `-`
1. `*`, `/`
1. `+`, `-`
1. `==`, `!=`, `>`, `>=`, `<`, `<=`
1. `&&`
1. `||`

## Numbers

Numbers may be specified in decimal (123.45), octal (072), or hex (0x2A). Exponentials and signs are supported (-0.8e-2).

# Example File

~~~
tsdbHost = tsdb01.stackoverflow.com:4242
smtpHost = mail.stackoverflow.com:25

template cpu {
	body = `Alert definition:
	Name: {{.Alert.Name}}
	Crit: {{.Alert.Crit}}
	
	Tags:{{range $k, $v := .Tags}}
	{{$k}}: {{$v}}{{end}}
	`
	subject = cpu idle at {{.Alert.Vars.q | .E}} on {{.Tags.host}}
}

notification default {
	email = someone@domain.com
	next = default
	timeout = 1h
}

alert cpu {
	template = cpu
	$q = avg(q("sum:rate:linux.cpu{host=*,type=idle}", "1m"))
	crit = $q < 40
	notification = default
}
~~~

{% endraw %}
