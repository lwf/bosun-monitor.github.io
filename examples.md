---
layout: page
title: Examples
order: 3
---

{% raw %}

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