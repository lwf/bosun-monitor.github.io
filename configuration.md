---
layout: page
title: Configuration
order: 3
---

{% raw %}

Syntax is sectional, with each section having a type and a name, followed by `{` and ending with `}`. Key/value pairs follow of the form `key = value`. Key names are non-whitespace characters before the `=`. The value goes until end of line and is a string. Multi-line strings are supported using backticks (``` ` ```) to delimit start and end of string. Comments go from a `#` to end of line (unless the `#` appears in a backtick string). Whitespace is trimmed at ends of values and keys. Files are UTF-8 encoded.

## Variables

Variables perform simple text replacement - they are not intelligent. They are any key whose name begins with `$`, and may also be surrounded by braces (`{`, `}`) to disambiguate between shorter keys (ex: `${var}`) Before an expression is evaluated, all variables are evaluated in the text. Variables can be defined at any scope, and will shadow other variables with the same name of higher scope.

### Environment Variables

Environment variables may be used similarly to variables, but with `env.` preceeding the name. For example: `tsdbHost = ${env.TSDBHOST}` (with or without braces). It is an error to specify a non-existent or empty environment variable.

## Sections

### globals

Globals are all key=value pairs not in a section. These are generally placed at the top of the file.

#### Required

* tsdbHost: OpenTSDB relay destination

#### Optional

* checkFrequency: time between alert checks, defaults to `5m`
* stateFile: bosun state file, defaults to `bosun.state`
* smtpHost: SMTP server, required for email notifications
* emailFrom: from address for notification emails, required for email notifications
* httpListen: HTTP listen address, defaults to `:8070`
* relayListen: OpenTSDB relay listen address, defaults to `:4242`
* webDir: directory with template and static assets, defaults to `web`
* responseLimit: number of bytes to limit OpenTSDB responses, defaults to 1MB (`1048576`)
* unknownTemplate: name of the template for unknown alerts
* squelch: see [alert squelch](#squelch)
* ping: if present, will ping all values tagged with host

### macro

Macros are sections that can define anything (including variables). It is not an error to reference an unknown variable in a macro. Other sections can reference the macro with `macro = name`. The macro's data will be expanded with the current variable definitions and inserted at that point in the section. Multiple macros may be thus referenced at any time. Macros may reference other macros. For example:

```
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
```

Will yield a warn expression for the os.high_cpu alert:

```
avg(q("avg:rate:os.cpu{host=ny-nexpose01}", "2m", "")) > 80
```

and set `warnNotification = default` for that alert.

### template

Templates are the message body for emails that are sent when an alert is triggered. Syntax is the golang [text/template](http://golang.org/pkg/text/template/) package. Variable expansion is not performed on templates because `$` is used in the template language, but a `V()` function is provided instead. Email bodies are HTML, subjects are plaintext. Macro support is currently disabled for the same reason due to implementation details.

* body: message body (HTML)
* subject: message subject (plaintext)

Variables and functions available to alert templates:

* Expr: string of evaluated expression
* Touched: time this alert was last updated
* Group: dictionary of tags for this alert (i.e., host=ny-redis01, db=42)
* Subject: string of template subject
* History: array of Events. An Event has a `Status` field (an integer) with a textual string representation; and a `Time` field. Most recent last. The status fields have identification methods: `IsNormal()`, `IsWarning()`, `IsCritical()`, `IsUnknown()`.
* Last: last Event of History array
* Alert: dictionary of rule data (but the first letter of each is uppercase)
  * Name
  * Crit
  * Warn
  * Vars: alert variables, prefixed without the `$`. For example: `{{.Alert.Vars.q}}` to print `$q`.
* Eval(string): executes the given expression and returns the first result with identical tags, or `nil` tags if none exists, otherwise `nil`.
* EvalAll(string): executes the given expression and returns all results.
* LeftJoin(...string): Takes 2 or more expressions, evaluates them all in global context, and performs a left outer join any results that are a subset of the first argument..
* Ack: URL for alert acknowledgement
* Graph(string): returns an SVG graph of the expression with identical tags
* GraphAll(string): returns an SVG graph of the expression
* Lookup("table", "key"): Looks up the value for the key based on the tagset of the alert in the specified lookup table

Global template functions:

* V: performs variable expansion on the argument and returns it. Needed since normal variable expansion is not done due to the `$` character being used by the Go template syntax.
* bytes: converts the string input into a human-readable number of bytes with extension KB, MB, GB, etc.
* short: Trims the string to everything before the first period. Useful for turning a FQDN into a shortname. For example: `{{short "foo.baz.com"}}` -> `foo`.
* replace: [strings.Replace](http://golang.org/pkg/strings/#Replace)

All body templates are associated, and so may be executed from another. Use the name of the other template section for inclusion. Subject templates are similarly associated.

An example:

```

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
```

#### unknown template

The unknown template (set by the global option `unknownTemplate`) acts differently than alert templates. It receives groups of alerts since unknowns tend to happen in groups (i.e., a host stops reporting and all alerts for that host trigger unknown at the same time).

Variables and function available to the unknown template:

* Time: [time](http://golang.org/pkg/time/#Time) this group triggered unknown
* Name: group name
* Group: list of names of alerts

Example:

```
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
```

### alert

An alert is an evaluated expression which can trigger actions like emailing or logging. The expression must yield a scalar. The alert triggers if not equal to zero. Alerts act on each tag set returned by the query. It is an error for alerts to specify start or end times. Those will be determined by the various functions and the alerting system.

* template: name of template
* crit: expression of a critical alert (which will send an email)
* warn: expression of a warning alert (viewable on the web interface)
* <a name="squelch"></a>squelch: comma-separated list of `tagk=tagv` pairs. `tagv` is a regex. If the current tag group matches all values, the alert is squelched, and will not trigger as crit or warn. For example, `squelch = host=ny-web.*,tier=prod` will match any group that has at least that host and tier. Note that the group may have other tags assigned to it, but since all elements of the squelch list were met, it is considered a match. Multiple squelch lines may appear; a tag group matches if any of the squelch lines match.
* critNotification: comma-separated list of notifications to trigger on critical. This line may appear multiple times and duplicate notifications, which will be merged so only one of each notification is triggered. Lookup tables may be used when `lookup("table", "key")` is an entire `critNotification` value. See example below.
* warnNotification: identical to critNotification, but for warnings
* unknown: time at which to mark an alert unknown if it cannot be evaluated; defaults to global checkFrequency
* unjoinedOk: if present, will ignore unjoined expression errors.

Example of notification lookups:

```
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
```


### notification

A notification is a chained action to perform. The chaining continues until the chain ends or the alert is acknowledged. At least one action must be specified. `next` and `timeout` are optional. Notifications are independent of each other and executed in concurrently (if there are many notifications for an alert, one will not block another).

* next: name of next notification to execute after timeout. Can be itself.
* timeout: duration to wait until next is executed. If not specified, will happen immediately.
* body: overrides the default POST body. The alert subject is passed as the templates `.` variable. The `V` function is available as in other templates. Additionally, a `json` function will output JSON-encoded data.

#### actions

* email: list of email address of contacts. Comma separated. Supports formats `Person Name <addr@domain.com>` and `addr@domain.com`.  Alert template subject and body used for the email.
* post: HTTP post to given URL. Alert subject sent as request body. Content type is set as `application/x-www-form-urlencoded`.
* get: HTTP get to given URL
* print: prints template subject to stdout. print value is ignored, so just use: `print = true`.

Example:

```
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
	body = payload={"username": "bosun", "text": {{.|json}}, "icon_url": "http://stackexchange.github.io/bosun/images/tsaf-logo-mark.png"} 
}
```

### lookup

Lookups are used when different values are needed based on the group. For example, an alert for high CPU use may have a general setting, but need to be higher for known high-CPU machines. Lookups have subsections for lookup entries. Each entry subsection is named with an OpenTSDB tag group, and supports globbing. Entry subsections have arbitrary key/value pairs.

The `lookup` function can be used in expressions to query lookup data. It takes two arguments: the name of the lookup table and the key to be extracted. When the function is executed, all possible combinations of tags are fetched from the search service, matched to the correct rule, and returned. The first successful match is used. Unmatched groups are ignored.

For example, to filter based on host:

```
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
```

Multiple groups are supported and separated by commas. For example:

```
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
```


# <a name="expressions"></a>Expressions

## Groups

Groups are OpenTSDB queries that return multiple tag sets. Any query with `*` or `|` in the tag list is such a query. Both scalars and series support groups, which are multiplexed with all other tag sets that are equivalent. Thus, you can do things like `avg([sum:sys.cpu{host=ny-*}]) > 0.8` to check many hosts at once.

If multiple queries appear in the same expression, they can be used together if their groups are equal or one is a strict subset of the other.

## Functions

Data types:

* scalar: a numeric value; not paired with a timestamp
* series: an array of timestamp-value pairs

### OpenTSDB Query Functions

Query functions take a query string (like `sum:os.cpu{host=*}`) and return a series.

#### q(query, startDuration, endDuration)

Generic query from endDuration to startDuration ago. If endDuration is the empty string (`""`), now is used. Support duration units are listed in [the docs](http://opentsdb.net/docs/build/html/user_guide/query/dates.html). Refer to [the docs](http://opentsdb.net/docs/build/html/user_guide/query/index.html) for query syntax. The query argument is the value part of the `m=...` expressions. `*` and `|` are fully supported. In addition, queries like `sys.cpu.user{host=ny-*}` are supported. These are performed by an additional step which determines valid matches, and replaces `ny-*` with `ny-web01|ny-web02|...|ny-web10` to achieve the same result. This lookup is kept in memory by the system and does not incur any additional OpenTSDB API requests, but does require tcollector instances pointed to the bosun server.

#### band(query, duration, period, num)

Band performs `num` queries of `duration` each, `period` apart and concatenates them together, starting `period` ago. So `band("avg:os.cpu", "1h", "1d", 7)` will return a series comprising of the given metric from 1d to 1d-1h-ago, 2d to 2d-1h-ago, etc, until 8d. This is a good way to get a time block from a certain hour of a day or certain day of a week over a long time period.

#### change(query, startDuration, endDuration)

Change is a way to determine the change of a query from startDuration to endDuration. If endDuration is the empty string (`""`), now is used. The query must either be a rate or a counter converted to a rate with the `agg:rate:metric` flag.

For example, assume you have a metric `net.bytes` that records the number of bytes that have been sent on some interface since boot. We could just subtract the end number from the start number, but if a reboot or counter rollover occurred during that time our result will be incorrect. Instead, we ask OpenTSDB to convert our metric to a rate and handle all of that for us. So, to get the number of bytes in the last hour, we could use:

`change("avg:rate:net.bytes", "60m", "")`

Note that this is implemented using the bosun's `avg` function. The following is exactly the same as the above example:

`avg(q("avg:rate:net.bytes", "60m", "")) * 60 * 60`

#### diff(query, startDuration, endDuration)

Diff returns the last point of the series minus the first point.

#### count(query, startDuration, endDuration)

Count returns the number of groups in the query as an ungrouped scalar.

### Reduction Functions

All reduction functions take a series and return a number.

#### dev(series)

Standard deviation.

#### avg(series)

Average.

#### sum(series)

Sum.

#### min(series)

Returns the minimum value of the series, same as calling percentile(series, 0).

#### median(series)

Returns the median value of the series, same as calling percentile(series, .5).

#### max(series)

Returns the maximum value of the series, same as calling percentile(series, 1).

#### percentile(series, p)

Returns the value from the series at the percentile p. Min and Max can be simulated using `p <= 0` and `p >= 1`, respectively.

#### last(series)

Returns the last (most recent) data point in the series.

#### first(series)

Returns the first (least recent) data point in the series.

#### since(series)

Returns the number of seconds since the latest data point not more than duration old. Same duration caveat as the `recent()` function.

#### forecastlr(series, y_val)

Returns the number of seconds until a linear regression of the series will reach y_val.

### Group Functions

Group functions modify the OpenTSDB groups.

#### ungroup(number)

Returns the input with its group removed. Used to combine queries from two differing groups.

#### t(number, group)

Transposes N series of length 1 to 1 series of length N. If the group parameter is not the empty string, the number of series returned is equal to the number of tagks passed. This is useful for performing scalar aggregation across multiple results from a query. For example, to get the total memory used on the web tier: `sum(t(avg(q("avg:os.mem.used{host=*-web*}", "5m", "")), ""))`.

## Operators

The standard math (+, -, *, /), relational (<, >, ==, !=, >= <=), logical (&&, ||), and unary(!, -) operators are supported. The binary operators require one side to be a scalar. Arrays will have the operator applied to each element. Examples:

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

```
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
```

{% endraw %}
