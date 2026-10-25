#!/usr/bin/env bash
# Compatibility wrapper for the optional heavy-app install.
#
#   cd ~/nixos && ./post-install.sh
#
# This remains supported as an alias to the more explicit
# ./install-heavy-apps.sh script, which is easier to discover and documents
# that the large application set is optional.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$REPO_ROOT/install-heavy-apps.sh" "$@"
