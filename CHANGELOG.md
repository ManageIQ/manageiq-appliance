# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)


## Gaprindashvili Beta2

### Fixed
- mute cron mail when no error [(#152)](https://github.com/ManageIQ/manageiq-appliance/pull/152)
- Use a login shell for the failover monitor service [(#155)](https://github.com/ManageIQ/manageiq-appliance/pull/155)

## Gaprindashvili Beta1

### Added
- Add miqldap_to_sssd launcher [(#134)](https://github.com/ManageIQ/manageiq-appliance/pull/134)

### Changed
- Rename ws to api to not be confused with websockets [(#131)](https://github.com/ManageIQ/manageiq-appliance/pull/131)

### Fixed
- Add support for the domain user attribute [(#127)](https://github.com/ManageIQ/manageiq-appliance/pull/127)
- ExecStart requires an absolute executable path [(#151)](https://github.com/ManageIQ/manageiq-appliance/pull/151)

## Fine-1

### Fixed
- Add the tower log files to our rotation script [(#120)](https://github.com/ManageIQ/manageiq-appliance/pull/120)
- Generate new certificate when the default one is not present [(#119)](https://github.com/ManageIQ/manageiq-appliance/pull/119)
