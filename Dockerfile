FROM alpine:3.9
MAINTAINER wiserain

ARG MAKEFLAGS="-j2"
ARG LIBTORRENT_VER=libtorrent-1_1_13

RUN \
	echo "**** install frolvlad/alpine-python3 ****" && \
	apk add --no-cache bash && \
	apk add --no-cache python3 && \
	python3 -m ensurepip && \
	rm -r /usr/lib/python*/ensurepip && \
	pip3 install --upgrade pip setuptools && \
	if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
	if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python3 /usr/bin/python; fi && \
	echo "**** install plugin: telegram ****" && \
	apk add --no-cache py3-cryptography && \
	pip install --upgrade python-telegram-bot && \
	echo "**** install plugins: cfscraper ****" && \
	apk add --no-cache --virtual=build-deps g++ gcc python3-dev && \
	pip install --upgrade cloudscraper && \
	apk del --purge --no-cache build-deps && \
	echo "**** install plugins: convert_magnet ****" && \
	# https://github.com/emmercm/docker-libtorrent/blob/master/Dockerfile
	set -euo pipefail && \
	apk add --no-cache \
		boost-python3 \
		boost-system \
		libgcc \
		libstdc++ \
		openssl && \
	apk add --no-cache --virtual=build-deps \
		autoconf \
		automake \
		boost-dev \
		coreutils \
		file \
		g++ \
		gcc \
		git \
		libtool \
		make \
		openssl-dev \
		python3-dev && \
	cd $(mktemp -d) && \
	git clone https://github.com/arvidn/libtorrent.git && \
	cd libtorrent && \
	git checkout $LIBTORRENT_VER && \
	./autotool.sh && \
	./configure \
		CFLAGS="-Wno-deprecated-declarations" \
	    CXXFLAGS="-Wno-deprecated-declarations" \
	    --prefix=/usr \
	    --disable-debug \
	    --enable-encryption \
	    --enable-python-binding \
	    --with-libiconv \
	    --with-boost-python="$(ls -1 /usr/lib/libboost_python3*-mt.so* | head -1 | sed 's/.*.\/lib\(.*\)\.so.*/\1/')" \
	    PYTHON=`which python3` && \
	make VERBOSE=1 && \
	make install && \
	apk del --purge --no-cache build-deps && \
	# recover missing symlink for python3
	ln -sf /usr/bin/python3 /usr/bin/python && \
	echo "**** install plugin: misc ****" && \
	pip install --upgrade \
		transmissionrpc \
		deluge_client \
		irc_bot && \
	echo "**** install flexget ****" && \
	pip install --upgrade --force-reinstall \
		flexget && \
	echo "**** system configurations ****" && \
	apk --no-cache add shadow tzdata && \
	sed -i 's/^CREATE_MAIL_SPOOL=yes/CREATE_MAIL_SPOOL=no/' /etc/default/useradd && \
	echo "**** cleanup ****" && \
	rm -rf \
		/tmp/* \
		/root/.cache

# Install GNU libc (aka glibc)
# https://github.com/sgerrand/alpine-pkg-glibc
# https://github.com/Technosoft2000/docker-calibre-web/blob/master/Dockerfile
COPY LOCALE.md /init/
RUN \

    ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    ALPINE_GLIBC_PACKAGE_VERSION="2.29-r0" && \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \

    # create temporary directories
    mkdir -p /tmp && \
    mkdir -p /var/cache/apk && \

    apk add --no-cache --virtual=.build-dependencies wget ca-certificates && \
    apk add --no-cache parallel && \

    wget "https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub" \
         -O "/etc/apk/keys/sgerrand.rsa.pub" && \

    wget "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
         "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
         "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \

    apk add --no-cache \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \

    # iterate through all locale and install it
    # NOTE: locale -a is not available in alpine linux, 
    # use `/usr/glibc-compat/bin/locale -a` instead
    cat /init/LOCALE.md | parallel "echo generate locale {}; /usr/glibc-compat/bin/localedef --force --inputfile {} --charmap UTF-8 {}.UTF-8;" && \

    apk del .build-dependencies && \

    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    rm "/root/.wget-hsts" && \
    rm "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
       "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
       "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"

# Install calibre binary
# enhancement from jim3ma/docker-calibre-web
# needed for calibre ebook-convert command line tool
# https://github.com/jim3ma/docker-calibre-web
# https://manual.calibre-ebook.com/generated/en/ebook-convert.html
# https://github.com/Technosoft2000/docker-calibre-web/blob/master/Dockerfile
ENV \
    LD_LIBRARY_PATH="/usr/lib:/opt/calibre/lib" \
    PATH="$PATH:/opt/calibre" \
    LC_ALL="C" \
    CALIBRE_INSTALLER_SOURCE_CODE_URL="https://raw.githubusercontent.com/kovidgoyal/calibre/master/setup/linux-installer.py"

RUN \
    apk update && \
    apk add --no-cache --upgrade \
        bash \
        ca-certificates \
        gcc \
        libxcomposite \
        mesa-gl \
        python \
        qt5-qtbase-x11 \
        xdg-utils \
        xz \
        wget && \

    wget -O- ${CALIBRE_INSTALLER_SOURCE_CODE_URL} | \
      python -c \
      "import sys; \
       main=lambda:sys.stderr.write('Download failed\n'); \
       exec(sys.stdin.read()); \
       main(install_dir='/opt', isolated=True)" && \

    rm -rf /tmp/calibre-installer-cache && \

    # remove not needed packages
    apk del --purge $PKG_DEV \
                    $PKG_IMAGES_DEV && \

    # create Calibre Web folder structure
    mkdir -p $APP_HOME/app && \

    # cleanup temporary files
    rm -rf /tmp && \
    rm -rf /var/cache/apk/*

# copy local files
COPY files/ /

# add default volumes
VOLUME /config /data
WORKDIR /config

# expose port for flexget webui
EXPOSE 3539 3539/tcp

# run init.sh to set uid, gid, permissions and to launch flexget
RUN chmod +x /scripts/init.sh
CMD ["/scripts/init.sh"]
