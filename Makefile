#
#
#
#
TOPDIR=$(shell pwd)

CONF?=default

include $(TOPDIR)/conf/$(CONF)

DESC?="$(CONF) - splunkforwarder-$(SPLUNK_UF_VERSION)-$(SPLUNK_UF_HASH)-Linux-x86_64 Installer"
DOWNLOAD_SCRIPT=$(TOPDIR)/bin/download_uf.sh
BUILDDIR=build/$(CONF)
DISTDIR=dist

DOWNLOADDIR=download/$(SPLUNK_UF_VERSION)-$(SPLUNK_UF_HASH)
UF_FILENAME=splunkforwarder-$(SPLUNK_UF_VERSION)-$(SPLUNK_UF_HASH)-Linux-x86_64.tgz
UF_ARCHIVE=$(DOWNLOADDIR)/$(UF_FILENAME)
UF_LINK=$(DOWNLOADDIR)/splunkforwarder.tgz

INSTALLER?=$(CONF)_uf_installer-$(SPLUNK_UF_VERSION)-$(SPLUNK_UF_HASH)-Linux-x86_64.sh
INSTALLER_SCRIPT=$(INSTALLER)
SCRIPT?=installme.sh

all:	distdir build download config copy installer
	
installer: $(INSTALLER_SCRIPT)
	
$(INSTALLER_SCRIPT): FORCE
	( cd $(BUILDDIR); \
	$(TOPDIR)/tools/makeself/makeself.sh \
		--notemp \
		--nox11 \
		--gzip \
		--follow \
		--export-conf \
		. \
		$(TOPDIR)/dist/$@ \
		$(DESC) \
		./installme.sh; \
	)

.PHONY: copy distdir

copy: $(BUILDDIR)/splunkforwarder.tgz

$(BUILDDIR)/splunkforwarder.tgz: $(UF_ARCHIVE)
	cp $(UF_ARCHIVE) $(BUILDDIR)/splunkforwarder.tgz

distdir:	$(DISTDIR)

$(DISTDIR):
	mkdir -p $@

build:	$(BUILDDIR)
	mkdir -p $@

$(BUILDDIR):
	mkdir -p $@

download: $(DOWNLOADDIR) $(UF_LINK)
		
$(DOWNLOADDIR):
	mkdir -p $@

$(UF_LINK): $(DOWNLOAD_SCRIPT)
	$(DOWNLOAD_SCRIPT) -V $(SPLUNK_UF_VERSION) -H $(SPLUNK_UF_HASH) -d $(DOWNLOADDIR)

$(DOWNLOAD_SCRIPT):

$(BUILDDIR)/installme.sh: FORCE
	sed -e 's!@@DS_URL@@!$(DS_URL)!' $(TOPDIR)/scripts/$(SCRIPT) > $@

config: $(BUILDDIR)/installme.sh

.PHONY: FORCE

FORCE:

.PHONY: clean realclean

help:
	@echo "Customer:	$(CONF)"
	@echo "Description: 	$(DESC)"
	@echo "DS URL:		$(DS_URL)"
	@echo "Installer:	$(INSTALLER)"
	@echo

realclean: clean
	rm -rf download build dist

clean:
	rm -rf $(BUILDDIR)
