---
layout: page
title: Home
order: 1
---

<div class="row">
	<div class="col-md-offset-1 col-md-10">
		<div class="jumbotron">
			<h1>Bosun</h1>
			<p>An advanced, open-source monitoring and alerting system by <a href="http://stackexchange.com">Stack Exchange</a></p>
			<p><a class="btn btn-primary btn-lg" href="{{site.github.url}}/gettingstarted.html">Get Started</a></p>
		</div>
	</div>
</div>
<div class="row">
	<div class="col-md-offset-1 col-md-10">
		<div class="panel panel-default">
			<div class="panel-heading"><h3>Features</h3></div>
			<div class="panel-body">
				<ul>
					<li>An expression language for evaluating time series data. You can now create highly flexible alerts and control noise</li>
					<li>Templates for notifications that allow making alerts as detailed and informative as needed</li>
					<li>An interface for testing alerts and templates to see if alerts would have triggered over a range of history before deploying the changes</li>
					<li>High resolution metrics that never need to be rolled up that are stored in <a href="http://opentsdb.net/">OpenTSDB</a></li>
					<li>Is bundled with a metric collector called <a href="http://bosun.org/scollector/">scollector</a> that treats both Linux and Windows as first-class systems and can also poll SNMP devices such as Cisco; running this collector provides you with a rich library of metrics from day 1</li>
					<li>Runs on any operating system which supports <a href="http://golang.org/">Go</a> (Windows and Linux supported)</li>
					<li>Auto-detects new services and starts sending metrics immediately; properly designed alerts will also apply to these new services and allow for minimal maintenance on the side of the operator</li>
					<li>Easily ingests metrics from services with a simple JSON API so you can easily get application-layer and business metrics into the system</li>
					<li>Aggregation support so your monitoring need not be purely host-based (and you don't need to worry about aggregating metrics from multiple servers yourself)</li>
				</ul>
			</div>
		</div>
	</div>
</div>
<div class="row hidden-sm hidden-xs">
	<div class="col-md-offset-1 col-md-10">
		<p>
		<h2>Screenshot</h2>
		<a href="{{site.github.url}}/public/ss_rule_timeline.png">
			<img class="col-sm-12" src="{{site.github.url}}/public/ss_rule_timeline.png">
		</a>
		</p>
	</div>
</div>
<div class="row">
	<div class="col-md-offset-1 col-md-10">
		<h2>Installation</h2>
		<ul>
			<li><a href="https://github.com/bosun-monitor/bosun/releases/download/{{site.version.id}}/bosun-linux-amd64"><strong>Linux</strong> amd64</a></li>
			<li><a href="https://github.com/bosun-monitor/bosun/releases/download/{{site.version.id}}/bosun-windows-amd64.exe"><strong>Windows</strong> amd64</a></li>
			<li><a href="https://github.com/bosun-monitor/bosun/releases/download/{{site.version.id}}/bosun-darwin-amd64"><strong>Mac</strong> amd64</a></li>
		</ul>

		<h3>From Source</h3>
		<code>$ go get github.com/bosun-monitor/bosun</code>
		<p>(All web assets are already bundled.)</p>
	</div>
</div>
<div class="row">
	<div class="col-md-offset-1 col-md-10">
		<h2>Alpha</h2>
		<p>Bosun is in alpha. It has bugs and its functionality will change. We will maintain an errata page detailing breaking changes going forward. Be aware of these problems if you plan to use it for production work.</p>
		<p>However, Bosun is already useful to us, and we are relying on it more and more at Stack Exchange. We want Bosun to be a general monitoring solution, and therefore we are depending on the creativity and experience of our users to influence its design. This means we will make changes that may break existing configuration.</p>
	</div>
</div>