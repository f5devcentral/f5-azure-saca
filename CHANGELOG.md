# Changelog

All notable changes to this project will be documented in this file.

## 3.0.0

- converted everything to terraform, added all outstanding features.

## [2.6.1] - 2020-03-10

### Changed

- 3 Tier: Changed DeclarationURL to Tier 1 and Tier 3 Declaration URLs to allow seperate AS3 declarations for each tier.
- Adjusted outputs to proper PIP FQDN output
- Extensive Changes to Microsoft.Compute/virtualMachines/extensions commandToExecute to help optimize time and clean up order of operations.
- Updated BYOL template AS3 release, and moved everything to b64 scripts
- removed SACAv1 Deploy button
- added deploy buttons for payg and bigiq

### Added

- PAYG template options
- Tier 1 & 3 Module Parameters

## [2.5] - 2020-03-02

### Fixed

- Resolved issue with Accelerated Networking Logic

### Changed

- Rewrote and updated templates closer to F5 *supported* 7.0 templates.
- Restricted templates to 14.1.2 and 15.0.1

### Added

- Created several AS3 options; PAYG, BYOL, and Baseline.
- Added parameter to select module provisioning

## [2.2] - 2019-08-06

### Changed

- Made STIG a bool option in Parameters
- Changed image to 14.1.00300

## [2.1] - 2019-07-10

### Added

- AV Sets added to all VMs.
- Managed Disks on all VMs.
- Enabled HA Ports on ILB.
- Added UDR for Default Route from VDMS Subnet.

### Updated

- Updated Public IP(s) to Standard SKU.
- Updated ALB to Standard SKU.
- Updated ILB to Standard SKU.
- Updated verifyHash
- Updated

### Removed

- PUA Option removed due to SKU.

## [2.0.2] - 2019-03-13

### Added

- Preloaded DOD Root CA Bundle v5.5.
- Added PUA Option.

## [2.0.1] - 2019-03-13

### Added

- CHANGELOG created.

### Removed

- Unused variables.
