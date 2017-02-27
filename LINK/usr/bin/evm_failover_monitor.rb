#!/bin/env ruby

require 'manageiq-gems-pending'
require 'postgres_ha_admin/failover_monitor'

monitor = PostgresHaAdmin::FailoverMonitor.new
monitor.monitor_loop
