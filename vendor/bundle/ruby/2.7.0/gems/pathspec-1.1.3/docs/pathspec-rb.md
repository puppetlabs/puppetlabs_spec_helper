# pathspec-rb(1)

{:data-date="2020/01/04"}

## NAME

pathspec - Test pathspecs against a specific path

## SYNOPSIS

`pathspec-rb` [`OPTIONS`] [`SUBCOMMAND`] [`PATH`] NAME PATH

## DESCRIPTION

`pathspc-rb` is a tool that accompanies the pathspec-ruby library to help
you test what match results the library would find using path specs. You can
either find all specs matching a path, find all files matching specs, or
verify that a path would match any spec.

https://github.com/highb/pathspec-ruby

## SUB-COMMANDS

|-
| Name | Description
|-
| *specs_match* | Find all specs matching path
|-
| *tree* | Find all files under path matching the spec
|-
| *match* | Check if the path matches any spec
|-

## OPTIONS

`-f <FILENAME>`, `--file <FILENAME>`
: Load path specs from the file passed in as argument. If this option is not specified, `pathspec-rb` defaults to loading `.gitignore`.

`-t [git|regex]`, `--type [git|regex]`
: Type of spec expected in the loaded specs file (see `-f` option). Defaults to `git`.

`-v`, `--verbose`
: Only output if there are matches.

## EXAMPLE

Find all files ignored by git under your source directory:

      $ pathspec-rb tree src/

List all spec rules that would match for the specified path:

      $ pathspec-rb specs_match build/

Check that a path matches at least one of the specs in a new version of a
gitignore file:

      $ pathspec-rb match -f .gitignore.new spec/fixtures/

## AUTHOR

Brandon High highb@users.noreply.github.com

Gabriel Filion
