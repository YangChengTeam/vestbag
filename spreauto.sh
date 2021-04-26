#!/bin/sh
apk=${1}
rdefdir=srdef${2}
echo ${rdefdir}

if [[ -d ${rdefdir} ]]; then
	rm -rf ${rdefdir}
fi

if [[ -d ${2} ]]; then
	rm -rf ${2}
fi

if [[ -e sdef${2}.apk ]]; then
	rm -rf sdef${2}.apk
fi

cp -f ${apk} sdef${2}.apk
zip -d  sdef${2}.apk "META-INF/*" 

unzip apktool-kk.jar prebuilt/linux/aapt
mv prebuilt/linux/aapt .
rm -rf prebuilt
chmod +x aapt

java -jar apktool-kk.jar -s d ${apk}
mkdir ${rdefdir}
mv ${2}/AndroidManifest.xml ${rdefdir}/AndroidManifest.xml
mv ${2}/apktool.yml ${rdefdir}/apktool.yml
cp ${apk}  ${rdefdir}/def.apk

cd ${rdefdir}
unzip -d tmp/ def.apk > /dev/null
node ../gen_config.js ../${rdefdir} tmp  ${2}
cd tmp
zip -9 def.apk ./resources.arsc
cp def.apk ../def.apk

cd ..
rm -rf ../${2}
rm -rf tmp/


