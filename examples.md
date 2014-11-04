---
layout: page
title: Examples
order: 3
---

# Alert Examples

## Alerts with Notification Breakdowns
A common pattern is to trigger an alert on a scope that convers multiple metrics (or hosts, services, etc...), but then to send more detailed information in notification. This is useful when you notice that certain failures tend to go together. 

### A Linux TCP Stack Alert
When alerting on issues with the Linux TCP stack on a host, you probably don't want N alerts about all TCP stats, but just one alert that shows breakdowns:

![](public/tcp_notification.png)

##### Rule

```
lookup linux_tcp {
    entry host=ny-tsdb03 {
        backlog_drop_threshold = 500
    }
    entry host=* {
        backlog_drop_threshold = 100
    }
}

alert linux.tcp {
    #This Macro Isn't Show, but makes it so IT is notified for their systems, and SRE is notified for theirs hosts, when an alert is host based
    macro = host_based
    $notes = This alert checks for various errors or possible issues in the TCP stack of a Linux host. Since these tend to happen at the same time, combining them into a single alert reduces notification noise.
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
```

##### Template Def

```
template linux.tcp {
    body = ``{{template "header" .}}
    <table>
        {{/* TODO: Reference what each stat means */}}
        <tr><th>Stat</th><th>Count in the last {{.Alert.Vars.time}}</th></tr>
        <tr><td>TCP Abort Failed</td><td>{{.Eval .Alert.Vars.abort_failed | printf "%.2f"}}<td></tr>
        <tr><td>Out Of Order Pruned</td><td>{{.Eval .Alert.Vars.ofo_pruned | printf "%.2f"}}<td></tr>
        <tr><td>Receive Pruned</td><td>{{.Eval .Alert.Vars.rcv_pruned | printf "%.2f"}}<td></tr>
        <tr><td>Backlog Dropped</td><td>{{.Eval .Alert.Vars.backlog_drop | printf "%.2f"}}<td></tr>
        <tr><td>Syn Cookies Sent</td><td>{{.Eval .Alert.Vars.syncookies_sent | printf "%.2f"}}<td></tr>
        <tr><td>TOTAL Of Above</td><td>{{.Eval .Alert.Vars.total_err | printf "%.2f"}}<td></tr>
    </table>
    ``
    subject = ``{{.Last.Status}}: {{.Eval .Alert.Vars.total_err | printf "%.2f"}} tcp errors on {{.Group.host}} ``
}
```