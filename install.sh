#!/bin/sh

#=================================================================#
#  System Required:  CentOS 6 or Higher                           #
#  Description: One click Install Package environment             #
#  Author：zhangkai <mzpbvsig@gmail.com>                          #
#=================================================================#


# jdk download url
jdk_url=""

# Need softs
softs=(
zip
unzip
convert
java  
node
redis
)

# Check command is exist
check_command(){
    local command=$1 
    if hash $command 2> /dev/null; then
        return 1
    else
        return 0
    fi
}

# Install all soft
install_softs(){
    local pkg=get_pkg
    for ((i=1;i<=${#softs[@]};i++ )); do
        command="${softs[$i-1]}"
        install_${command} yum
    done
}

install_node(){
    if check_command node; then
        echo "node 未安装 执行安装命令..."
        curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
        yum -y install nodejs    
    else
       echo "nodejs 已安装"
    fi

    npm i

    if check_command pm2; then
        npm install -g pm2
     else
       echo "pm2 已安装"
    fi
}

install_convert(){
    if check_command convert; then
        echo "convert 未安装 执行安装命令..."
        yum -y install ImageMagick
    else
       echo "convert 已安装"
    fi
}

install_redis(){
    if check_command redis-cli; then
        echo "redis 未安装 执行安装命令..."
        yum -y install epel-release
        yum -y update
        yum -y install redis
        systemctl start redis
        systemctl enable redis
    else
       echo "redis 已安装"
    fi
}

install_zip(){
    if check_command zip; then
        echo "zip  未安装 执行安装命令..."
        yum -y install zip
    else
       echo "zip 已安装"
    fi
}

install_unzip(){
    if check_command unzip; then
        echo "unzip  未安装 执行安装命令..."
        yum -y install unzip
    else
       echo "unzip 已安装"
    fi
}


install_java(){
    if check_command java; then
        echo "java  未安装 执行安装命令..."
        yum -y install java-1.8.0-openjdk-devel
    else
        echo "java 已安装"
    fi
}


install_softs