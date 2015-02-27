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
			<p><a class="btn btn-primary btn-lg" href="/quickstart.html">Quick Start</a></p>
		</div>
	</div>
</div>
<div class="row">
	<div class="col-md-offset-1 col-md-10">
		<div class="panel panel-default">
			<div class="panel-heading"><h3>Features</h3></div>
			<div class="panel-body">
				<h4>General</h4>
				<ul>
					<li>An expression language for evaluating time series data. You can now create highly flexible alerts and control noise</li>
					<li>Templates for notifications that allow making alerts as detailed and informative as needed</li>
					<li>An interface for testing alerts and templates to see if alerts would have triggered over a range of history before deploying the changes</li>
					<li>First-class tags support.  Supports arbitrary dimensions (not just host based), aggregations and automatically incorporating new tags (hosts, services, ..) as they appear.</li>
					<li>Supports querying <a href="http://opentsdb.net/">OpenTSDB</a>, <a href="http://graphite.readthedocs.or">Graphite</a> and <a href="http://www.elasticsearch.org/overview/logstash/">Logstash-Elasticsearch</a>.  More to come.</li>
					<li>Runs on any operating system that <a href="http://golang.org/">Go</a> supports, such as Linux or Windows</li>
				</ul>
				<h4>OpenTSDB specific</h4>
				<ul>
					<li>Suports taking in arbitrary application or business metrics via a simple JSON API and proxying into OpenTSDB</li>
					<li>Is bundled with <a href="http://bosun.org/scollector/">scollector</a>, a metrics collector that treats both Linux and Windows as first-class systems and can also poll SNMP devices such as Cisco; running this collector provides you with a rich library of metrics from day 1</li>
					<li>Auto-detects new services and starts sending metrics immediately; properly designed alerts will also apply to these new services and allow for minimal maintenance on the side of the operator</li>
				</ul>
			</div>
		</div>
	</div>
</div>
<div class="row hidden-sm hidden-xs">
	<div class="col-md-offset-1 col-md-10">
		<p>
		<h2>Screenshot</h2>
		<a href="/public/ss_rule_timeline.png">
			<img class="col-sm-12" src="/public/ss_rule_timeline.png">
		</a>
		</p>
	</div>
</div>
<div class="row">
	<div class="col-md-offset-1 col-md-10">
		<h2>Support &amp; Development</h2>
		<p>We have a slack chat room: <a href="https://bosun.slack.com">https://bosun.slack.com</a>. Unfortunately it's invitation only but tweet at <a href="https://twitter.com/Dieter_be">Dieter_be</a> and/or <a href="https://twitter.com/kylembrandt">kylembrandt</a> to get an invite, or email us or open a ticket.
		<p>You can open <a href="https://github.com/bosun-monitor/bosun/issues">issues on GitHub</a> to report bugs or discuss new features.</p>
		<p>We encourage and foster collaboration.  We are depending on the creativity and experience of our users to influence its design.  Let's make Bosun better, together!</p>
	</div>
</div>
<div class="row">
	<div class="col-md-offset-1 col-md-10">
		<h2 id="installation">Installation</h2>
		<p>Binaries are provided below. All web assets are already bundled. Source instructions provided for developers.</p>
		<ul>
			<li><a href="https://github.com/bosun-monitor/bosun/releases/download/{{site.version.id}}/bosun-linux-amd64"><strong>Linux</strong> amd64</a></li>
			<li><a href="https://github.com/bosun-monitor/bosun/releases/download/{{site.version.id}}/bosun-linux-386"><strong>Linux</strong> 386</a></li>
			<li><a href="https://github.com/bosun-monitor/bosun/releases/download/{{site.version.id}}/bosun-windows-amd64.exe"><strong>Windows</strong> amd64</a></li>
			<li><a href="https://github.com/bosun-monitor/bosun/releases/download/{{site.version.id}}/bosun-windows-386.exe"><strong>Windows</strong> 386</a></li>
			<li><a href="https://github.com/bosun-monitor/bosun/releases/download/{{site.version.id}}/bosun-darwin-amd64"><strong>Mac</strong> amd64</a></li>
			<li><a href="https://github.com/bosun-monitor/bosun/releases/download/{{site.version.id}}/bosun-darwin-386"><strong>Mac</strong> 386</a></li>
		</ul>

		<h4>From Source</h4>
		<code>$ go get bosun.org/cmd/bosun</code>
	</div>
</div>
<div class="row">
	<div class="col-md-offset-1 col-md-10">
		<h2>Status</h2>
		<p>Bosun is in active development.  Functionality is constantly being improved.</p>
        <p>Bosun is used for production monitoring at:
            <br/>
            <img src="/public/stackexchange-logo.png" width="200px">
            <img src="/public/vimeo-logo.png" width="130px">
        </p>
	</div>
</div>
