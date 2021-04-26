const fs = require("fs");
const parseString = require('xml2js').parseString;
const path = require('path');

function genConfig(xmlPath, apkPath) {
    var config = `#!/bin/sh \n`
    var promise = new Promise((r, j) => {
        fs.readFile(path.join(xmlPath, 'AndroidManifest.xml'), function (err, data) {

            if (err) {
                j(err)
                return
            }

            parseString(data, function (err, result) {
                if (err) {
                    j(err)
                    return
                }
                var icon = result.manifest.application[0].$["android:icon"]
                let iconInfos = icon.split("/")
                console.log("I: 图标:" + icon)
                var iconDir = iconInfos[0].substr(1)
                var iconName = ""
                if (iconInfos.length == 2) {
                    iconName = iconInfos[1] + ".png"
                    config += `icon_name="${iconName}"\n`
                } else {
                    j("E: AndroidManifest.xml format error")
                    return;
                }
                

                let dpiNames = {
                    "":"icon_name_dir",
                    "-hdpi": "icon_name_dir",
                    "-ldpi": "icon_name_dir_l",
                    "-mdpi": "icon_name_dir_m",
                    "-xhdpi": "icon_name_dir_x",
                    "-xxhdpi": "icon_name_dir_xx",
                    "-xxxhdpi": "icon_name_dir_xxx",
                    "-hdpi-v4": "icon_name_dir",
                    "-ldpi-v4": "icon_name_dir_l",
                    "-mdpi-v4": "icon_name_dir_m",
                    "-xhdpi-v4": "icon_name_dir_x",
                    "-xxhdpi-v4": "icon_name_dir_xx",
                    "-xxxhdpi-v4": "icon_name_dir_xxx"
                }

                for (attr in dpiNames) {
                    let iconPath = path.join(apkPath, "res", iconDir + attr + "/" + iconName)
                    if (fs.existsSync(iconPath)) {
                        config += `${dpiNames[attr]}="${path.join("res", iconDir + attr)}"\n`
                    }
                }

                let appName = result.manifest.application[0].$["android:label"]
                config += `default_app_name="${appName}"\n`
                r(config)

            });
        });
    });
    promise.catch(new Function)
    return promise
}


async function main() {
    let xmlPath = process.argv[2]
    let apkPath = process.argv[3]
    let type = process.argv[4]
    if(!fs.existsSync(apkPath)){
        console.log("W: 资源目录"+apkPath + " not exist")
        console.log(`I: 请执行: sh squick.sh -a ${type}.apk -t ${type} -g 1 `)
        return
    }
    var config = await genConfig(xmlPath, apkPath)
    console.log(config)
    if (!fs.existsSync("../" + type + ".config")) {
        fs.writeFileSync("../" + type + ".config", config, "utf-8")
        console.log('gen ' + type + ".config success")
    } else {
        console.log(type+'.config  is exist')
    }
}

main()
