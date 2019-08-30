# splunk-uf-installer
A Simple Splunk UF Installer

# Usage

## checkout the code.
You know what to do here. _dont forget to issue "git submodule update"_
## Create a config file
copy conf/default into something else. i.e. conf/blah
```
    cp conf/default conf/blah
 ```
## Edit conf/blah
```
  SPLUNK_UF_VERSION=7.3.1
  SPLUNK_UF_HASH=bd63e13aa157
  DESC="Splunk Linux UF Installer"
  DS_URL=https://127.0.0.1:8089
  INSTALLER=splunk_linux_installer-$(SPLUNK_UF_VERSION)-$(SPLUNK_UF_HASH).sh
```
## Run make
```
make -e CONF=blah
```
You should see out as follows
```
$ make -e CONF=blah
mkdir -p dist
mkdir -p build/blah
mkdir -p build
mkdir -p download/7.3.1-bd63e13aa157
/home/foo/splunk-uf-installer/bin/download_uf.sh -V 7.3.1 -H bd63e13aa157 -d download/7.3.1-bd63e13aa157
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 24.4M  100 24.4M    0     0  18.2M      0  0:00:01  0:00:01 --:--:-- 18.2M
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    92  100    92    0     0   1957      0 --:--:-- --:--:-- --:--:--  1957
sed -e 's!@@DS_URL@@!https://127.0.0.1:8089!' /home/foo/splunk-uf-installer/scripts/installme.sh > build/blah/installme.sh
cp download/7.3.1-bd63e13aa157/splunkforwarder-7.3.1-bd63e13aa157-Linux-x86_64.tgz build/blah/splunkforwarder.tgz
( cd build/default; \
/home/foo/splunk-uf-installer/tools/makeself/makeself.sh \
        --notemp \
        --nox11 \
        --gzip \
        --follow \
        --export-conf \
        . \
        /home/foo/splunk-uf-installer/dist/splunk_linux_installer-7.3.1-bd63e13aa157.sh \
        "Splunk Linux UF Installer" \
        ./installme.sh; \
)
Header is 631 lines long

About to compress 25096 KB of data...
Adding files to archive named "/home/foo/splunk-uf-installer/dist/splunk_linux_installer-7.3.1-bd63e13aa157.sh"...
./installme.sh
./splunkforwarder.tgz
CRC: 577634187
MD5: 71b65eba4eb7918b7ed4212890b39978

Self-extractable archive "/home/foo/splunk-uf-installer/dist/splunk_linux_installer-7.3.1-bd63e13aa157.sh" successfully created.
```
