#!/bin/sh
#
# After a PR merge, Chef Expeditor bumps the PATCH version in the VERSION file.
# It then executes this script to update any other files/components with that
# new version. chef-winrm-fs reads its version directly from the VERSION file
# (see chef-winrm-fs.gemspec), so there are no additional files to patch today,
# but this script is kept as the hook point for any future version references.
#

set -evx

# Once Expeditor finishes executing this script, it will commit the changes and push
# the commit as a new tag corresponding to the value in the VERSION file.
