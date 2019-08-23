#
#
#
#
CONF?=default

include conf/$(CONF)

#SPLUNK_UF_VERSION="7.3.1"
#SPLUNK_UF_HASH="bd63e13aa157"
#DESC="Zoom Splunk Linux UF Installer"
#INSTALLER=uf_install.sh
#DS_URL=https://deployment-server-for-uf-lb-6a9a73a6a59745f8.elb.us-east-1.amazonaws.com:8089

all: installme download build
	./tools/makeself/makeself.sh \
		--notemp \
		--nox11 \
		--gzip \
		--follow \
		dist \
		build/$(INSTALLER) \
		$(DESC) \
		./dist/$(CONF)_installme.sh


dist/splunkforwarder.tgz:
	./bin/download_uf.sh $(SPLUNK_UF_VERSION) $(SPLUNK_UF_HASH)

.PHONY: download

download: dist/splunkforwarder.tgz

dist/$(CONF)_installme.sh: FORCE
	sed -e 's!@@DS_URL@@!$(DS_URL)!' ./script/installme.sh > ./dist/$(CONF)_installme.sh

.PHONY: FORCE

FORCE:

.PHONY: installme

installme: dist dist/$(CONF)_installme.sh

build:
	mkdir build

dist:
	mkdir dist

.PHONY: clean realclean

realclean: clean
	rm -rf ./dist ./build

clean:
	rm -f build/$(INSTALLER) dist/$(CONF)_installme.sh
