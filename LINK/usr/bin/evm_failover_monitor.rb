#!/bin/env ruby

require_relative '/var/www/miq/vmdb/gems/pending/bundler_setup'
require 'postgres_ha_admin/failover_monitor'

monitor = PostgresHaAdmin::FailoverMonitor.new
monitor.monitor_loop
