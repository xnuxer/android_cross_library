# THIS DOCKERFILE TRIES TO COMPILE CURL/OPENSSL FOR ANDROID
#
# 5 july 2015
#
# More detals could be found here: 
# http://vitiy.info/dockerfile-example-to-compile-libcurl-for-android-inside-docker-container/
#
# Fixed and update by Dani Firmansyah, get from repo at http://github.com/xnuxer/android_cross_library
 
FROM ubuntu

MAINTAINER Victor Laskin "victor.laskin@gmail.com"
MAINTAINER Dani Firmansyah "dnfsec@gmail.com"

# Install compilation tools

RUN echo "nameserver 8.8.8.8" >> /etc/resolv.conf

RUN apt-get update && apt-get install -y \
    automake \
    build-essential \
    wget \
    p7zip-full \
    bash \
    curl


# Download SDK / NDK

RUN mkdir /Android && cd Android && mkdir output
WORKDIR /Android

RUN wget http://dl.google.com/android/android-sdk_r24.3.3-linux.tgz
RUN wget http://dl.google.com/android/ndk/android-ndk-r10e-linux-x86_64.bin

# Extracting ndk/sdk

RUN tar -xvzf android-sdk_r24.3.3-linux.tgz && \
	chmod a+x android-ndk-r10e-linux-x86_64.bin && \
	7z x android-ndk-r10e-linux-x86_64.bin


# Set ENV variables

ENV ANDROID_HOME /Android/android-sdk-linux
ENV NDK_ROOT /Android/android-ndk-r10e
ENV PATH $PATH:$ANDROID_HOME/tools
ENV PATH $PATH:$ANDROID_HOME/platform-tools

# Make stand alone toolchain (Modify platform / arch here)

RUN mkdir=toolchain-arm && bash $NDK_ROOT/build/tools/make-standalone-toolchain.sh --verbose --platform=android-19 --install-dir=toolchain-arm --arch=arm --toolchain=arm-linux-androideabi-clang3.6 --llvm-version=3.6 --system=linux-x86_64 --stl=libc++

ENV TOOLCHAIN /Android/toolchain-arm
ENV SYSROOT $TOOLCHAIN/sysroot
ENV PATH $PATH:$TOOLCHAIN/bin:$SYSROOT/usr/local/bin

# Configure toolchain path

ENV ARCH armv7

#ENV CROSS_COMPILE arm-linux-androideabi
ENV CC arm-linux-androideabi-clang
ENV CXX arm-linux-androideabi-clang++
ENV AR arm-linux-androideabi-ar
ENV AS arm-linux-androideabi-as
ENV LD arm-linux-androideabi-ld
ENV RANLIB arm-linux-androideabi-ranlib
ENV NM arm-linux-androideabi-nm
ENV STRIP arm-linux-androideabi-strip
ENV CHOST arm-linux-androideabi

ENV CXXFLAGS -std=c++14 -Wno-error=unused-command-line-argument

# download, configure and make Zlib

RUN curl -O http://zlib.net/fossils/zlib-1.2.8.tar.gz && \
	tar -xzf zlib-1.2.8.tar.gz && \
	mv zlib-1.2.8 zlib
RUN cd zlib && ./configure --static && \
	make && \
	ls -hs . && \
	cp libz.a /Android/output

# open ssl


ENV CPPFLAGS -mthumb -mfloat-abi=softfp -mfpu=vfp -march=$ARCH  -DANDROID

RUN curl -O https://www.openssl.org/source/old/1.0.2/openssl-1.0.2n.tar.gz && \
	tar -xzf openssl-1.0.2n.tar.gz
RUN ls && cd openssl-1.0.2n && ./Configure android-armv7 no-asm no-shared --static --with-zlib-include=/Android/zlib/include --with-zlib-lib=/Android/zlib/lib && \
	make build_crypto build_ssl -j 4 && ls && cp libcrypto.a /Android/output && cp libssl.a /Android/output 
RUN cp -r openssl-1.0.2n /Android/output/openssl


# Download and extract curl

ENV CFLAGS -v -DANDROID --sysroot=$SYSROOT -mandroid -march=$ARCH -mfloat-abi=softfp -mfpu=vfp -mthumb -DCURL_STATICLIB 
ENV CPPFLAGS $CPPFLAGS $CFLAGS -L/Android/openssl-1.0.2n/include
ENV LDFLAGS -L${TOOLCHAIN}/include -march=$ARCH -Wl,--fix-cortex-a8 -L/Android/openssl-1.0.2n


RUN curl -O https://curl.haxx.se/download/curl-7.43.0.tar.gz && \
	tar -xzf curl-7.43.0.tar.gz
RUN cd curl-7.43.0 && ./configure --host=arm-linux-androideabi --disable-shared --enable-static --disable-dependency-tracking --with-zlib=/Android/zlib --with-ssl=/Android/openssl-1.0.2n --without-ca-bundle --without-ca-path --enable-ipv6 --enable-http --enable-ftp --disable-file --disable-ldap --disable-ldaps --disable-rtsp --disable-proxy --disable-dict --disable-telnet --disable-tftp --disable-pop3 --disable-imap --disable-smtp --disable-gopher --disable-sspi --disable-manual --target=arm-linux-androideabi --build=x86_64-unknown-linux-gnu --prefix=/opt/curlssl || cat config.log

# Make curl 

RUN cd curl-7.43.0 && \
	make && \
	ls lib/.libs/ && \
	cp lib/.libs/libcurl.a /Android/output && \
	ls -hs /Android/output && \
	mkdir /output


RUN cp -r curl-7.43.0 /Android/output/curl


# ziplib 

RUN curl -O https://libzip.org/download/libzip-0.11.2.tar.gz && \
	tar -xzf libzip-0.11.2.tar.gz && \
	mv libzip-0.11.2 libzip && \
	cd libzip && \
	./configure --help && \
	./configure --enable-static --host=arm-linux-androideabi --target=arm-linux-androideabi && \
	make && \
	ls -hs lib && \
	cp lib/.libs/libzip.a /Android/output && \
	mkdir /Android/output/ziplib && \
	cp lib/*.c /Android/output/ziplib && \
	cp lib/*.h /Android/output/ziplib && \
	cp config.h /Android/output/ziplib




# To get the results run container with output folder
# Example: docker run -v HOSTFOLDER:/output --rm=true IMAGENAME 

ENTRYPOINT cp -r /Android/output/* /output
#ENTRYPOINT cp -r /Android/toolchain-arm /toolchain-arm
