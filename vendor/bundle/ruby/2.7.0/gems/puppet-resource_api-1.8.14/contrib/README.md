# Git pre-commit hook
This directory contains the file `pre-commit`. When enabled the hook is called when you attempt to commit changes locally. The hook will run the bundled `rubocop` with auto correct function on files that you have changed.

* If rubocop is successful in correcting errors detected in the changed files it will stage the changes and proceed with the commit.
* If rubocop is unsuccessful in correcting errors detected in the changed files the commit will fail and the rubocop output will be displayed. Manual changes will need to be made before proceeding.

To enable the pre-commit hook, either create a symlink to this file or copy the file to `.git/hooks`
