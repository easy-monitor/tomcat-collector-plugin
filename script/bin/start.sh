#!/bin/bash


PACKAGE_NAME=tomcat-collector-plugin
PACKAGE_PATH=$(dirname "$(cd `dirname $0`; pwd)")
LOG_DIRECTORY=$PACKAGE_PATH/log
LOG_FILE=$LOG_DIRECTORY/$PACKAGE_NAME.log


if ! type getopt >/dev/null 2>&1 ; then
  message="command \"getopt\" is not found"
  echo "[ERROR] Message: $message" >& 2
  echo "$(date "+%Y-%m-%d %H:%M:%S") [ERROR] Message: $message" > $LOG_FILE
  exit 1
fi

getopt_cmd=`getopt -o h -a -l help:,host:,port:,config-file-path:,exporter-host:,exporter-port: -n "start_script.sh" -- "$@"`
if [ $? -ne 0 ] ; then
    exit 1
fi
eval set -- "$getopt_cmd"


config_file_path="conf/tomcat.yml"
host="127.0.0.1"
port="9999"
exporter_host="127.0.0.1"
exporter_port=8989

print_help() {
    echo "Usage:"
    echo "    start_script.sh [options]"
    echo "    start_script.sh --config-file-path conf/tomcat.yml [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help                 show help"
    echo "      --host     the listen address of tomcat(\"127.0.0.1\" by default)"
    echo "      --port     the listen port of tomcat(\"9999\" by default)"
    echo "      --config-file-path     the path of config file (\"conf/tomcat.yml\")"
    echo "      --exporter-host        the listen address of exporter (\"127.0.0.1\" by default)"
    echo "      --exporter-port        the listen port of exporter (8989 by default)"
}

while true
do
    case "$1" in
        -h | --help)
            print_help
            shift 1
            exit 0
            ;;
        --host)
            case "$2" in
                "")
                    shift 2  
                    ;;
                *)
                    host="$2"
                    shift 2;
                    ;;
            esac
            ;;
        --port)
            case "$2" in
                "")
                    shift 2  
                    ;;
                *)
                    port="$2"
                    shift 2;
                    ;;
            esac
            ;;
        --config-file-path)
            case "$2" in
                "")
                    shift 2  
                    ;;
                *)
                    config_file_path="$2"
                    shift 2;
                    ;;
            esac
            ;;
        --exporter-host)
            case "$2" in
                "")
                    shift 2  
                    ;;
                *)
                    exporter_host="$2"
                    shift 2;
                    ;;
            esac
            ;;
        --exporter-port)
            case "$2" in
                "")
                    shift 2  
                    ;;
                *)
                    exporter_port="$2"
                    shift 2;
                    ;;
            esac
            ;;
        --)
            shift
            break
            ;;
        *)
            message="argument \"$1\" is invalid"
            echo "[ERROR] Message: $message" >& 2
            echo "$(date "+%Y-%m-%d %H:%M:%S") [ERROR] Message: $message" > $LOG_FILE
            print_help
            exit 1
            ;;
    esac
done

mkdir -p $LOG_DIRECTORY

message="start exporter"
echo "[INFO] Message: $message"
echo "$(date "+%Y-%m-%d %H:%M:%S") [INFO] Message: $message" >> $LOG_FILE

config_file="conf/$host-$port.yml"
echo $config_file
if [ ! -f "$config_file" ]; then
  cp $config_file_path $config_file
  sed -i "s#hostPort: .*#hostPort: $host:$port#g" $config_file
fi

cd $PACKAGE_PATH
java -jar src/jmx_prometheus_httpserver.jar $exporter_host:$exporter_port $config_file >/dev/null 2>$LOG_FILE &
# 获得执行的pid
echo $!