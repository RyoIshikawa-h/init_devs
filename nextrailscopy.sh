#!/bin/bash

echo ""
read -p "プロジェクト名を入力してください（※ 半角小文字 例：nextrails）: " PNAME
echo "  $PNAME"
read -p "アプリ名を入力してください（※ 半角小文字 例：app）: " APPNAME
echo -e "   $APPNAME\\n"
current_folder=$(basename "$(pwd)")
APP_PATH=/${APPNAME}

# クローンリポジトリの初期URL
FRONT_URL=https://github.com/githuno/nextrails-ini-frontend.git
BACK_URL=https://github.com/githuno/nextrails-ini-backend.git
DEV_CON=https://github.com/githuno/devcon-nextrails.git

# -----------------------------------------------------------------------------------------|

echo "現在の階層は $current_folder 下 です。"
read -p "ここに${PNAME}のプロジェクトディレクトリを作成しますか? <y/N> : " yn
if [[ "$yn" == [yY] ]]; then
    Pfolder="./${PNAME}"
    tmpfolder="./${PNAME}_tmp"
else
    read -p "作成するディレクトリを指定してください。: " specified_dir
    trimmed_dir=$(echo "$specified_dir" | sed 's:/*$::')
    Pfolder="${trimmed_dir}/${PNAME}"
    tmpfolder="${trimmed_dir}/${PNAME}_tmp"
fi

# if [[ "$yn" == [yY] ]]; then のように、[[ ... ]] を使用する場合：
# より強力な条件式を使用できます。例えば、&& や || などの論理演算子を使うことができます。
# 文字列のパターンマッチングができます。== や != の他にも =~ を使って正規表現を使用できます。
# 変数の値が空の場合にもエラーになりません。ただしデフォルトcodespaceでは使えない

# プロジェクトフォルダとアプリフォルダを作成
if [ ! -e "${Pfolder}" ]; then
    mkdir ${Pfolder}
    echo -e "\\n ${Pfolder}を新規作成しました。\\n"
else
    echo -e "\\n ${Pfolder}は既に存在します。\\n"
fi
if [ ! -e "${Pfolder}/${APPNAME}" ]; then
    mkdir ${Pfolder}/${APPNAME}
    echo -e "${Pfolder}/${APPNAME}を新規作成しました。\\n"
else
    echo -e "${Pfolder}/${APPNAME}は既に存在します。\\n"
fi

# -----------------------------------------------------------------------------------------|

if [ -e "${Pfolder}/.devcontainer" ] ; then # .devcontainerが存在して、更にその他のファイルも存在する場合
    echo -e -n "${Pfolder}には.devcontainerが既に存在しますが、上書きして初期化を続行して大丈夫ですか?\\n\
        ※ または\"ex\"でそのまま既存の.devcontainerを使用します。\\n\
        <y/N> : "
    read -r yn
    if [[ "$yn" == [yY] ]]; then
        rm -rf "${Pfolder}/.devcontainer"
    elif [ "$yn" != "ex" ]; then
        echo "終了します。"
        exit
	fi
fi

if [ "$yn" = "ex" ]; then
    echo "既存の.devcontainerを使用して初期化を続行します。"
else
    git clone $DEV_CON $tmpfolder/.devcontainer
    mv $tmpfolder/.devcontainer ${Pfolder}
    rm -rf $tmpfolder
fi

# git削除
if [ -e "${Pfolder}/.devcontainer/.git" ]; then
    read -p ".devcontainerのgitを削除します。 <ENTER> : " INPUT
    if [ -z "$INPUT" ]; then
        rm -rf ${Pfolder}/.devcontainer/.git
        echo ".gitを削除しました。"
    else
        echo ".gitは削除しませんでした。"
    fi
fi

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
NSUBW="10.0.0.0/16"
NGATE="10.0.0.1"

EOT

# ./.envファイルを読み込んで変数として参照できるようにする
source ${Pfolder}/${APPNAME}/.env

# -----------------------------------------------------------------------------------------|

# 各ディレクトリをfor文で順に初期化
TARGET=("${CONTAINER1}" "${CONTAINER2}" "${CONTAINER3}")
DESTURL=("${FRONT_URL}" "${BACK_URL}" "")

for ((i=0; i<${#TARGET[@]}; i++));
do

    echo -e "\\n【${TARGET[$i]}】\\n"
    if [ -e ${Pfolder}/${APPNAME}/${TARGET[$i]} ]; then   # ${TARGET[$i]}ディレクトリが存在する場合
        read -p "既に${TARGET[$i]}が存在します。既存フォルダを削除して大丈夫ですか? <y/N> : " yn
        if [[ "$yn" == [yY] ]]; then
            # 該当ディレクトリの削除
            if [ -e "${Pfolder}/${APPNAME}/${TARGET[$i]}/.next" ] || [ ${TARGET[$i]} = "db" ]; then
                sudo rm -rf ${Pfolder}/${APPNAME}/${TARGET[$i]} # 一度でもrootでyarn devするとrootファイルが生成されてしまう
            fi
            rm -rf ${Pfolder}/${APPNAME}/${TARGET[$i]}
            echo -e "\\n既存の${TARGET[$i]}を削除しました。\\n"
        else
            echo -e "${TARGET[$i]}は初期化しませんでした。\\n\\n"         # 終了
        fi
    fi
    if [[ "$yn" == [yY] ]] || [ ! -e ${Pfolder}/${APPNAME}/${TARGET[$i]} ]; then      # 続行
        if [ ${TARGET[$i]} = "db" ]; then
            echo "${TARGET[$i]}を初期化します。"
            mkdir ${Pfolder}/${APPNAME}/${TARGET[$i]} ${Pfolder}/${APPNAME}/${TARGET[$i]}/data
        else
            echo -e -n "${TARGET[$i]}を${DESTURL[$i]}で初期化します。\\n\
                    ※ または\"mk\"でnew\\n\
                    ※ またはリポジトリURL入力でclone\\n\
                <ENTER> : "
            read -r INPUT
            case "$INPUT" in
            ( https*git )
                echo -e "︙\\n ${TARGET[$i]}を${INPUT}で初期化します。\\n\︙\\n"
                git clone ${INPUT} ${Pfolder}/${APPNAME}/${TARGET[$i]}
            ;;( mk )
                mkdir ${Pfolder}/${APPNAME}/${TARGET[$i]}
            ;;( * )
                git clone ${DESTURL[$i]} ${Pfolder}/${APPNAME}/${TARGET[$i]}
            ;;esac
        fi

        # git削除
        if [ -e "${Pfolder}/${APPNAME}/${TARGET[$i]}/.git" ]; then
            read -p "${TARGET[$i]}のgitを削除します <ENTER> : " INPUT
            if [ -z "$INPUT" ]; then
                rm -rf ${Pfolder}/${APPNAME}/${TARGET[$i]}/.git
                echo ".gitを削除しました。"
            else
                echo ".gitは削除しませんでした。"
            fi
        fi

        echo -e "︙\\n︙\\n︙\\n   ${TARGET[$i]} is initialized !!\\n\\n"
    fi

done

# -----------------------------------------------------------------------------------------|

# docker compose up -d 
    # -buildつけることでキャッシュを使用せずcompose.ymlや依存関係の変更を反映させて新たにイメージを作成
    # --env-fileで.envのパスを指定 https://docs.docker.jp/compose/environment-variables.html#env
    #  -p でプロジェクトネーム（これは、docler-compose.ymlにname:を書くのと同意）https://docs.docker.jp/v1.10/compose/reference/overview.html
docker compose -f ${Pfolder}/.devcontainer/docker-compose.yml \
-p ${PNAME} --env-file ${Pfolder}/${APPNAME}/.env up -d --build

# Pfolderへ移動
if [ ! "${current_folder}" = "${PNAME}" ]; then

    echo "cd ${Pfolder} で移動してください"
    # ./***.shではなく . ./***.sh であれば移動可能：https://atmarkit.itmedia.co.jp/bbs/phpBB/viewtopic.php?topic=5801&forum=10
    # $ . test.sh
        # ファイル読み込み -> 実行 (ディレクトリ移動)
    # $ ./test.sh
        # bash起動 -> ファイル読み込み -> 実行 (ディレクトリ移動) -> bash終了
fi
