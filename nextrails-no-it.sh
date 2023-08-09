#!/bin/bash

PNAME="nextrails"
APPNAME="app"
current_folder=$(basename "$(pwd)")
APP_PATH=/${APPNAME}

# クローンリポジトリの初期URL
FRONT_URL=https://github.com/githuno/nextrails-front-1.git
BACK_URL=https://github.com/githuno/nextrails-back-1.git
DEV_CON=https://github.com/githuno/devcon-nextrails.git

# -----------------------------------------------------------------------------------------|

Pfolder="./${PNAME}"
tmpfolder="./${PNAME}_tmp"

# プロジェクトフォルダとアプリフォルダを作成
mkdir ${Pfolder}
echo -e "\\n ${Pfolder}を新規作成しました。\\n"
mkdir ${Pfolder}/${APPNAME}
echo -e "${Pfolder}/${APPNAME}を新規作成しました。\\n"

# -----------------------------------------------------------------------------------------|

git clone $DEV_CON $tmpfolder/.devcontainer
mv $tmpfolder/.devcontainer ${Pfolder}
rm -rf $tmpfolder
rm -rf ${Pfolder}/.devcontainer/.git

# -----------------------------------------------------------------------------------------|
cat <<EOT > ${Pfolder}/${APPNAME}/.env

# user
LOCALUID=`id -u`
LOCALUNAME=`id -un`
LOCALGID=`id -g`
LOCALGNAME=`id -gn`

# project
PNAME=${PNAME}
APPNAME=${APPNAME}
APP_PATH=/${APPNAME}

# rails
CONTAINER1="frontend"
PORT1="3003:3000"

# next
CONTAINER2="backend"
PORT2="3004:3000"

# postgres
CONTAINER3="db"
PORT3="5434:5432"
DB_NAME="db"
DB_USER="postgres"
DB_PW="password"

# adminer
CONTAINER4="adminer"
PORT4="8082:8080"

TZ="Asia/Tokyo"
LANG="C.UTF-8"

# network
NSUBW="11.0.0.0/16"
NGATE="11.0.0.1"

EOT

# ./.envファイルを読み込んで変数として参照できるようにする
source ${Pfolder}/${APPNAME}/.env

# -----------------------------------------------------------------------------------------|
# mkdir ${Pfolder}/${APPNAME}/frontend
# mkdir ${Pfolder}/${APPNAME}/backend
# mkdir ${Pfolder}/${APPNAME}/db ${Pfolder}/${APPNAME}/db/data

# docker compose -f ${Pfolder}/.devcontainer/docker-compose.yml \
# -p ${PNAME} --env-file ${Pfolder}/${APPNAME}/.env up -d --build

# sudo rm -rf ${Pfolder}/${APPNAME}/frontend
# sudo rm -rf ${Pfolder}/${APPNAME}/backend
# sudo rm -rf ${Pfolder}/${APPNAME}/db

# docker compose -p ${PNAME} stop

# 各ディレクトリをfor文で順に初期化
TARGET=("${CONTAINER1}" "${CONTAINER2}" "${CONTAINER3}")
DESTURL=("${FRONT_URL}" "${BACK_URL}" "")

for ((i=0; i<${#TARGET[@]}; i++));
do

    echo -e "\\n【${TARGET[$i]}】\\n"

	if [ ${TARGET[$i]} = "db" ]; then
		mkdir ${Pfolder}/${APPNAME}/${TARGET[$i]} ${Pfolder}/${APPNAME}/${TARGET[$i]}/data
	else
		mkdir ${Pfolder}/${APPNAME}/${TARGET[$i]}
		git clone ${DESTURL[$i]} ${Pfolder}/${APPNAME}/${TARGET[$i]}
	fi

	# git削除
	if [ -e "${Pfolder}/${APPNAME}/${TARGET[$i]}/.git" ]; then
		rm -rf ${Pfolder}/${APPNAME}/${TARGET[$i]}/.git
		echo ".gitを削除しました。"
	fi

	echo -e "︙\\n︙\\n︙\\n   ${TARGET[$i]} is initialized !!\\n\\n"

done

# -----------------------------------------------------------------------------------------|

# docker compose up -d
    # -buildつけることでキャッシュを使用せずcompose.ymlや依存関係の変更を反映させて新たにイメージを作成
    # --env-fileで.envのパスを指定 https://docs.docker.jp/compose/environment-variables.html#env
    #  -p でプロジェクトネーム（これは、docler-compose.ymlにname:を書くのと同意）https://docs.docker.jp/v1.10/compose/reference/overview.html
docker compose -f ${Pfolder}/.devcontainer/docker-compose.yml \
-p ${PNAME} --env-file ${Pfolder}/${APPNAME}/.env up -d

# Pfolderへ移動
# if [ ! "${current_folder}" = "${PNAME}" ]; then

#     echo "cd ${Pfolder} で移動してください"
#     # ./***.shではなく . ./***.sh であれば移動可能：https://atmarkit.itmedia.co.jp/bbs/phpBB/viewtopic.php?topic=5801&forum=10
#     # $ . test.sh
#         # ファイル読み込み -> 実行 (ディレクトリ移動)
#     # $ ./test.sh
#         # bash起動 -> ファイル読み込み -> 実行 (ディレクトリ移動) -> bash終了
# fi
