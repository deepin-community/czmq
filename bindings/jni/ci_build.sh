#!/usr/bin/env bash
################################################################################
#  THIS FILE IS 100% GENERATED BY ZPROJECT; DO NOT EDIT EXCEPT EXPERIMENTALLY  #
#  Read the zproject/README.md for information about making permanent changes. #
################################################################################
#
#   Exit if any step fails
set -e

# Set this to enable verbose profiling
[ -n "${CI_TIME-}" ] || CI_TIME=""
case "$CI_TIME" in
    [Yy][Ee][Ss]|[Oo][Nn]|[Tt][Rr][Uu][Ee])
        CI_TIME="time -p " ;;
    [Nn][Oo]|[Oo][Ff][Ff]|[Ff][Aa][Ll][Ss][Ee])
        CI_TIME="" ;;
esac

# Set this to enable verbose tracing
[ -n "${CI_TRACE-}" ] || CI_TRACE="no"
case "$CI_TRACE" in
    [Nn][Oo]|[Oo][Ff][Ff]|[Ff][Aa][Ll][Ss][Ee])
        set +x ;;
    [Yy][Ee][Ss]|[Oo][Nn]|[Tt][Rr][Uu][Ee])
        set -x ;;
esac

########################################################################
# Build and check the jni binding
########################################################################

export BUILD_PREFIX=/tmp/jni_build
CZMQ_JNI_ROOT=${PWD}
CZMQ_ROOT=${PWD}/../..

CONFIG_OPTS=()
CONFIG_OPTS+=("CFLAGS=-I${BUILD_PREFIX}/include")
CONFIG_OPTS+=("CPPFLAGS=-I${BUILD_PREFIX}/include")
CONFIG_OPTS+=("CXXFLAGS=-I${BUILD_PREFIX}/include")
CONFIG_OPTS+=("LDFLAGS=-L${BUILD_PREFIX}/lib")
CONFIG_OPTS+=("PKG_CONFIG_PATH=${BUILD_PREFIX}/lib/pkgconfig")
CONFIG_OPTS+=("--prefix=${BUILD_PREFIX}")
CONFIG_OPTS+=("--with-docs=no")
if [ -z "${CI_CONFIG_QUIET-}" ] || [ "${CI_CONFIG_QUIET-}" = yes ] || [ "${CI_CONFIG_QUIET-}" = true ]; then
    CONFIG_OPTS+=("--quiet")
fi

rm -rf /tmp/tmp-deps
mkdir -p /tmp/tmp-deps

# Clone and build dependencies
[ -z "$CI_TIME" ] || echo "`date`: Starting build of dependencies (if any)..."
export LIBMICROHTTPD_ROOT="/tmp/tmp-deps/libmicrohttpd"
wget http://ftp.gnu.org/gnu/libmicrohttpd/libmicrohttpd-0.9.44.tar.gz
tar -xzf $(basename "http://ftp.gnu.org/gnu/libmicrohttpd/libmicrohttpd-0.9.44.tar.gz")
mv $(basename "http://ftp.gnu.org/gnu/libmicrohttpd/libmicrohttpd-0.9.44.tar.gz" .tar.gz) $LIBMICROHTTPD_ROOT
cd $LIBMICROHTTPD_ROOT
$CI_TIME ./configure "${CONFIG_OPTS[@]}"
$CI_TIME make -j4
$CI_TIME make install

export LIBZMQ_ROOT="/tmp/tmp-deps/libzmq"
$CI_TIME git clone --quiet --depth 1 https://github.com/zeromq/libzmq.git $LIBZMQ_ROOT

cd $LIBZMQ_ROOT
git --no-pager log --oneline -n1
if [ -e autogen.sh ]; then
    $CI_TIME ./autogen.sh 2> /dev/null
fi
if [ -e buildconf ]; then
    $CI_TIME ./buildconf 2> /dev/null
fi
if [ ! -e autogen.sh ] && [ ! -e buildconf ] && [ ! -e ./configure ] && [ -s ./configure.ac ]; then
    $CI_TIME libtoolize --copy --force && \
    $CI_TIME aclocal -I . && \
    $CI_TIME autoheader && \
    $CI_TIME automake --add-missing --copy && \
    $CI_TIME autoconf || \
    $CI_TIME autoreconf -fiv
fi
$CI_TIME ./configure "${CONFIG_OPTS[@]}"
$CI_TIME make -j4
$CI_TIME make install


export LIBCURL_ROOT="/tmp/tmp-deps/libcurl"
$CI_TIME git clone --quiet --depth 1 https://github.com/curl/curl.git $LIBCURL_ROOT

cd $LIBCURL_ROOT
git --no-pager log --oneline -n1
if [ -e autogen.sh ]; then
    $CI_TIME ./autogen.sh 2> /dev/null
fi
if [ -e buildconf ]; then
    $CI_TIME ./buildconf 2> /dev/null
fi
if [ ! -e autogen.sh ] && [ ! -e buildconf ] && [ ! -e ./configure ] && [ -s ./configure.ac ]; then
    $CI_TIME libtoolize --copy --force && \
    $CI_TIME aclocal -I . && \
    $CI_TIME autoheader && \
    $CI_TIME automake --add-missing --copy && \
    $CI_TIME autoconf || \
    $CI_TIME autoreconf -fiv
fi
$CI_TIME ./configure "${CONFIG_OPTS[@]}"
$CI_TIME make -j4
$CI_TIME make install


cd $CZMQ_ROOT
[ -z "$CI_TIME" ] || echo "`date`: Starting build of currently tested project..."
git --no-pager log --oneline -n1
if [ -e autogen.sh ]; then
    $CI_TIME ./autogen.sh 2> /dev/null
fi
if [ -e buildconf ]; then
    $CI_TIME ./buildconf 2> /dev/null
fi
if [ ! -e autogen.sh ] && [ ! -e buildconf ] && [ ! -e ./configure ] && [ -s ./configure.ac ]; then
    $CI_TIME libtoolize --copy --force && \
    $CI_TIME aclocal -I . && \
    $CI_TIME autoheader && \
    $CI_TIME automake --add-missing --copy && \
    $CI_TIME autoconf || \
    $CI_TIME autoreconf -fiv
fi
$CI_TIME ./configure "${CONFIG_OPTS[@]}"
$CI_TIME make -j4
$CI_TIME make install
[ -z "$CI_TIME" ] || echo "`date`: Build completed without fatal errors!"

cd ${CZMQ_JNI_ROOT}
[ -z "$TRAVIS_TAG" ] || IS_RELEASE="-PisRelease"

TERM=dumb $CI_TIME ./gradlew build jar -PbuildPrefix=$BUILD_PREFIX $IS_RELEASE --info
TERM=dumb $CI_TIME ./gradlew clean

########################################################################
#  Build and check the jni android binding
########################################################################

if [ "$TRAVIS_OS_NAME" == "linux" ] && [ "$BINDING_OPTS" == "android" ]; then
    pushd ../../builds/android
        export NDK_VERSION=android-ndk-r21d
        export ANDROID_NDK_ROOT="/tmp/${NDK_VERSION}"

        case $(uname | tr '[:upper:]' '[:lower:]') in
          linux*)
            HOST_PLATFORM=linux-x86_64
            ;;
          darwin*)
            HOST_PLATFORM=darwin-x86_64
            ;;
          *)
            echo "Unsupported platform"
            exit 1
            ;;
        esac

        if [ ! -d "${ANDROID_NDK_ROOT}" ]; then
            export FILENAME=$NDK_VERSION-$HOST_PLATFORM.zip

            (cd '/tmp' \
                && wget http://dl.google.com/android/repository/$FILENAME -O $FILENAME &> /dev/null \
                && unzip -q $FILENAME) || exit 1
            unset FILENAME
        fi
    popd

    pushd czmq-jni/android
        $CI_TIME ./build.sh "arm"
        $CI_TIME ./build.sh "arm64"
        $CI_TIME ./build.sh "x86"
        $CI_TIME ./build.sh "x86_64"
    popd
fi
