# git2log

Tool to auto-create changelog entries from git commit logs.

## purpose

To avoid merge conflicts it is desirable not to maintain separate `VERSION`, `changelog` or `*.changes`
files within the git tree.

Also, maintaining the correct version number scheme can become quite tricky. So `git2log` supports
you here as well.

## basics

`git2log` expects the project to use tags of the form `VERSION` (for master) or `BRANCH-VERSION` for
other branches. `VERSION` is any sequence of decimal numbers and dots (`.`) (e.g. `8.2` or `4.315.77.3`).

A new version is released by setting an appropriate tag.

A git commit message consists of a single line (summary) followed by any number of detailed paragraphs.

The log will be created from git commit messages in this way:

Usually only the first line (the summary) is used. But to ease concerns that the git commit messages
are not suited for a changelog, you can tag paragraphs by starting them with `@log@` or `@+log@`.

These paragraphs are then added to the changelog.

The difference between them is that `@log@` will cause all summary lines of the commit (possibly
a merge commit as for pull requests) to be ignored. `@+log@` will just **add** the paragraph.

So, use `@log@` to rewite the changelog of a pull request, `@+log@` to add some additional log.
You can write several `@log@` and `@+log@` entries. All will be combined.

Log entries are reformatted (line breaks) to fit within a max line length. Also, version numbers
and github pull request references are auto-added.

As the changelog must maintain a monotonous time (build system requirement)
and at the same time must be identical on every run, `git2log` will use the time of
the merge commit for every commit belonging to the merge.

This way the submitted package can be made bitwise identical on every submission (as long as the code
didn't change) - something the build service team is really happy about.

`git2log --version` will report the current version you are working on. This is either `VERSION` from
the tag if `HEAD` is tagged or `VERSION+1` (auto-incremented suitably) if `HEAD` is untagged.

`git2log --branch` reports the branch you are working on. This is **not** necessarily the current git
branch name but `BRANCH` from the last `BRANCH-VERSION` or `VERSION` (master branch) tag found. This way you can
`git checkout -b WHATEVER` from a supported branch and not mess up versioning in your private devel branch.

`git2log --log --start STARTTAG` generates the log beginning at `STARTTAG` (excluding the entry for
`STARTTAG` itself). If `STARTTAG` is not found it generates the whole log.

## possible workflow

### normal use

- have `git2log --log --start VERSION_FROM_OLD_SPEC` generate the new obs log
- use `git2log --branch` and `git2log --version` to create the new tag name and set the tag
- submit to obs

### create new branch

- create new branch, e.g. `sle12`
- create new tag: e.g. to branch off at version `6.8` and add a third number component,
add tag `sle12-6.8.0` to the existing `6.8`
- after you submit something to the new branch, `git2log` will report `sle12-6.8.1` as new branch/version; etc.
- trick question:
    - So if HEAD is tagged both with `6.8` **and** `sle12-6.8.0` - which version will `git2log --version` report?
    - Answer: `6.8` if you are on branch `master`, `6.8.0` if you are on branch `sle12`. And after you submit some changes it will be `6.9` and `6.8.1` respectively.

