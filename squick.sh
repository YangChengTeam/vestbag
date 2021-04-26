#!/bin/sh
# 作者: 张凯

function usage() {
    echo "usage: "
    echo "  sh squick.sh -a def.apk -t 4"
    echo "  -a apk文件路径"
    echo "  -t 是哪个apk|开启脚本的名称 1-9"
    echo "  -d 是否删除缓存包 0|1"
    echo "  -c 是否复制母包 0|1"
    echo "  -g 是否生成一个测试包 0|1"
    echo "  -s 是否开启脚本 0|1"
    echo "  -v 检测包的有效性 0|1"
    echo "  -h 帮助手册"
    exit
}

spath=$(pwd)
# 进程管理
if [[ $1 == "pm"  &&  $2 == "start" ]];then
   pm2 delete auto.js
   pm2 start auto.js --name auto$3 -i 8
   pm2 save
   pm2 startup
   exit
fi

if [[  $1 == "pm" && $2 == "restart" ]];then
   pm2 restart auto.js
   exit
fi

if [[  $1 == "pm" && $2 == "stop" ]];then
   pm2 stop auto.js
   exit
fi

if [[  $1 == "pm"  && $2 == "log" ]];then
   pm2 log
   exit
fi

# 文件管理
if [[ $1 == "fs" && $2 == "clean" ]];then
   sh rm_tmp.sh
   exit
fi

if [[ $1 == "fs"  && $2 == "check" ]];then
	echo "正在检测有效性"
   node rm_invalid_apk_main.js $3
   exit
fi


#  马甲包管理
apk="-"
soft_type="-"
is_del_apk=0
is_gen_test_apk=0
is_copy=1
is_start=0
is_quick_start=0
is_valid=0
while getopts ":a:t:d:c:g:h" arg
do
  case $arg in
       a)
          apk=$OPTARG
          ;;
       t)
          soft_type=$OPTARG
          ;;
       d)
          is_del_apk=$OPTARG
          ;;
       c)
          is_copy=$OPTARG
          ;;
       g)
          is_gen_test_apk=$OPTARG
          ;;
       h)
          usage
          ;;
       *)  #当有不认识的选项的时候arg为*
          usage
          ;;
  esac
done



if [[ ${soft_type} == "-" ]];then
    echo "E: 缺少参数 -t type "
    exit
fi


if [[ ${apk} != "-" ]];then
   if [[ -e res/${apk} ]]; then
      if [[ ! -e ../Uploads/apk/${soft_type}/ ]]; then
         echo "W: 目录../Uploads/apk/${soft_type}/不存在"
         mkdir -p ../Uploads/apk/${soft_type}/
      fi
      echo "I: 正在构造打包资源"
      sh spreauto.sh ${apk} ${soft_type}
      echo "I: 正在关闭打包脚本..."
      pm2 stop auto.js
      echo "删除所有临时文件"
      sh rm_tmp.sh 

      if [[ ${is_copy} == 1 ]];then
         echo "I: 复制母包到../Uploads/apk/${soft_type}/"
         cp res/${apk} ../Uploads/apk/${soft_type}/def.apk
      fi

      if [[ ${is_del_apk} == 1 ]]; then
         echo "I: 正在删除旧包资源../Uploads/apk/${soft_type}/"
         for dir in $(ls ../Uploads/apk/${soft_type})
         do
            if [[ -d ../Uploads/apk/${soft_type}/${dir} ]]; then
               rm -rf ../Uploads/apk/${soft_type}/${dir}/*.apk
            fi 
         done
      fi  

      if [[ ${is_gen_test_apk} == 1 ]];then
          echo "正在打本地测试包${spath}/test/test${soft_type}.apk"
	       sh sauto.sh "${spath}/test/test${soft_type}.apk" test "${spath}/test/test.png" test${soft_type} ${soft_type} "test" "" "test" "10000" 0
      fi 
   else 
      echo "E: res/${apk} 文件不存在"
   fi
elif [[ ${is_gen_test_apk} == 1 ]];then
	 echo "正在打本地测试包${spath}/test/test${soft_type}.apk"
	       sh sauto.sh "${spath}/test/test${soft_type}.apk" test "${spath}/test/test.png" test${soft_type} ${soft_type} "test" "" "test" "10000" 0
else
   echo "E: 缺少参数 -a apk"
fi




