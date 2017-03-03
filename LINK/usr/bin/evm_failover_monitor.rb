#!/bin/env ruby

require 'bundler'
Bundler.setup

require 'manageiq-gems-pending'
require 'postgres_ha_admin/failover_monitor'

monitor = PostgresHaAdmin::FailoverMonitor.new
monitor.monitor_loop
