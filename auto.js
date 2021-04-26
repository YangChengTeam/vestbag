/**
作者: 张凯

*/
const fs = require('fs')
const path = require('path')
const exec = require('child_process').exec
const redis = require("redis")


const redisKey = "app_list_44"   // 这个需要确定key值

// 获取打包目录
var scriptsDir = __dirname
var uploadsDir = ""
var scriptsDirs = scriptsDir.split(path.sep)

for (var i = 0; i < scriptsDirs.length; i++) {
	if (i != scriptsDirs.length - 1) {
		uploadsDir += scriptsDirs[i] + path.sep
	}
}
uploadsDir += "Uploads" + path.sep + "apk" + path.sep
console.log(uploadsDir)


// 入口
function main() {
	client = redis.createClient()

	client.on('ready', async function () {
		await loop().catch(() => {
			console.error("E: loop method error")
		})
	})

	client.on("error", function (err) {
		console.error("E: Redis error:" + err)
	})
}

// 循环执行任务
async function loop() {
	let data = await lpop().catch(() => { })
	if (data) {
		console.log(data)
		await task(data).catch(() => {
			console.error("E: do task error")
		})
	}
	setTimeout(async () => {
		await loop()
	}, 1000 * 1)
}

// 取首条记录并删除
function lpop() {
	let promise = new Promise((resolve, reject) => {
		client.lpop(redisKey, function (err, value) {
			if (err) {
				reject(err)
			} else {
				resolve(value)
			}
		})
	})
	return promise
}

// 执行打包任务
async function task(info) {
	info = JSON.parse(info)
	if (!isPkged(info)) {
		await run(info).catch(() => { console.error("E: run method error") })
	} else {
		console.log(`I: ${info.app_name}打过包（已跳过）`)
	}
}

// 运行打包任务
function run(info) {
	var promise = new Promise(async (resolve, reject) => {

		if (!isMatch(info)) return

		processInfo(info)

		sh = "sauto.sh"

		let cmd = `sh "${sh}" "${info.apk_path}" "${info.app_name}" "${info.icon_path}" "${info.apk_name}" "${info.type}" "${info.agent_id}" "" "${info.site_id}" "${info.soft_id}" "${info.is_change_package_name}" "${info.package_content.replace(/"/g, "\\\"")}" "${info.img}" `

		cmd += processCmd(info)

		console.log(cmd)
		console.log("开始打包...")
		cmd = cmd.replace(/'/g, "")

		exec(cmd, function (error, stdout, stderr) {
			if (error) {
				reject("E: cmd run error")
				return
			}
			console.log(stdout)
			resolve()
		})
	})
	return promise
}

// 是否已打包
function isPkged(info) {
	var flag = false
	var defapkPath = `${uploadsDir}${info.type}/def.apk`
	if (fs.existsSync(`tmp/${info.site_id}_${info.type}_${info.soft_id}`)) {
		flag = true
	} else if (fs.existsSync(info.apk_path)) {
		var defbirthtimeMs = 0
		if (fs.existsSync(defapkPath)) {
			defbirthtimeMs = fs.statSync(defapkPath).mtime.getTime()
		}
		var birthtimeMs = fs.statSync(info.apk_path).mtime.getTime()
		if (birthtimeMs > defbirthtimeMs) {
			flag = true
		} else {
			console.log(`I: ${info.app_name}已过期（重新打）`)
		}
	}
	return flag
}

// 匹配打包信息
function isMatch(info) {
	if (!info.app_name || info.app_name.length == 0) {
		console.log("E: miss app name")
		return false
	}
	return true;
}

// 处理打包信息
function processInfo(info) {
	info.package_content = info.package_content || ""
	info.VOL_CHANNEL = info.VOL_CHANNEL || 0

	info.app_name = filterAppname(info.app_name)
	if (info.type == 42 && info.app_name.indexOf("工具") == -1) {
		info.app_name += "工具"
	}

	var dir = uploadsDir + info.type + path.sep + path.dirname(info.apk_path).split(path.sep).pop()
	if (!fs.existsSync(dir)) {
		fs.mkdirSync(dir)
		console.log("I: 创建" + dir)
	}
}


// 过滤名称
function filterAppname(app_name) {
	console.log("过滤前: "+app_name)

	let filterWords = ['app', '下载', 'v[0-9|\.]+', '软件', '官方版', '官方', '完美破解版', '破解版', '最新版', '破解', '最新', '手机版', '手机', '安卓版', '安卓', 'ios版', '苹果版', '苹果', '永久破解', '免登陆版', '官网版', '官网', '客户端', 'PC版', 'vip会员', '会员', 'vip', '免费版', '安装', 'apk']
	var regExp = ''
	for (var i = 0; i < filterWords.length; i++) {
		regExp += filterWords[i]
		if (i != filterWords.length - 1) {
			regExp += "|"
		}
	}
	let reg = RegExp(regExp, 'ig')
	app_name = app_name.replace(reg, "").trim()

	console.log("过滤后: " + app_name)

	return app_name
}

// 处理命令
function processCmd(info) {
	let cmd = ""

	if (info.type == 8) {
		cmd = ` "${info.version_code}" "${info.version_name}" "${info.url}" "${info.lanuch_img}" "${info.package_name}"`
	}

	if (info.type == 19 || info.type == 25 || info.type == 26) {
		cmd = `"${info.VOL_CHANNEL}"`
	}

	return cmd
}

main()
