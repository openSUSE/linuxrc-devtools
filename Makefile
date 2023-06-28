PACKAGE := linuxrc-devtools
SCRIPTS := build_it git2log git2tags submit_it tobs make_package

GIT2LOG := $(shell if [ -x ./git2log ] ; then echo ./git2log --update ; else echo true ; fi)
GITDEPS := $(shell [ -d .git ] && echo .git/HEAD .git/refs/heads .git/refs/tags)
VERSION := $(shell $(GIT2LOG) --version VERSION ; cat VERSION)
BRANCH  := $(shell [ -d .git ] && git branch | perl -ne 'print $$_ if s/^\*\s*//')
PREFIX  := $(PACKAGE)-$(VERSION)

.EXPORT_ALL_VARIABLES:
.PHONY:	all clean install archive

%.o:	%.c
	$(CC) $(CFLAGS) -o $@ $<

all: changelog

changelog: $(GITDEPS)
	$(GIT2LOG) --changelog changelog

install:
	install -m 755 -d $(DESTDIR)/usr/bin
	install -m 755 -t $(DESTDIR)/usr/bin $(SCRIPTS)
	@cp tobs tobs.tmp
	@perl -pi -e 's/0\.0/$(VERSION)/ if /VERSION = /' tobs.tmp
	install -m 755 -D tobs.tmp $(DESTDIR)/usr/bin/tobs
	@rm -f tobs.tmp

archive: changelog
	@if [ ! -d .git ] ; then echo no git repo ; false ; fi
	mkdir -p package
	git archive --prefix=$(PREFIX)/ $(BRANCH) > package/$(PREFIX).tar
	tar -r -f package/$(PREFIX).tar --mode=0664 --owner=root --group=root --mtime="`git show -s --format=%ci`" --transform='s:^:$(PREFIX)/:' VERSION changelog
	xz -f package/$(PREFIX).tar

clean:
	@rm -rf *~ package
