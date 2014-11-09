---
layout: page
title: General Documentation
order: 5
---

{% raw %}

* auto-gen TOC:
{:toc}

#Architecture 
The main components are:

 * **scollector**: An agent that provides data collection
   * A binary that gathers Linux and Windows data locally from the system (no external libraries needed) 
   * Has built-in collectors
   * Can data poll via network devices via SNMP and VSphere
   * Can run external scripts
   * Queues data when Bosun can't be reached
 * **bosun**: Data collection and relaying, Alerting, and Graphing 
   * Has an expression language for creating alerts from times series queried from OpenTSDB
   * Exposes the Go template language for users to craft alert notifications with
   * Has notification escalation
   * Relays data to OpenTSDB
   * Collects Metadata: (String information about things like hosts (i.e. IP Address, Serial Numbers)) and information about metrics: Description, Gauge vs Counter, and the metrics's measurement unit. Currently stored locally on the server as a state file
   * Text Configuration that can be version controlled: support macros, lookup tables, alert configuration, notifications, and notification templates 
   * Web Interface: 
     * Has an alert dashboard: Currently Triggered Alerts, Acknowledgments etc. Can also view alert history
     * Has a Graphing interface
     * Has a page for running expressions
     * Has a page for silencing alerts 
     * Has a page for testing alerts over history and previewing notifications
     * Host views for basic host information such as CPU, Memory, Network throughput, and Disk Space
     * Page to validate configuration

##Diagram
![Architecture Diagram](public/arch.png)

{% endraw %}