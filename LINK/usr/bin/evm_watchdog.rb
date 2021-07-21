#!/usr/bin/env ruby
# description: ManageIQ watchdog application loop
#

require 'bundler'
Bundler.setup

require_relative '../../../lib/evm_watchdog'

EvmWatchdog.kill_other_watchdogs # To prevent duplicates.
sleep(600) # 600s = 10 minute startup delay.
loop do
  EvmWatchdog.check_evm
  sleep(60) # 60s = 1 minute check frequency.
end
