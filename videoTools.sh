#!/usr/bin/bash
#
# Video Tools
#
# Dependency:
#   annie: get video's info & download videos
#       https://github.com/iawia002/annie
#   ffprobe: get video's resolution
#       part of ffmpeg
#   danmaku2ass: convert xml danmaku to ass
#       https://github.com/m13253/danmaku2ass
# Usage:
#   see `usage()` or `${basename $0} help`
#

ORIGIN_COOKIES="${HOME}/Downloads/cookies.txt"
COOKIES="./bilibili.cookies"
DOWNLOAD_LIST="./.download.list"
INFO_LIST="./download.info"
INFO_LIST_TMP="./.download.info.tmp"
MOVE_DIR="${HOME}/Videos"

echoWarning() {
    echo -ne "\033[33;1mWARNING:\033[0m "; echo $*
}

echoError() {
    echo -ne "\033[31;1mERROR:\033[0m "; echo $*
}

makeBilibiliCookies() {
    if [[ -f "${ORIGIN_COOKIES}" ]]; then
        echo -n "Generating Bilibili cookies ... "
        grep 'bilibili.*\(DedeUserID\(__ckMd5\)\?\|SESSDATA\|sid\)' \
            "${ORIGIN_COOKIES}" \
            > "${COOKIES}"
        sed -i 's/^#//' "${COOKIES}"
        if [[ $? -eq 0 ]]; then
            echo "DONE!"
        fi
        rm "${ORIGIN_COOKIES}"
    else
        echoWarning "Downloaded cookies not found!"
    fi
}

updateInfo() {
    echo -n "Processing download list ... "
    sed -E 's/^#([0-9a-z])/\1/' ./download.list | grep -Eo '^[^#]+' > "${INFO_LIST_TMP}"
    if [[ $? -eq 0 ]]; then
        echo "DONE!"
    fi
    echo -n "Generating infomation list ... "
    annie -p -j -c "${COOKIES}" -F "${INFO_LIST_TMP}" | \
        grep -E '("title"|"url":.*www\.bilibili\.com)' \
        > "${INFO_LIST}"
    rm "${INFO_LIST_TMP}"
    sed -i -E 's/^ +//' "${INFO_LIST}"
    sed -i -E 's/("url": ".*) *#.*"/\1"/' "${INFO_LIST}"
    echo "DONE!"
}

listDownload() {
    catDownloadList() {
        cat "${DOWNLOAD_LIST}"
    }

    makeDownloadList() {
        if [[ ! -f "./download.list" ]]; then
            echoError "Download list is not found in ./download.list"
            exit 1
        fi
        echo -n "Processing download list ... "
        sed -E 's/ *#.*$//' ./download.list | grep '.\+' > "${DOWNLOAD_LIST}"
        if [[ $? -eq 0 ]]; then
            echo "DONE!"
        fi
    }

    case "$1" in
        "make"|"generate" )
            makeDownloadList
            ;;
        * )
            catDownloadList
            ;;
    esac
}

download() {
    if [[ ! -f  "${DOWNLOAD_LIST}" ]]; then
        listDownload make
    fi
    annie -p -C -c "${COOKIES}" -F "${DOWNLOAD_LIST}" && rm "${DOWNLOAD_LIST}"
}

xml2ass() {
    getVideoRes() {
        videoFile="$1"
        ffprobe -v error \
            -select_streams v:0 \
            -show_entries stream=width,height \
            -of csv=s=x:p=0 \
            "${videoFile}"
    }

    xmlFile="$1"
    xmlFileName=${xmlFile%.xml}
    videoFile="${xmlFileName}.flv"
    if [[ -f "${xmlFileName}.mp4" ]]; then
        videoFile="${xmlFileName}.mp4"
    fi
    if [[ -f "${videoFile}" ]]; then
        optRes=$(getVideoRes "${videoFile}")
        height=${optRes#*x}
        optFs=$((${height}*50/1080))
        optDm=12
        optAlpha=.7
        echo -n "Generating ${xmlFileName}.ass ... "
        danmaku2ass \
            -s ${optRes} \
            -fs ${optFs} \
            -dm ${optDm} \
            -ds ${optDm} \
            -a ${optAlpha} \
            -o "${xmlFileName}.ass" "${xmlFile}"
        if [[ $? -eq 0 ]]; then
            echo "DONE!"
        fi
    else
        echoWarning "Video ${xmlFileName##*/} is not found!"
    fi
}

makeAss() {
    for i in "${1-}"*.xml; do
        xml2ass "$i"
    done
}

statCount() {
    ls "$1"* \
        | sed -E 's/(.+第([0-9]+(\.[0-9]+)?).*[^]])(\[[0-9]+])?\.[^.]{3}(\.download)?$/\2\t\1/' \
        | sort -g | uniq -c
}

videoMove() {
    if [[ ! -n "$1" ]]; then
        echoError -n "Moving videos needs a param of PREFIX! "
        echo "Use $(basename $0) help for more help."
        exit 1
    fi
    targetDir="${MOVE_DIR}/$1"
    if [[ ! -d "${targetDir}" ]]; then
        echo -n "Making folder: ${targetDir} ... "
        mkdir -p "${targetDir}"
        echo "DONE!"
    fi
    echo "Moving $(ls "$1"* | wc -l) files to ${targetDir}"
    rsync -aP --remove-source-files "$1"* "${targetDir}"
}

usage() {
    NAME=$(basename $0)
    cat << EOF
${NAME} is a video download tool

usage:  ${NAME} SUBCOMMAND [OPTION]...

SUBCOMMAND:
    cookie          - make bilibili cookies
    list [make]     - list or generate download list
    download        - download videos and generate ass
    stat [PREFIX]   - show file list & counts with PREFIX of filename
    ass [PREFIX]    - generate ass from xml with PREFIX of filename
    info            - generate video infomations
    move PREFIX     - move files with PREFIX of filename to ${MOVE_DIR}/PREFIX
    help            - show this help text

EOF
}

main() {
    SUBCMD="$1"
    shift
    case "$SUBCMD" in
        "download"|"d" )
            download
            makeAss
            ;;
        "list"|"ls" )
            listDownload $*
            ;;
        "cookie" )
            makeBilibiliCookies
            ;;
        "ass" )
            makeAss $*
            ;;
        "stats"|"stat" )
            statCount $*
            ;;
        "info" )
            updateInfo
            ;;
        "move" )
            videoMove $*
            ;;
        "help"|""|"-h"|"--help" )
            usage
            ;;
        * )
            echoError "Vaild SUBCOMMAND, use $(basename $0) help for help."
    esac
}

main $*
