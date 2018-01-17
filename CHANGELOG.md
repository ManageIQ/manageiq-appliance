# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)


## Unreleased as of Sprint 76 ending 2018-01-01

### Added
- Configure PostgreSQL ssl by default [(#162)](https://github.com/ManageIQ/manageiq-appliance/pull/162)

## Unreleased as of Sprint 75 ending 2017-12-11

### Added
- Restore the context of usr/bin for docker executable issues [(#160)](https://github.com/ManageIQ/manageiq-appliance/pull/160)

### Fixed
- Use a better command to add /usr/local/bin to the path [(#161)](https://github.com/ManageIQ/manageiq-appliance/pull/161)
- Add /usr/local/bin to the path if it is missing [(#159)](https://github.com/ManageIQ/manageiq-appliance/pull/159)

## Unreleased as of Sprint 74 ending 2017-11-27

### Fixed
- Use a login shell for the failover monitor service [(#155)](https://github.com/ManageIQ/manageiq-appliance/pull/155)
- mute cron mail when no error [(#152)](https://github.com/ManageIQ/manageiq-appliance/pull/152)
- Add trailing slash to cockpit machine urls [(#148)](https://github.com/ManageIQ/manageiq-appliance/pull/148)

## Unreleased as of Sprint 73 ending 2017-11-13

### Fixed
- ExecStart requires an absolute executable path [(#151)](https://github.com/ManageIQ/manageiq-appliance/pull/151)

## Gaprindashvili Beta1

### Added
- Add miqldap_to_sssd launcher [(#134)](https://github.com/ManageIQ/manageiq-appliance/pull/134)

### Changed
- Rename ws to api to not be confused with websockets [(#131)](https://github.com/ManageIQ/manageiq-appliance/pull/131)

### Fixed
- Platform
  - Add support for the domain user attribute [(#127)](https://github.com/ManageIQ/manageiq-appliance/pull/127)

## Fine-1

### Fixed
- Add the tower log files to our rotation script [(#120)](https://github.com/ManageIQ/manageiq-appliance/pull/120)
- Generate new certificate when the default one is not present [(#119)](https://github.com/ManageIQ/manageiq-appliance/pull/119)
