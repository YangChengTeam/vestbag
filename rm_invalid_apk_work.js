const fs = require("fs")
const {exec} = require('child_process').exec

function aapt(file_path) {
    var promise = new Promise((r, j) => {
        exec(`./aapt d badging ${file_path}`, function (error, stdout, stderr) {
            if (error) {
                j(error)
                return
            }
            r(true)
        })
    })
    return promise
}


process.on('message', async function (data) {
    let workerData = data.value
    console.log(`进程${process.pid}运行 分片数量:` + workerData.length)

    for (let i = 0; i < workerData.length; i++) {
        let file_path = workerData[i]
        let status = await aapt(file_path).catch(error => {
            fs.unlinkSync(file_path)
            console.error(file_path + "无效包 已删除")
            parentPort.postMessage(file_path)
        })
        if (status) {
            console.log(file_path + " 有效包")
        }
    }
    process.exit()
})


