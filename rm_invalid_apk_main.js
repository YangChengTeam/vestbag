
let start = new Date()
const path = require("path")
const fs = require("fs")
const os = require('os'),
cpuCount = os.cpus().length
const fork = require('child_process').fork

var scriptsDir = __dirname
var uploadsDir = ""
var scriptsDirs = scriptsDir.split(path.sep)
let errorFiles = []
let deadCount = 0
for (var i = 0; i < scriptsDirs.length; i++) {
  if (i != scriptsDirs.length - 1) {
    uploadsDir += scriptsDirs[i] + path.sep
  }
}
var uploadsApKDir = uploadsDir + path.sep + "Uploads" + path.sep + "apk" + path.sep

var walk = function (dir, done) {
  var results = []
  fs.readdir(dir, function (err, list) {
    if (err) return done(err)
    var pending = list.length
    if (!pending) return done(null, results)
    list.forEach(function (file) {
      file = path.resolve(dir, file)
      fs.stat(file, function (err, stat) {
        if (stat && stat.isDirectory()) {
          walk(file, function (err, res) {
            results = results.concat(res)
            if (!--pending) done(null, results)
          });
        } else {
          results.push(file)
          if (!--pending) done(null, results)
        }
      })
    })
  })
}

let type = process.argv[2]
let dir = `${uploadsApKDir}${type}`
if (!fs.existsSync(dir)) {
  console.log(`${dir}目录不存在`)
  return
}

walk(dir, async (err, results) => {
  console.log(`${dir}目录总共有${(results && results.length) || 0}个包`)
  if (err) return
  let thread_count = results.length > 100 ? cpuCount : 1
  if (thread_count > 10) {
    thread_count = 10
  }
  console.log(`--------------------启动${thread_count}个进程检测文件--------------------`)
  for (let i = 0; i < thread_count; i++) {
    let n = parseInt(results.length / thread_count) + (results.length % thread_count ? 1 : 0)
    const worker = fork(`${__dirname}/rm_invalid_apk_work.js`)

    worker.on('message', (file_path) => {
       errorFiles.push(file_path)
    })

    worker.send({ type: "data", value: results.slice(i * n, (i + 1) * n) })

    worker.on('exit', (code) => {
      if (++deadCount >= thread_count) {
        console.error("--------------------无效包汇总--------------------")
        console.error("无效包总数: " + errorFiles.length)
        if (errorFiles.length > 0) {
          errorFiles.forEach(file_path => {
            console.error(file_path + "无效包")
          })
        }
        let end = new Date()
        let minutes = (end - start) / 1000 / 60
        console.log(`检测总用时间${minutes.toFixed(2)}分钟`)
      }
    })
  }
})