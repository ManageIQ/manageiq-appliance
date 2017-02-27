#!/bin/env ruby
# description: ManageIQ watchdog application loop
#

require 'manageiq-gems-pending'
require 'util/system/evm_watchdog'

EvmWatchdog.kill_other_watchdogs # To prevent duplicates.
sleep(600) # 600s = 10 minute startup delay.
loop do
  EvmWatchdog.check_evm
  EvmWatchdog.check_for_update
  sleep(60) # 60s = 1 minute check frequency.
end
