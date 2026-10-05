# WinRM-fs Gem Changelog

<!-- latest_release 1.4.4 -->
## [v1.4.4](https://github.com/chef/chef-winrm-fs/tree/v1.4.4) (2026-10-05)

#### Merged Pull Requests
- Backfill CHANGELOG.md with missing pre-Expeditor pull requests [#34](https://github.com/chef/chef-winrm-fs/pull/34) ([neha-p6](https://github.com/neha-p6))
<!-- latest_release -->

<!-- release_rollup since=1.4.2 -->
### Changes not yet released to rubygems.org

#### Merged Pull Requests
- Backfill CHANGELOG.md with missing pre-Expeditor pull requests [#34](https://github.com/chef/chef-winrm-fs/pull/34) ([neha-p6](https://github.com/neha-p6)) <!-- 1.4.4 -->
- Re-enable Expeditor gem build/publish now that rubygems@chef.io owns chef-winrm-fs [#31](https://github.com/chef/chef-winrm-fs/pull/31) ([neha-p6](https://github.com/neha-p6)) <!-- 1.4.3 -->
- Fix Expeditor verify pipeline Windows Docker image [#32](https://github.com/chef/chef-winrm-fs/pull/32) ([neha-p6](https://github.com/neha-p6)) <!-- 1.4.3 -->
- Add Chef Expeditor version bump, labeling, and gem release [#27](https://github.com/chef/chef-winrm-fs/pull/27) ([tpowell-progress](https://github.com/tpowell-progress)) <!-- 1.4.3 -->
<!-- release_rollup -->

## 1.4.2
_Backfilled: VERSION was bumped manually (outside Expeditor) across these merges before Expeditor automation was added in #27._

#### Merged Pull Requests
- Restore VERSION to 1.4.2 and require rubyzip >= 3.4 [#28](https://github.com/chef/chef-winrm-fs/pull/28) ([jmtx1020](https://github.com/jmtx1020))
- Bump version to 1.4.0 [#26](https://github.com/chef/chef-winrm-fs/pull/26) ([tpowell-progress](https://github.com/tpowell-progress))
- CHEF-29608 Update and standardize copyright notices to Progress Software Corporation - copyright_update [#16](https://github.com/chef/chef-winrm-fs/pull/16) ([clintoncwolfe](https://github.com/clintoncwolfe))
- CHEF-27269 - Create CONTRIBUTING.md file with standard template for Chef [#12](https://github.com/chef/chef-winrm-fs/pull/12) ([nandanhegde73](https://github.com/nandanhegde73))
- Compile each PS1 template once instead of on every render [#21](https://github.com/chef/chef-winrm-fs/pull/21) ([tas50](https://github.com/tas50))
- Remove the dead AppVeyor CI configuration [#23](https://github.com/chef/chef-winrm-fs/pull/23) ([tas50](https://github.com/tas50))
- Revive the FileTransporter unit tests [#24](https://github.com/chef/chef-winrm-fs/pull/24) ([tas50](https://github.com/tas50))
- Decode download chunks without the redundant scrub and copy [#20](https://github.com/chef/chef-winrm-fs/pull/20) ([tas50](https://github.com/tas50))
- Reuse one PowerShell shell for the duration of a download [#19](https://github.com/chef/chef-winrm-fs/pull/19) ([tas50](https://github.com/tas50))
- Require rubyzip 3.0 [#25](https://github.com/chef/chef-winrm-fs/pull/25) ([tas50](https://github.com/tas50))
- Defer rubyzip/CSV loading and drop the unused logger require [#17](https://github.com/chef/chef-winrm-fs/pull/17) ([tas50](https://github.com/tas50))
- CHEF-27271 - Create CODE_OF_CONDUCT.md file [#11](https://github.com/chef/chef-winrm-fs/pull/11) ([Saburesh07](https://github.com/Saburesh07))
- CHEF-28527 - Create SECURITY.md file with standard template [#15](https://github.com/chef/chef-winrm-fs/pull/15) ([cgunasree08](https://github.com/cgunasree08))
- set up ai assisted development workflow [#10](https://github.com/chef/chef-winrm-fs/pull/10) ([rishichawda](https://github.com/rishichawda))
- Forgot to update the version [#14](https://github.com/chef/chef-winrm-fs/pull/14) ([johnmccrae](https://github.com/johnmccrae))
- Updating Benchmark and Cookstyle [#13](https://github.com/chef/chef-winrm-fs/pull/13) ([johnmccrae](https://github.com/johnmccrae))
- Updating version for a release [#9](https://github.com/chef/chef-winrm-fs/pull/9) ([johnmccrae](https://github.com/johnmccrae))
- CHEF-24143 switch off verbosity [#8](https://github.com/chef/chef-winrm-fs/pull/8) ([sathish-progress](https://github.com/sathish-progress))

<!-- latest_stable_release -->
# 1.3.5
- Optimize requires
- Ensure connections are closed
- Include dot files
<!-- latest_stable_release -->

# 1.3.4
- Bump rubyzip dependency

# 1.3.3
- Replace erubis with erubi

# 1.3.2
- Limit the files that are shipped in the gem artifact

# 1.3.1
- Download files in chunks

# 1.3.0
- Upload from StringIO object
- Add missing winrm/exceptions require in file_transporter
- Use correct way to relativize paths of Zip entries

# 1.2.1
- Correctly handle unicode filenames

# 1.2.0
- Add ability to download directories

# 1.1.1
- Remove empty items from powershell pipeline when extracting zip files

# 1.1.0
- Convert MD5 hashes to SHA1.

# 1.0.2
- Fix `Pathname.glob` expansion of shortnames.

# 1.0.1
- Call ClearScriptBlockCache to prevent OutOfMemoryExceptions ClearScriptBlockCache

# 1.0.0
- Using winrm v2. File uploads just got a whole lot faster!

# 0.4.3
- Fix error handling with wmf5, filtering out progress output from inspected stderr.

# 0.4.2
- Improved Powershell error handling in metadata checking.

# 0.4.1
- Fixes a regression on Windows 2008 R2/Windows 7 and below where the WinRM service corrupts the check files metadata resulting in malformed destination paths.

# 0.4.0
- Correct the destination path of individual files. Always assume it is the full destination path unless it is an existing directory. This may potentialy break some callers expecting the remote path to be a directory that winrm-fs will create if missing as the destination of the local file. A new directory will not be created and the local file will be uploaded directly to the remote path.

# 0.3.2
- Fix re-extraction of cached directories from temp folder when there is more than one "clean" directory deleted from destination

# 0.3.1
- Widen logging version constraints to include 2.0 (matching WinRM core gem)

# 0.3.0
- Jetisons `CommandExecutor` now living in the core WinRM gem and swaps in implementation currently used in the winrm-transport gem. These changes should have little visible effect on current consumers of the `FileManager` class with these exceptions:
  - BREAKING CHANGE: When uploading a directory and the destination directory exists on the endpoint, the source base directory will be created below the destination directory on the endpoint and the source directory contents will be unzipped to that location. Prior to this release, the contents of the source directory would be unzipped to an existing destination directory without creating the source base directory. This new behavior is more consistent with SCP and other well known shell copy commands.
  - `Upload` may now receive an array of source files and directories rather than just a single file or directory path.

# 0.2.4
- Fix issue 21, downloading files is extremely slow.
- Add zip file creation debug logging.

# 0.2.3
- Fix yielding progress data, issue #23

# 0.2.2
- Fix powershell streams leaking to standard error breaking Windows 10, issue #18

# 0.2.1
- Fixed issue 16 creating zip file on Windows

# 0.2.0
- Redesigned temp zip file creation system
- Fixed lots of small edge case issues especially with directory uploads
- Simplified file manager upload method API to take only a single source file or directory
- Expanded acceptable username and hostnames for rwinrmcp

# 0.1.0
- Initial alpha quality release