# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)


## Gaprindashvili-3

### Fixed
- Use version 2 of appliance console [(#183)](https://github.com/ManageIQ/manageiq-appliance/pull/183)
- httpd reload is not needed with copytruncate [(#185)](https://github.com/ManageIQ/manageiq-appliance/pull/185)

### Removed
- Remove reindex and vacuum scripts [(#180)](https://github.com/ManageIQ/manageiq-appliance/pull/180)

## Gaprindashvili-2 - Released 2018-03-07

### Fixed
- Allow local replication connections [(#178)](https://github.com/ManageIQ/manageiq-appliance/pull/178)

## Gaprindashvili-1 - Released 2018-02-01

### Added
- Configure PostgreSQL ssl by default [(#162)](https://github.com/ManageIQ/manageiq-appliance/pull/162)
- Restore the context of usr/bin for docker executable issues [(#160)](https://github.com/ManageIQ/manageiq-appliance/pull/160)
- Add miqldap_to_sssd launcher [(#134)](https://github.com/ManageIQ/manageiq-appliance/pull/134)

### Changed
- Rename ws to api to not be confused with websockets [(#131)](https://github.com/ManageIQ/manageiq-appliance/pull/131)

### Fixed
- Add /usr/local/bin to the path if it is missing [(#159)](https://github.com/ManageIQ/manageiq-appliance/pull/159)
- Use a better command to add /usr/local/bin to the path [(#161)](https://github.com/ManageIQ/manageiq-appliance/pull/161)
- Increase applinace_console version in manageiq-appliance-dependencies.rb to 1.1 [(#163)](https://github.com/ManageIQ/manageiq-appliance/pull/163)
- mute cron mail when no error [(#152)](https://github.com/ManageIQ/manageiq-appliance/pull/152)
- Use a login shell for the failover monitor service [(#155)](https://github.com/ManageIQ/manageiq-appliance/pull/155)
- Add support for the domain user attribute [(#127)](https://github.com/ManageIQ/manageiq-appliance/pull/127)
- ExecStart requires an absolute executable path [(#151)](https://github.com/ManageIQ/manageiq-appliance/pull/151)

## Fine-1

### Fixed
- Add the tower log files to our rotation script [(#120)](https://github.com/ManageIQ/manageiq-appliance/pull/120)
- Generate new certificate when the default one is not present [(#119)](https://github.com/ManageIQ/manageiq-appliance/pull/119)
