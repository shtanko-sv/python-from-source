#!/bin/sh -x

PYTHON_VERSION=3.9.0
ZLIB_VERSION=1.2.11
BZIP2_VERSION=1.0.8
GDBM_VERSION=1.18.1
LIBFFI_VERSION=3.3
OPENSSL_VERSION=1.1.1h
READLINE_VERSION=8.0
NCURSES_VERSION=6.2
LIBEXPAT_VERSION=2.2.10
MPDECIMAL_VERSION=2.5.0

# download_python
build_python() {
    wget https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz || clean_exit
    tar Jxvf Python-$PYTHON_VERSION.tar.xz || clean_exit
    cd Python-$PYTHON_VERSION || clean_exit
    rm -r Modules/expat || clean_exit
    rm -r Modules/_ctypes/libffi* || clean_exit
    rm -r Modules/_ctypes/darwin* || clean_exit
    rm -r Modules/_decimal/libmpdec || clean_exit
    sed -i -e 's/libmpdec\.so\.2/libmpdec.a/g' setup.py || clean_exit
    CFLAGS="$CFLAGS" LIBRARY_PATH="$LIBRARY_PATH" LDFLAGS="$LDFLAGS" ./configure \
        --prefix /tmp/python \
        --with-openssl=$workdir/deps \
        --with-system-expat \
        --with-system-ffi \
        --with-system-libmpdec \
        --with-computed-gotos || clean_exit
    CFLAGS="$CFLAGS" LIBRARY_PATH="$LIBRARY_PATH" LDFLAGS="$LDFLAGS" make -j || clean_exit
    CFLAGS="$CFLAGS" LIBRARY_PATH="$LIBRARY_PATH" LDFLAGS="$LDFLAGS" make install || clean_exit
}

build_zlib() {
    wget https://zlib.net/zlib-$ZLIB_VERSION.tar.gz || clean_exit
    tar zxvf zlib-$ZLIB_VERSION.tar.gz || clean_exit
    cd zlib-$ZLIB_VERSION || clean_exit
    ./configure --static --prefix=$workdir/deps || clean_exit
    make -j || clean_exit
    make install || clean_exit
    cd - > /dev/null || clean_exit
}

build_bzip2() {
    wget https://sourceware.org/pub/bzip2/bzip2-$BZIP2_VERSION.tar.gz || clean_exit
    tar zxvf bzip2-$BZIP2_VERSION.tar.gz || clean_exit
    cd bzip2-$BZIP2_VERSION > /dev/null || clean_exit
    # patch makefile
    sed -ie 's/CFLAGS=/CFLAGS=-fPIC /' Makefile
    make -j || clean_exit
    make install PREFIX=$workdir/deps || clean_exit
    cd - > /dev/null || clean_exit
}

build_libexpat() {
    github_tag=$(echo R_$LIBEXPAT_VERSION | sed -e 's/\./_/g')
    wget https://github.com/libexpat/libexpat/releases/download/$github_tag/expat-${LIBEXPAT_VERSION}.tar.gz || clean_exit
    tar zxvf expat-$LIBEXPAT_VERSION.tar.gz || clean_exit
    cd expat-$LIBEXPAT_VERSION || clean_exit
    ./configure --prefix=$workdir/deps --enable-static --enable-shared=no --with-pic || clean_exit
    make -j || clean_exit
    make install || clean_exit
    cd - > /dev/null || clean_exit
}

build_gdbm() {
    wget https://ftp.gnu.org/gnu/gdbm/gdbm-$GDBM_VERSION.tar.gz || clean_exit
    tar zxvf gdbm-$GDBM_VERSION.tar.gz || clean_exit
    cd gdbm-$GDBM_VERSION > /dev/null || clean_exit
    gdbm_cflags="-fcommon -fPIC"
    CFLAGS="$CFLAGS $gdbm_cflags" ./configure --enable-shared=no --enable-libgdbm-compat --prefix=$workdir/deps || clean_exit
    CFLAGS="$CFLAGS $gdbm_cflags" make -j || clean_exit
    CFLAGS="$CFLAGS $gdbm_cflags" make install || clean_exit
    cd - > /dev/null || clean_exit
}

build_libffi() {
    wget https://sourceware.org/pub/libffi/libffi-$LIBFFI_VERSION.tar.gz || clean_exit
    tar zxvf libffi-$LIBFFI_VERSION.tar.gz || clean_exit
    cd libffi-$LIBFFI_VERSION > /dev/null || clean_exit
    ffi_cflags="-fPIC"
    CFLAGS="$CFLAGS $ffi_cflags" ./configure --disable-shared --prefix=$workdir/deps|| clean_exit
    CFLAGS="$CFLAGS $ffi_cflags" make -j || clean_exit
    CFLAGS="$CFLAGS $ffi_cflags" make install || clean_exit
    cd - > /dev/null || clean_exit
}

build_libxcrypt() {
    wget https://github.com/besser82/libxcrypt/archive/v4.4.17.tar.gz || clean_exit
    tar zxvf v4.4.17.tar.gz || clean_exit
    cd libxcrypt-4.4.17 > /dev/null || clean_exit
    ./configure --disable-shared --enable-hashes=strong,glibc --enable-obsolete-api=no --disable-failure-tokens --prefix=$workdir/deps || clean_exit
    make -j || clean_exit
    make install || clean_exit
    cd - > /dev/null || clean_exit
}

build_openssl() {
    wget "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz" || clean_exit
    tar zxvf openssl-$OPENSSL_VERSION.tar.gz || clean_exit
    cd openssl-$OPENSSL_VERSION > /dev/null || clean_exit
    ./Configure --prefix=$workdir/deps no-shared linux-x86_64 || clean_exit
    make -j || clean_exit
    make install || clean_exit
    cd - > /dev/null || clean_exit
}

build_readline() {
    wget https://ftp.gnu.org/gnu/readline/readline-$READLINE_VERSION.tar.gz || clean_exit
    tar zxvf readline-$READLINE_VERSION.tar.gz || clean_exit
    cd readline-$READLINE_VERSION > /dev/null || clean_exit
    readline_flags="-fPIC"
    CFLAGS="$CFLAGS $readline_flags" ./configure --prefix=$workdir/deps --enable-static --enable-shared=no || clean_exit
    CFLAGS="$CFLAGS $readline_flags" make -j || clean_exit
    CFLAGS="$CFLAGS $readline_flags" make install || clean_exit
    cd - > /dev/null || clean_exit
}

build_ncurses() {
    wget https://ftp.gnu.org/pub/gnu/ncurses/ncurses-$NCURSES_VERSION.tar.gz || clean_exit
    tar zxvf ncurses-$NCURSES_VERSION.tar.gz || clean_exit
    cd ncurses-$NCURSES_VERSION > /dev/null || clean_exit
    ncurses_flags="-fPIC"
    CFLAGS="$CFLAGS $ncurses_flags" ./configure --without-shared --without-debug --without-ada --without-cxx --without-cxx-binding --enable-widec --prefix=$workdir/deps || clean_exit
    CFLAGS="$CFLAGS $ncurses_flags" make -j || clean_exit
    CFLAGS="$CFLAGS $ncurses_flags" make install || clean_exit
    cd - > /dev/null || clean_exit
}

build_mpdecimal() {
    wget https://www.bytereef.org/software/mpdecimal/releases/mpdecimal-$MPDECIMAL_VERSION.tar.gz || clean_exit
    tar zxvf mpdecimal-$MPDECIMAL_VERSION.tar.gz || clean_exit
    cd mpdecimal-$MPDECIMAL_VERSION > /dev/null || clean_exit
    mpdecimal_flags="-fPIC"
    CFLAGS="$CFLAGS $mpdecimal_flags" ./configure --prefix=$workdir/deps || clean_exit
    CFLAGS="$CFLAGS $mpdecimal_flags" make -j || clean_exit
    CFLAGS="$CFLAGS $mpdecimal_flags" make install || clean_exit
    # remove shared libraries
    rm -rf $workdir/deps/lib/*so* || clean_exit
    cd - > /dev/null || clean_exit
}

clean_exit() {
    last_exit_code=$?
    if [ ! -z $startdir ]; then
        cd $startdir > /dev/null || exit 1
    fi
    if [ ! -z $workdir ]; then
        # rm -rf $workdir
        echo "exit";
    fi
    exit $last_exit_code
}


startdir=$PWD
workdir=$(mktemp -d)
cd $workdir > /dev/null || clean_exit

CFLAGS="$CFLAGS -I$workdir/deps/include -I$workdir/deps/include/ncursesw"
LIBRARY_PATH="$LIBRARY_PATH:$workdir/deps/lib"
LDFLAGS="$LDFLAGS -L$workdir/deps/lib"

build_zlib
build_bzip2
build_libexpat
build_gdbm
build_libffi
build_openssl
build_ncurses
build_readline
build_mpdecimal
build_python
clean_exit
