#!/bin/sh

# 作者: 张凯
start=`date +%s`

gen_apk_path=${1} #apk生成后的路径
app_name=${2}     #apk文件安装后名称
icon_path=${3}    #apk文件安装后图标路径
apk_name=${4}     #apk文件名称
apk_type=${5}     #哪个apk
agent_id=${6}     #渠道id
referer_url=${7}  #渠道url
site_id=${8}      #站点id
soft_id=${9}      #软件id
is_change_package_name=${10}  #是否换包名
channel_info=${11} #渠道信息
img=${12} #需要下载的图标

# 检测thumbnail_lighting文件是否存在
if  [[ ! -e "thumbnail_lighting.png" ]];then
   echo "thumbnail_lighting.png不存在"
   exit
fi

# 当前脚本路径
spath=$(pwd)

# 判断这个类型是否预处理  即是否执行过 sh squick -a type.apk -t type -d 1 -g 1

# 原始包资源信息
res_dir="srdef${apk_type}"  
oapk_path="sdef${apk_type}.apk"

if [[ ! -e ${oapk_path} || ! -d ${res_dir} ]];then
   echo "E: 类型:${apk_type} 原始包资源信息不存在"
   exit
fi

# 生成标识
key=${site_id}_${apk_type}_${soft_id}
# 可能中断过的包 极小概率 进程并发
dir=tmp/${key}

# 清理
function cls(){
   rm -rf "${dir}"
}

if [[ -d ${dir} ]];then
   echo "E: 正在打包中..."
   exit
fi

# 生成随机目录标识
mkdir -p ${dir}

# 判断图片是否存在png jpg gif
icon_exist=0
icon_name="${icon_path%.*}"
if  [[ -e ${icon_name}.jpg ]];then
   icon_path=${icon_name}.jpg
   icon_exist=1
elif [[ -e ${icon_name}.png ]];then
   icon_path=${icon_name}.png
   icon_exist=1
elif [[ -e ${icon_name}.gif ]];then
   icon_path=${icon_name}.gif
   icon_exist=1
fi

if [[ $icon_exist == 0 ]];then
    echo "W: 本地${icon_path}不存在"
  if [[ $img == "" ]];then
     echo "E: 未提供远程地址"
     exit
  fi
  echo 尝试下载 $img
  curl --insecure -Lo ${icon_path} ${img}
  if [[ ! -e $icon_path ]];then
     echo 'E: download error  ${img}'
     exit
  fi
  echo 下载成功$icon_path 
fi

# 动态配置信息

# 签名信息
jks_path='mjb_common.jks'
jks_ali="mjb_common"
jks_pass="123456"

# 应用信息
jb_icon="jb${apk_type}.png"   #角标信息
default_app_name=@string/app_name
icon_name=ic_launcher.png     #icon名称
icon_name_dir=""
icon_name_dir_l=""            #icon目录
icon_name_dir_m=""
icon_name_dir_h="" 
icon_name_dir_x="" 
icon_name_dir_xx=""
icon_name_dir_xxx=""

is_insert_channel=1   #是否插入渠道信息

# 读取配置文件
if [[ -e $apk_type.config ]];then
    IFS="="
    while read -r name value
    do
    value=${value//\"/}
    if [[ $name == "jks_path" ]];then
        jks_path=$value
    fi
    if [[ $name == "jks_ali" ]];then
        jks_ali=$value
    fi
    if [[ $name == "jks_pass" ]];then
        jks_pass=$value
    fi
    if [[ $name == "default_app_name" ]];then
        default_app_name=$value
    fi
    if [[ $name == "icon_name" ]];then
        icon_name=$value
    fi
    if [[ $name == "icon_name_dir" ]];then
        icon_name_dir=$value
    fi
    if [[ $name == "icon_name_dir_l" ]];then
        icon_name_dir_l=$value
    fi
    if [[ $name == "icon_name_dir_m" ]];then
        icon_name_dir_m=$value
    fi
    if [[ $name == "icon_name_dir_h" ]];then
        icon_name_dir_h=$value
    fi
    if [[ $name == "icon_name_dir_x" ]];then
        icon_name_dir_x=$value
    fi
    if [[ $name == "icon_name_dir_xx" ]];then
        icon_name_dir_xx=$value
    fi
    if [[ $name == "icon_name_dir_xxx" ]];then
        icon_name_dir_xxx=$value
    fi
    if [[ $name == "is_insert_channel" ]];then
        is_insert_channel=$value
    fi
    if [[ $name == "num" ]];then
        apk_type=${apk_type}_${value}
        res_dir="rdef${apk_type}"  
        oapk_path="def${apk_type}.apk"
    fi
   
    done < $apk_type.config
fi

# 转换图片
convert ${icon_path} -resize 90x90! -alpha Set thumbnail_lighting.png \
          \( -clone 0,1 -alpha Opaque -compose Hardlight -composite \) \
          -delete 0 -compose In -composite \
          "${dir}/${key}.png"

if [[ ! -e "${dir}/${key}.png" ]];then
  echo "E: icon error: convert fail"
  rm -f ${icon_path}
  cls
  exit
fi

if [[ -e $jb_icon ]]; then
     convert "${dir}/${key}.png" -geometry +0+0 -compose over $jb_icon -composite "${dir}/${key}.png"
fi

cp -rf srdef${apk_type} ${dir}

sed -i "s*${default_app_name}*${app_name}*g" "${dir}/srdef${apk_type}/AndroidManifest.xml" 

# 对应马甲包执行其它的相关操作
if [[ -e $apk_type.sh ]];then
    sh $apk_type.sh ${dir} ${apk_type}
fi

java -jar apktool-kk.jar b "${dir}/srdef${apk_type}"

cp -f sdef${apk_type}.apk ${dir}/sdef${apk_type}.apk
cp -f "${dir}/srdef${apk_type}/build/apk/AndroidManifest.xml" "${dir}/AndroidManifest.xml"

cd ${dir}

zip -g sdef${apk_type}.apk AndroidManifest.xml

if [[ $icon_name_dir != "" ]];then
   mkdir -p "${icon_name_dir}"
   cp "${key}.png"  "${icon_name_dir}/${icon_name}"
   zip -g sdef${apk_type}.apk "${icon_name_dir}/${icon_name}"
fi

if [[ $icon_name_dir_l != "" ]];then
   mkdir -p "${icon_name_dir_l}"
   cp "${key}.png"  "${icon_name_dir_l}/${icon_name}"
   zip -g sdef${apk_type}.apk "${icon_name_dir_l}/${icon_name}"
fi

if [[ $icon_name_dir_m != "" ]];then
   mkdir -p "${icon_name_dir_m}"
   cp "${key}.png"  "${icon_name_dir_m}/${icon_name}"
   zip -g sdef${apk_type}.apk "${icon_name_dir_m}/${icon_name}"
fi

if [[ $icon_name_dir_h != "" ]];then
   mkdir -p "${icon_name_dir_h}"
   cp "${key}.png"  "${icon_name_dir_h}/${icon_name}"
   zip -g sdef${apk_type}.apk "${icon_name_dir_h}/${icon_name}"
fi

if [[ $icon_name_dir_x != "" ]];then
   mkdir -p "${icon_name_dir_x}"
   cp "${key}.png"  "${icon_name_dir_x}/${icon_name}"
   zip -g sdef${apk_type}.apk "${icon_name_dir_x}/${icon_name}"
fi

if [[ $icon_name_dir_xx != "" ]];then
   mkdir -p "${icon_name_dir_xx}"
   cp "${key}.png"  "${icon_name_dir_xx}/${icon_name}"
   zip -g sdef${apk_type}.apk "${icon_name_dir_xx}/${icon_name}"
fi

if [[ $icon_name_dir_xxx  != "" ]];then
   mkdir -p "${icon_name_dir_xxx}"
   cp "${key}.png"  "${icon_name_dir_xxx}/${icon_name}"
   zip -g sdef${apk_type}.apk "${icon_name_dir_xxx}/${icon_name}"
fi


# 签名
java -jar ${spath}/apksigner.jar sign -v2-signing-enabled false --ks ${spath}/${jks_path} --ks-key-alias ${jks_ali}  --ks-pass pass:${jks_pass} --key-pass pass:${jks_pass} --out ${apk_name}.apk sdef${apk_type}.apk

if [[ ! -e "${apk_name}.apk" ]];then
   echo "E: jarsigner sign error"
   exit
fi

mkdir "META-INF"

if [[ $is_insert_channel == 1 ]]; then

echo "${channel_info}" > "META-INF/gamechannel.json"
echo "{\"author\":\"\", \"from_id\": \"\", \"agent_id\": \"${agent_id}\"}" > "META-INF/gamechannel.json"

echo "{\"node_id\":\"${gen_apk_path}\", \"node_url\": \"${referer_url}\", \"user_id\":\"${user_id}\", \"site_id\":\"${site_id}\", \"soft_id\": \"${soft_id}\"}" > "META-INF/channelconfig.json"

zip  -g ${apk_name}.apk "META-INF/gamechannel.json"
zip  -g ${apk_name}.apk "META-INF/channelconfig.json"

fi

mv "${apk_name}.apk" ${gen_apk_path}

stop=`date +%s`
echo "程序执行时间$[ stop - start ]秒"

cd ${spath}
cls

./aapt d badging ${gen_apk_path} > /dev/null  || (echo aapt check error ${gen_apk_path} && rm -f ${gen_apk_path})

