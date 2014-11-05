---
layout: page
title: Examples
order: 3
---

{% raw %}

## Basic Host Based Alerts

### Using a Macro to establish different base contacts for different systems based on name (and alert on low memory)
This is an example of one of our basic alerts at Stack Exchange. We have an IT and SRE team, so for host based alerts we make it so that the appropriate team is alerted for those hosts using our macro and lookup functionality. Macros reduce reuse for alert definitions. The lookup table is like a case statement that lets you change values based on the instance of the alert. The generic template is meant for when warn and crit use basically the same expression with different thresholds.  Templates can include other templates, so we make reusable components that we may want to include in other alerts.

#### Rule

~~~
lookup host_base_contact {
    entry host=nyhq-|-int|den-*|lon-* {
        main_contact = it
        chat_contact = it-chat
    }
    entry host=* {
        main_contact = default
    }
}

macro host_based {
    warnNotification = lookup("host_base_contact", "main_contact")
    critNotification = lookup("host_base_contact", "main_contact")
    warnNotification = lookup("host_base_contact", "chat_contact")
    critNotification = lookup("host_base_contact", "chat_contact")
}

alert os.low.memory {
    macro = host_based
    template = generic
    $notes = In Linux, Buffers and Cache are considered "Free Memory"
    #Unit string shows up in the subject of the "Generic" template
    $unit_string = % Free Memory
    $q = avg(q("avg:os.mem.percent_free{host=*}", $default_time, ""))
    crit = $q <= .5
    warn = $q < 5
    squelch = host=sql|devsearch
}
~~~

#### Template

~~~

template generic {
    body = `{{template "header" .}}
    {{template "def" .}}
    
    {{template "tags" .}}

    {{template "computation" .}}`
    subject = {{.Last.Status}}: {{replace .Alert.Name "." " " -1}}: {{.Eval .Alert.Vars.q | printf "%.2f"}}{{if .Alert.Vars.unit_string}}{{.Alert.Vars.unit_string}}{{end}} on {{.Group.host}}
}

template def {
    body = `<p><strong>Alert definition:</strong>
    <table>
        <tr>
            <td>Name:</td>
            <td>{{replace .Alert.Name "." " " -1}}</td></tr>
        <tr>
            <td>Warn:</td>
            <td>{{.Alert.Warn}}</td></tr>
        <tr>
            <td>Crit:</td>
            <td>{{.Alert.Crit}}</td></tr>
    </table>`
}

template tags {
    body = `<p><strong>Tags</strong>
    
    <table>
        {{range $k, $v := .Group}}
            {{if eq $k "host"}}
                <tr><td>{{$k}}</td><td><a href="{{$.HostView $v}}">{{$v}}</a></td></tr>
            {{else}}
                <tr><td>{{$k}}</td><td>{{$v}}</td></tr>
            {{end}}
        {{end}}
    </table>`
}

template computation {
    body = `
    <p><strong>Computation</strong>
    
    <table>
        {{range .Computations}}
            <tr><td><a href="{{$.Expr .Text}}">{{.Text}}</a></td><td>{{.Value}}</td></tr>
        {{end}}
    </table>`
}

template header {
    body = `<p><a href="{{.Ack}}">Acknowledge alert</a>
    <p><a href="{{.Rule}}">View the Rule + Template in the Bosun's Rule Page</a>
    {{if .Alert.Vars.notes}}
    <p>Notes: {{.Alert.Vars.notes}}
    {{end}}
    {{if .Group.host}}
    <p><a href="https://status.stackexchange.com/dashboard/node?node={{.Group.host}}">View Host {{.Group.host}} in Opserver</a>
    {{end}}
    `
}

~~~

## Forecasting Alerts

### Forecast Disk space
This alert mixes thresholds and forecasting to trigger alerts based on disk space. This can be very useful because it can warn about a situation that will result in the loss of diskspace before it is too late to go and fix the issue. This is combined with a threshold based alert because a good general rule is to try to eliminate duplicate notifications / alerts on the same object.

Once we have string support for lookup tables, the duration that the forecast acts on can be tuned per host when relevant (some disks will have longer or shorter periodicity).

The forecastlr function returns the number of seconds until the specified value will be reached according to a linear regression. It is a pretty naive way of forecasting, but has been effective. Also, there is no reason we can't extend bosun to include more advanced forecasting functions.

![Forecast Notification Image](public/disk_forecast_notification.png)

#### Rule

~~~
lookup disk_space {
    entry host=ny-omni01,disk=E {
        warn_percent_free = 2
        crit_percent_free = 0
    }
    entry host=*,disk=* {
        warn_percent_free = 10
        crit_percent_free = 0
    }
}

alert os.diskspace {
    macro = host_based
    $notes = This alert triggers when there are issues detected in disk capacity. Two methods are used. The first is a traditional percentage based threshold. This alert also uses a linear regression to attempt to predict the amount of time until we run out of space. Forecasting is a hard problem, in particular to apply generically so there is a lot of room for improvement here. But this is a start
    template = diskspace
    $filter = host=*,disk=*
    
    ##Forecast Section
    #Downsampling avg on opentsdb side will save the linear regression a lot of work
    $days_to_zero = (forecastlr(q("avg:6h-avg:os.disk.fs.percent_free{$filter}", "7d", ""), 0) / 60 / 60 / 24)
    #Threshold can be higher here once we support string lookups in lookup tables https://github.com/bosun-monitor/bosun/issues/268
    $warn_days = $days_to_zero > 0 && $days_to_zero < 7
    $crit_days =   $days_to_zero > 0 && $days_to_zero < 1
    
    ##Percent Free Section
    $pf_time = "5m"
    $percent_free = avg(q("avg:os.disk.fs.percent_free{host=*,disk=*}", $pf_time, ""))
    $used = avg(q("avg:os.disk.fs.space_used{host=*,disk=*}", $pf_time, ""))
    $total = avg(q("avg:os.disk.fs.space_total{host=*,disk=*}", $pf_time, ""))
    $warn_percent = $percent_free <  lookup("disk_space", "warn_percent_free")
    #Linux stops root from writing at less than 5%
    $crit_percent = $percent_free <  lookup("disk_space", "crit_percent_free")
    #For graph (long time)
    $percent_free_graph = q("avg:1h-min:os.disk.fs.percent_free{host=*,disk=*}", "4d", "")
    
    ##Main Logic
    warn = $warn_percent || $warn_days
    crit = $crit_percent || $crit_days
    
    ##Options
    squelch = $disk_squelch
    ignoreUnknown = true
    #This is needed because disks go away when the forecast doesn't
    unjoinedOk = true
    
}
~~~

#### Template

~~~
template diskspace {
    body = `{{template "header" .}}
    <p>Host: <a href="{{.HostView .Group.host | short }}">{{.Group.host}}</a>
    <br>Disk: {{.Group.disk}}

    <p>Percent Free: {{.Eval .Alert.Vars.percent_free | printf "%.2f"}}%
    <br>Used: {{.Eval .Alert.Vars.used | bytes}}
    <br>Total: {{.Eval .Alert.Vars.total | bytes}}
    <br>Est. {{.Eval .Alert.Vars.days_to_zero | printf "%.2f"}} days remain until 0% free space
    {{/* .Graph .Alert.Vars.percent_free_graph */}}
    {{/* What is below can be replaced by the below once https://github.com/bosun-monitor/bosun/issues/348 is fixed */}}
    {{printf "q(\"avg:1h-min:os.disk.fs.percent_free{host=%s,disk=%s}\", \"7d\", \"\")" .Group.host .Group.disk | .Graph}}
    `
    subject = {{.Last.Status}}: Diskspace: ({{.Alert.Vars.used | .Eval | bytes}}/{{.Alert.Vars.total | .Eval | bytes}}) {{.Alert.Vars.percent_free | .Eval | printf "%.2f"}}% Free on {{.Group.host}}:{{.Group.disk}} (Est. {{.Eval .Alert.Vars.days_to_zero | printf "%.2f"}} days remain)
}
~~~

## Alerts with Notification Breakdowns

A common pattern is to trigger an alert on a scope that convers multiple metrics
(or hosts, services, etc.), but then to send more detailed information in
notification. This is useful when you notice that certain failures tend to go
together.

### A Linux TCP Stack Alert

When alerting on issues with the Linux TCP stack on a host, you probably don't
want N alerts about all TCP stats, but just one alert that shows breakdowns:

![](public/tcp_notification.png)

#### Rule

~~~
# This macro isn't Show, but makes it so IT and SRE are notified for their
respective systems, when an alert is host based.

lookup linux_tcp {
	entry host=ny-tsdb03 {
		backlog_drop_threshold = 500
	}
	entry host=* {
		backlog_drop_threshold = 100
	}
}

alert linux.tcp {
	macro = host_based
	$notes = `
		This alert checks for various errors or possible issues in the
		TCP stack of a Linux host. Since these tend to happen at the
		same time, combining them into a single alert reduces
		notification noise.`
	template = linux.tcp
	$time = 10m
	$abort_failed = change("sum:rate{counter,,1}:linux.net.stat.tcp.abortfailed{host=*}", "$time", "")
	$abort_mem = change("sum:rate{counter,,1}:linux.net.stat.tcp.abortonmemory{host=*}", "$time", "")
	$ofo_pruned = change("sum:rate{counter,,1}:linux.net.stat.tcp.ofopruned{host=*}", "$time", "")
	$rcv_pruned = change("sum:rate{counter,,1}:linux.net.stat.tcp.rcvpruned{host=*}", "$time", "")
	$backlog_drop = change("sum:rate{counter,,1}:linux.net.stat.tcp.backlogdrop{host=*}", "$time", "")
	$syncookies_sent = change("sum:rate{counter,,1}:linux.net.stat.tcp.syncookiessent{host=*}", "$time", "")
	$total_err = $abort_failed + $ofo_pruned + $rcv_pruned + $backlog_drop + $syncookies_sent
	warn = $abort_failed || $ofo_pruned > 100 || $rcv_pruned > 100 || $backlog_drop > lookup("linux_tcp", "backlog_drop_threshold")  || $syncookies_sent
}
~~~

#### Template Def

~~~
template linux.tcp {
	body = `
		{{template "header" .}}
		<table>
			{{/* TODO: Reference what each stat means */}}
			<tr><th>Stat</th><th>Count in the last {{.Alert.Vars.time}}</th></tr>
			<tr><td>TCP Abort Failed</td><td>{{.Eval .Alert.Vars.abort_failed | printf "%.2f"}}<td></tr>
			<tr><td>Out Of Order Pruned</td><td>{{.Eval .Alert.Vars.ofo_pruned | printf "%.2f"}}<td></tr>
			<tr><td>Receive Pruned</td><td>{{.Eval .Alert.Vars.rcv_pruned | printf "%.2f"}}<td></tr>
			<tr><td>Backlog Dropped</td><td>{{.Eval .Alert.Vars.backlog_drop | printf "%.2f"}}<td></tr>
			<tr><td>Syn Cookies Sent</td><td>{{.Eval .Alert.Vars.syncookies_sent | printf "%.2f"}}<td></tr>
			<tr><td>TOTAL Of Above</td><td>{{.Eval .Alert.Vars.total_err | printf "%.2f"}}<td></tr>
		</table>`
	subject = {{.Last.Status}}: {{.Eval .Alert.Vars.total_err | printf "%.2f"}} tcp errors on {{.Group.host}}
}
~~~

### Backup (Advanced Grouping)

This shows the state of backups based on multiple conditions and multiple metrics. It also simulates a Left Join operation by substituting NaN Values with numbers and the nv functions in the rule, and using the LeftJoin template function. This stretches Bosun when it comes to grouping. Generally you might want to capture this sort of logic in your collector when going to these extremes, but this displays that you don't have to be limited to that:

![](public/netbackup_notification.png)

#### Rule

~~~
alert netbackup {
	template = netbackup
	$tagset = {class=*,client=*,schedule=*}
	#Turn seconds into days
	$attempt_age = max(q("sum:netbackup.backup.attempt_age$tagset", "10m", "")) / 60 / 60 / 24
	$job_frequency = max(q("sum:netbackup.backup.frequency$tagset", "10m", "")) / 60 / 60 / 24
	$job_status = max(q("sum:netbackup.backup.status$tagset", "10m", ""))
	#Add 1/4 a day to the frequency as some buffer
	$not_run_in_time = nv($attempt_age, 1e9) > nv($job_frequency+.25, 1)
	$problems = $not_run_in_time || nv($job_status, 1)
	$summary = sum(t($problems, ""))
	warn = $summary
}
~~~

#### Template Def

~~~
template netbackup {
	subject = `{{.Last.Status}}: Netbackup has {{.Eval .Alert.Vars.summary}} Problematic Backups`
	body = `
	        {{template "header" .}}
	        <p><a href="http://www.symantec.com/business/support/index?page=content&id=DOC5181">Symantec Reference Guide for Status Codes (PDF)</a>
	        <p><a href="https://ny-back02.ds.stackexchange.com/opscenter/">View Backups in Opscenter</a>
	        <h3>Status of all Tape Backups</h3>
		<table>
		<tr><th>Client</th><th>Policy</th><th>Schedule</th><th>Frequency</th><th>Attempt Age</th><th>Status</th></tr>
	{{ range $v := .LeftJoin .Alert.Vars.job_frequency .Alert.Vars.attempt_age .Alert.Vars.job_status}}
		{{ $freq := index $v 0 }}
		{{ $age := index $v 1 }}
		{{ $status := index $v 2 }}
		<tr>
			<td><a href="https://status.stackexchange.com/dashboard/node?node={{$freq.Group.client| short}}">{{$freq.Group.client| short}}</td>
			<td>{{$freq.Group.class}}</td>
			<td>{{$freq.Group.schedule}}</td>
			<td>{{$freq.Value}}</td>
			<td {{if gt $age.Value $freq.Value }} style="color: red;" {{end}}>{{$age.Value | printf "%.2f"}}</td>
			<td{{if gt $status.Value 0.0}} style="color: red;" {{end}}>{{$status.Value}}</td>
		<tr>
	{{end}}
	</table>`
}

~~~


{% endraw %}