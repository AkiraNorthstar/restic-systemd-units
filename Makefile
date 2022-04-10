
prefix=/usr
bindir=$(prefix)/bin
libdir=$(prefix)/lib
sysconfdir=/etc
unitdir=$(libdir)/systemd/system
localstatedir=/var
cachedir=$(localstatedir)/cache/restic

RESTIC_BIN    = restic
RESTIC_USER   = restic
RESTIC_GROUP  = restic
RESTIC_BACKUP = $(bindir)/restic-backup
BINSCRIPTS    = restic-backup restic-helper
INSTALL       = install

SERVICES = \
	restic-backup@.service \
	restic-check@.service \
	restic-forget@.service \
	restic-prune@.service \
	restic-unlock@.service

TIMERS = \
	restic-backup-hourly@.timer \
	restic-backup-daily@.timer \
	restic-backup-weekly@.timer \
	restic-backup-monthly@.timer \
	restic-check-hourly@.timer \
	restic-check-daily@.timer \
	restic-check-weekly@.timer \
	restic-check-monthly@.timer \
	restic-forget-hourly@.timer \
	restic-forget-daily@.timer \
	restic-forget-weekly@.timer \
	restic-forget-monthly@.timer \
	restic-prune-hourly@.timer \
	restic-prune-daily@.timer \
	restic-prune-weekly@.timer \
	restic-prune-monthly@.timer

all: $(TIMERS) $(SERVICES) $(BINSCRIPTS)

### BINSCRIPTS
restic-backup: restic-backup.in
	@echo generating $@
	@sed "s~@RESTIC_BIN@~$(bindir)/$(RESTIC_BIN)~g;s~@RESTIC_CACHE_DIR@~$(cachedir)~g" $< > $@ || rm -f $@

restic-helper: restic-helper.in
	@echo generating $@
	@sed "s~@RESTIC_BIN@~$(bindir)/$(RESTIC_BIN)~g;s~@RESTIC_CACHE_DIR@~$(cachedir)~g" $< > $@ || rm -f $@

restic-tmpfiles.conf: restic-tmpfiles.conf.in
	@echo generating $@
	@sed "s~@RESTIC_USER@~$(RESTIC_USER)~g;s~@RESTIC_GROUP@~$(RESTIC_GROUP)~g;s~@RESTIC_CACHE_DIR@~$(cachedir)~g" $< > $@ || rm -f $@

restic-sysusers.conf: restic-sysusers.conf.in
	@echo generating $@
	@sed "s~@RESTIC_USER@~$(RESTIC_USER)~g;s~@RESTIC_GROUP@~$(RESTIC_GROUP)~g;s~@RESTIC_CACHE_DIR@~$(cachedir)~g" $< > $@ || rm -f $@

### SERVICES
restic-backup@.service: restic-backup@.service.in
	@echo generating $@
	@sed "s~@RESTIC_USER@~$(RESTIC_USER)~g;s~@RESTIC_CACHE_DIR@~$(cachedir)~g;s~@RESTIC_BACKUP@~$(RESTIC_BACKUP)~g" $< > $@ || rm -f $@

restic-check@.service: restic-check@.service.in
	@echo generating $@
	@sed "s~@RESTIC_USER@~$(RESTIC_USER)~g;s~@RESTIC_CACHE_DIR@~$(cachedir)~g;s~@RESTIC_BACKUP@~$(RESTIC_BACKUP)~g" $< > $@ || rm -f $@

restic-forget@.service: restic-forget@.service.in
	@echo generating $@
	@sed "s~@RESTIC_USER@~$(RESTIC_USER)~g;s~@RESTIC_CACHE_DIR@~$(cachedir)~g;s~@RESTIC_BACKUP@~$(RESTIC_BACKUP)~g" $< > $@ || rm -f $@

restic-prune@.service: restic-prune@.service.in
	@echo generating $@
	@sed "s~@RESTIC_USER@~$(RESTIC_USER)~g;s~@RESTIC_CACHE_DIR@~$(cachedir)~g;s~@RESTIC_BACKUP@~$(RESTIC_BACKUP)~g" $< > $@ || rm -f $@

restic-unlock@.service: restic-unlock@.service.in
	@echo generating $@
	@sed "s~@RESTIC_USER@~$(RESTIC_USER)~g;s~@RESTIC_CACHE_DIR@~$(cachedir)~g;s~@RESTIC_BACKUP@~$(RESTIC_BACKUP)~g" $< > $@ || rm -f $@

### TIMER
restic-backup-%@.timer: restic-backup-schedule.timer
	@echo generating $@
	@schedule=$(shell echo $@ | cut -f1 -d@ | cut -f3 -d-); \
		sed "s/@schedule@/$$schedule/g" $< > $@ || rm -f $@

restic-check-%@.timer: restic-check-schedule.timer
	@echo generating $@
	@schedule=$(shell echo $@ | cut -f1 -d@ | cut -f3 -d-); \
		sed "s/@schedule@/$$schedule/g" $< > $@ || rm -f $@

restic-forget-%@.timer: restic-forget-schedule.timer
	@echo generating $@
	@schedule=$(shell echo $@ | cut -f1 -d@ | cut -f3 -d-); \
		sed "s/@schedule@/$$schedule/g" $< > $@ || rm -f $@

restic-prune-%@.timer: restic-prune-schedule.timer
	@echo generating $@
	@schedule=$(shell echo $@ | cut -f1 -d@ | cut -f3 -d-); \
		sed "s/@schedule@/$$schedule/g" $< > $@ || rm -f $@

### INSTALL
install: restic-backup restic-helper restic-tmpfiles.conf restic-sysusers.conf $(BINSCRIPTS) $(TIMERS) $(SERVICES)
	$(INSTALL) -d -m 755 $(DESTDIR)$(sysconfdir)/restic
	$(INSTALL) -m 644 restic-template.conf $(DESTDIR)$(sysconfdir)/restic/restic.tmpl
	$(INSTALL) -d -m 755 $(DESTDIR)$(bindir)
	for SCRIPTS in $(BINSCRIPTS); do \
		$(INSTALL) -m 755 $$SCRIPTS $(DESTDIR)$(bindir); \
	done
	$(INSTALL) -m 755 -d $(DESTDIR)$(libdir)/sysusers.d
	$(INSTALL) -m 644 restic-sysusers.conf $(DESTDIR)$(libdir)/sysusers.d/restic.conf
	$(INSTALL) -m 755 -d $(DESTDIR)$(libdir)/tmpfiles.d
	$(INSTALL) -m 644 restic-tmpfiles.conf $(DESTDIR)$(libdir)/tmpfiles.d/restic.conf
	$(INSTALL) -m 755 -d $(DESTDIR)$(unitdir)
	for unit in $(TIMERS) $(SERVICES) ; do \
		$(INSTALL) -m 644 $$unit $(DESTDIR)$(unitdir) ; \
	done

clean:
	rm -f $(BINSCRIPTS)
	rm -f $(SERVICES)
	rm -f $(TIMERS)
