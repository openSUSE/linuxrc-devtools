# Linuxrc development tools


This is a collection of scripts used to connect [Github](http://github.com/)
via [Jenkins](http://jenkins-ci.org/) to the [Open Build
Service](https://build.opensuse.org/).

For these to work the git project must fulfill some requirements:

* there must be a `clean` or `distclean` make target that really cleans up
  everything
* there must be an `archive` target that creates a source tar file (details see
  below)

## Tools

### git2log

Generate a changelog file based on git commit messages.

If your commit message is split into a single line short comment and a
detailed description separated by an empty line, just the short comment is
used. Alternatively, precede each commit line with a dash '-' to get
multiple changelog entries.

Expects numerical tags matching version number, like 1.2.3. For branches !=
master, tags should be `<branch>-<version>`.

You can create test branches from any main branch (e.g. for pull requests,
with `git co -b`). _git2log_ recognizes those branches and treats them as
continuation of the main branch.

From _git2log's_ perspective a test branch is just a branch without tags in
it. But it should also have a name starting with either 'test' or 'bnc' as
_tobs_ expects this.

### tobs

Commit current git state to build service.

There must be a make target `archive` that **has created**:

* a `VERSION` file
* a `changelog` file
* a source archive `package/<name>-<version>.tar.xz`
* optionally other source files (that will be mentioned in `*.spec`) below `package/`

Ideally, repeated make runs should produce exactly the same archive file as
long as the git repo stays unchanged.

The script gets the current build service package, updates it with the new
sources, adjust the `*.spec` file to remove any old patches, updates the
`*.changes` file and commits the new package back to the build service (to the
same project). It will auto-add comments about removed patches and
removed/added source files.

If it does not yet exist it creates a new version number tag in the git
repo.

Note that you need a `$HOME/.oscrc` file with sufficient authentication info
to access the build service and to write to the git repo (to push the tag).

There is a `--try` option that does everything except actually submitting
the changes to the build service or setting the new tag. Use together with
`--save-temp` to debug things.

If you are on a branch with a name starting with either 'test' or 'bnc',
_tobs_ handles this as a test build. That is, the package is submitted to a
special test project (see 'test' entry in config file) and no submit
requests are created.

#### tobs --sr

If you use the `--sr` option it will create a build service submit request.
With `--wait-for-ok` it optionally waits until the package has been built
successfully in the originating project.

#### $HOME/.tobsrc

_tobs_ uses a config file to relate build service projects to git repos.

Note: section names are arbitrary and used only for logging. You can have
multiple sections with the same name. If several sections match (based on
package and branch names) the first match is used. So put more general
sections last.

Examples:

    [factory]
    branch=master
    prj=system:install:head
    test=home:xxx:factory
    sr=openSUSE:Factory
    bs=api.opensuse.org

If you are on branch master, look up a package with the same name as the
git project in the system:install:head build service project ('devel
project'). When creating a submit request, submit to openSUSE:Factory. Use
the opensuse.org build service.

Test builds are done in home:xxx:factory.

    [factory]
    package=perl-Bootloader
    gitname=perl-bootloader
    branch=master
    prj=Base:System
    sr=openSUSE:Factory
    bs=api.opensuse.org

Similar as above but git project name and build service package name
differ. Note that `make archive` must produce a name matching the build
service package, not the git repo name.

    [factory]
    package=installation-images
    branch=master
    prj=system:install:head
    sr=openSUSE:Factory/installation-images-openSUSE
    bs=api.opensuse.org

Similar to first example but build service package names differ in devel
project and target project (e.g. you have several `*.spec` files).

If the submit request should go to a different buildservice than the one
where the project was built, use the 'bs_sr' entry to specify the build
service for the sr and the prefix to access one bs from the other.

For example:

    [sle12]
    branch=master
    prj=system:install:head
    test=home:xxx:factory
    sr=SUSE:SLE-12:Update
    bs=api.opensuse.org
    bs_sr=api.foo.bar,openSUSE.org:

Sources are built in system:install:head on api.opensuse.org but the result
is submitted from openSUSE.org:system:install:head to SUSE:SLE-12:Update on
api.foo.bar.

### build_it

  Wrapper script for _tobs_ to be run by Jenkins.

  `tobs <branch>` checks out <branch>, runs `make archive`, and then `tobs`.


### submit_it

  Wrapper script for `tobs --sr` to be run by Jenkins.

  This assumes the Jenkins job name to be `<foo>-sr` and a previously
  finished Jenkins job `<foo>`. It changes to the `<foo>` workspace and runs
  `tobs --wait-for-ok --sr`.

## openSUSE development

### Workflow

At a first glance, Linuxrc (and related projects) follows the same approach as other YaST projects:
changes are tracked on Github and Jenkins CI will take care of submitting them to OBS. However,
tools used by these projects are different from the ones used for YaST.

Those tools are available in [linuxrc-devtools](http://github.com/openSUSE/linuxrc-devtools).
Next we'll introduce them (and how are they related to Jenkins) but it's recommended to check the
[documentation](https://github.com/openSUSE/linuxrc-devtools/blob/master/README.md)
in the repository.

When Jenkins detect changes on, for example,
[Linuxrc](http://github.com/openSUSE/linuxrc) Git repository, it will build the
project using [build_it
script](https://github.com/openSUSE/linuxrc-devtools/blob/master/build_it).
This script is just a wrapper that, after building the `make archive` target,
will invoke
[tobs](https://github.com/openSUSE/linuxrc-devtools/blob/master/tobs) which
will take care of submitting the new version to the development project on OBS.
Branches, projects, etc. to submit to are defined in `tobs` configuration. For
example, for _Factory_, `master` branch will be submitted to `system:install:head/linuxrc`.

If the previous step ran successfully, then a submit request to the final
project will be created through the [submit_it
script](https://github.com/openSUSE/linuxrc-devtools/blob/master/submit_it),
which is just another wrapper script that will rely on `tobs`. For example, for
_Factory_, the project will be submitted to `openSUSE:Factory/linuxrc`.

### linuxrc-devtools

The package is automatically submitted from the `master` branch to
[system:install:head](https://build.opensuse.org/package/show/system:install:head/linuxrc-devtools)
OBS project. From that place it is forwarded to
[openSUSE Factory](https://build.opensuse.org/project/show/openSUSE:Factory).
