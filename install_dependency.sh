#!/bin/bash
set -e

if [ ! -d "clash.meta" ]; then
    echo "Downloading mihomo..."
    mkdir clash.meta
    # arm64
    curl -s https://api.github.com/repos/MetaCubeX/mihomo/releases/latest \
     | grep "browser_download_url.*mihomo-darwin-arm64-v.*gz" \
     | cut -d '"' -f 4 \
     | xargs curl -L -o clash.meta/mihomo-darwin-arm64.gz

     # amd64
    curl -s https://api.github.com/repos/MetaCubeX/mihomo/releases/latest \
     | grep "browser_download_url.*mihomo-darwin-amd64-v.*gz" \
     | cut -d '"' -f 4 \
     | xargs curl -L -o clash.meta/mihomo-darwin-amd64.gz

    echo "Download complete."
fi

echo "Unzip core files"
cd clash.meta
ls
gzip -d *.gz
echo "Create Universal core"
lipo -create -output com.metacubex.ClashX.ProxyConfigHelper.meta mihomo-darwin-amd64* mihomo-darwin-arm64*
chmod +x com.metacubex.ClashX.ProxyConfigHelper.meta

echo "Update meta core md5 to code"
CORE_MD5=$(md5 -q com.metacubex.ClashX.ProxyConfigHelper.meta)
echo "Core MD5: ${CORE_MD5}"
# 替换 MetaCoreMd5 常量的值，无论是占位符还是已有的 MD5
sed -i '' -E "s/(private let MetaCoreMd5 = \")[^\"]*(\")$/\1${CORE_MD5}\2/" ../ClashX/AppDelegate.swift
echo "Updated line:"
grep "MetaCoreMd5" ../ClashX/AppDelegate.swift

echo "Gzip Universal core"
gzip com.metacubex.ClashX.ProxyConfigHelper.meta
cp com.metacubex.ClashX.ProxyConfigHelper.meta.gz ../ClashX/Resources/
cd ..

echo "delete old files"
rm -f ./ClashX/Resources/country.mmdb
rm -f ./ClashX/Resources/geosite.dat
rm -f ./ClashX/Resources/geoip.dat
rm -rf ./ClashX/Resources/dashboard
rm -f GeoLite2-Country.*
echo "install mmdb"
curl -LO https://github.com/MetaCubeX/meta-rules-dat/raw/release/country.mmdb
gzip country.mmdb
mv country.mmdb.gz ./ClashX/Resources/country.mmdb.gz
echo "install geosite"
curl -LO https://github.com/MetaCubeX/meta-rules-dat/raw/release/geosite.dat
gzip geosite.dat
mv geosite.dat.gz ./ClashX/Resources/geosite.dat.gz
echo "install geoip"
curl -LO https://github.com/MetaCubeX/meta-rules-dat/raw/release/geoip.dat
gzip geoip.dat
mv geoip.dat.gz ./ClashX/Resources/geoip.dat.gz


echo "install yacd dashboard"
cd ClashX/Resources
git clone -b gh-pages https://github.com/MetaCubeX/Yacd-meta.git dashboard/yacd
cd dashboard/yacd
rm -rf *.webmanifest *.js CNAME .git
cd ../../

echo "install XD dashboard"
git clone -b gh-pages https://github.com/metacubex/metacubexd.git dashboard/xd
cd dashboard/xd
rm -rf *.webmanifest CNAME .git
cd ../../

echo "install zashboard"
git clone -b gh-pages https://github.com/Zephyruso/zashboard.git dashboard/zashboard
cd dashboard/zashboard
rm -rf *.webmanifest CNAME .git