#!/bin/sh

export CGO_ENABLED=1
export GOOS=linux

case $1 in
    amd64)
        ARCH="64"
        FNAME="amd64"
        export GOARCH=amd64
        ;;
    armv8 | arm64 | aarch64)
        ARCH="arm64-v8a"
        FNAME="arm64"
        export GOARCH=arm64
        export CC=aarch64-linux-gnu-gcc
        ;;
    armv7 | arm | arm32)
        ARCH="arm32-v7a"
        FNAME="arm32"
        export GOARCH=arm
        export GOARM=7
        export CC=arm-linux-gnueabihf-gcc
        ;;
    armv6)
        ARCH="arm32-v6"
        FNAME="armv6"
        export GOARCH=arm
        export GOARM=6
        export CC=arm-linux-gnueabihf-gcc
        ;;
    armv5)
        ARCH="arm32-v5"
        FNAME="armv5"
        export GOARCH=arm
        export GOARM=5
        export CC=arm-linux-gnueabi-gcc
        ;;
    i386)
        ARCH="32"
        FNAME="i386"
        export GOARCH=386
        export CC=i686-linux-gnu-gcc
        ;;
    s390x)
        ARCH="s390x"
        FNAME="s390x"
        export GOARCH=s390x
        export CC=s390x-linux-gnu-gcc
        ;;
    *)
        ARCH="64"
        FNAME="amd64"
        export GOARCH=amd64
        ;;
esac

go build -o xui-release -v main.go

mkdir -p build/bin
cp xui-release build/
cp x-ui.service build/
cp x-ui.sh build/
mv build/xui-release build/x-ui
cd build/bin

wget "https://github.com/XTLS/Xray-core/releases/download/v25.3.3/Xray-linux-${ARCH}.zip"
unzip "Xray-linux-${ARCH}.zip"
rm -f "Xray-linux-${ARCH}.zip" geoip.dat geosite.dat
wget https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
wget https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
mv xray "xray-linux-${FNAME}"
cd ../../