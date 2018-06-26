FROM alpine:3.7 AS builder
LABEL maintainer "mecab <mecab@misosi.ru>"

RUN apk add --no-cache alpine-sdk autoconf libtool automake boost-dev libevent-dev openssl-dev && \
#
# Build libdb
#
cd /tmp && \
curl -L http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz -o db-4.8.30.NC.tar.gz && \
echo '12edc0df75bf9abd7f82f821795bcee50f42cb2e5f76a6a281b85732798364ef  db-4.8.30.NC.tar.gz' | sha256sum -c && \
tar zxvf db-4.8.30.NC.tar.gz && \
cd /tmp/db-4.8.30.NC && \
cd build_unix && \
../dist/configure --disable-shared --enable-cxx --disable-replication --with-pic --prefix=/tmp/built/ && \
make libdb_cxx-4.8.a libdb-4.8.a && \
make install_lib install_include && \
apk add --no-cache libevent-dev && \
#
# Copy built libs to use in the following build
#
cp -r /tmp/built/** /usr/local && \
#
# Build Yenten
#
cd /tmp && \
curl -L https://github.com/conan-equal-newone/yenten/archive/2.0.1fix.tar.gz -o yenten-2.0.1fix.tar.gz && \
echo '77e2dbbc888fd92bb965e830f4b79cf6f7d48ee3a076e7fc50fee7df70eae0a0  yenten-2.0.1fix.tar.gz' | sha256sum -c && \
tar -zxvf yenten-2.0.1fix.tar.gz && \
cd /tmp/yenten-2.0.1fix && \
./autogen.sh && \
./configure LDFLAGS=-L/usr/local/lib/ CPPFLAGS=-I/usr/local/lib/ --enable-upnp-default --without-gui --disable-tests --prefix=/tmp/built && \
make && \
make install

FROM alpine:3.7

RUN apk add --no-cache boost boost-program_options libevent openssl
COPY --from=builder /tmp/built /usr/local

ENTRYPOINT ["/usr/local/bin/yentend"]
VOLUME ["/data"]
CMD ["-datadir=/data"]
