# Release runbook

Multiples is local-only. `MultiplesSession` is a versioned Codable record. Missing, malformed, arithmetically inconsistent, or obsolete state falls back to the safe empty journey; round-trip, malformed-state, and restoration tests are the migration/failure coverage for this topology.

Before release:

1. Run `scripts/verify.sh` on a machine with a compatible iOS simulator runtime.
2. Set an organization-owned bundle identifier and development team; never commit certificates or provisioning profiles.
3. Increment the marketing/build versions, archive Release, analyze it, and validate the archive.
4. Supply owner-approved final App Store icons and capture screenshots for supported device sizes, portrait/landscape, and accessibility sizes. The existing catalog does not contain approved final icon binaries.
5. Test VoiceOver, Switch Control, Dynamic Type, rotation, interruption/restoration, clean install/upgrade, malformed state, and low storage on supported devices.
6. Confirm the privacy manifest and App Store privacy answers match the final binary, then obtain product/release approval.
