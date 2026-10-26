# Test dependency

`addons/gut` is vendored, unmodified GUT **9.7.1**, the upstream release for Godot 4.7.x.

- Source: https://github.com/bitwes/Gut/releases/tag/v9.7.1
- Archive: https://github.com/bitwes/Gut/archive/refs/tags/v9.7.1.zip
- Copied directory: `Gut-9.7.1/addons/gut`
- License: `addons/gut/LICENSE.md` (MIT)
- Documentation: https://gut.readthedocs.io/en/v9.7.1/

Tests run offline from a checkout. To upgrade, replace the vendored addon with an explicitly selected compatible upstream release, update this record, and run `mise run test`. Do not modify framework internals to accommodate game tests.
