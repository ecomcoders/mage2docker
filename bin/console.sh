#!/usr/bin/env bash

# Enable bash strict mode
set -euo pipefail

# Define globals
SCRIPTNAME="bin/$(basename $0)"
PROJECTPATH=$(pwd)
CONFIGFOLDER="$PROJECTPATH/config"
ENVIRONMENTVARIABLESFILE="$PROJECTPATH/.env"
DOCKERCOMPOSEFILE="$PROJECTPATH/docker-compose.yml"

generateDockerEnvFile()
{
    if [ ! -f "${PROJECTPATH}/.env" ]; then
        cp .env.dist .env
        echo 'Generated docker .env file. Feel free to adapt it to your needs.'
    fi
}

createSharedDirectoriesIfNotExists()
{
    if [ ! -d "${PROJECTPATH}/shared/htdocs" ]; then
        mkdir -p ${PROJECTPATH}/shared/htdocs ${PROJECTPATH}/shared/db
    fi
}

includeEnvVarFileAndExportVars()
{
    . "$ENVIRONMENTVARIABLESFILE"
    export $(grep "^[^#]" "$ENVIRONMENTVARIABLESFILE" | cut -d= -f1 )
}

start()
{
    docker-compose -f $DOCKERCOMPOSEFILE up -d
}

stop()
{
    docker-compose -f $DOCKERCOMPOSEFILE stop
}

installMagento()
{
    # see http://devdocs.magento.com/guides/v2.1/install-gde/install/cli/install-cli-install.html
    executeInDocker composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition /var/www/html || true
    executeInDocker "chmod +x /var/www/html/bin/magento \
        && /var/www/html/bin/magento setup:install \
            --admin-firstname=${ADMIN_FIRSTNAME} \
            --admin-lastname=${ADMIN_LASTNAME} \
            --admin-email=${ADMIN_EMAIL} \
            --admin-user=${ADMIN_USERNAME} \
            --admin-password=${ADMIN_PASSWORD} \
            --base-url=${BASE_URL} \
            --backend-frontname=${BACKEND_FRONTNAME} \
            --db-host=mysql \
            --db-name=${DATABASE_NAME} \
            --db-user=${DATABASE_USER} \
            --db-password=${DATABASE_PASSWORD} \
            --language=${DEFAULT_LANGUAGE} \
            --currency=${DEFAULT_CURRENCY} \
            --timezone=${DEFAULT_TIMEZONE} \
            --use-rewrites=1 \
            --session-save=${SESSION_SAVE} \
            --cleanup-database"
    info
}

executeInDocker() {
  docker-compose exec php bash -c "$*"
}

executeBinMagentoInDocker() {
    docker-compose exec php bash -c "bin/magento $*"
}

usage() {
  echo "Utility for controlling dockerized Magento projects"
  echo "Usage:$SCRIPTNAME <action> <arguments...>"
  echo ""
  echo "Actions:"
  printf "  %-15s%-30s\n" "exec" "Execute bin/magento inside docker"
  printf "  %-15s%-30s\n" "install" "Install Magento 2"
  printf "  %-15s%-30s\n" "restart" "Recreate and restart containers"
  printf "  %-15s%-30s\n" "start, up" "Create and start containers"
  printf "  %-15s%-30s\n" "stop" "Stop containers"
  printf "  %-15s%-30s\n" "info" "Print useful informations"
}

info() {
    printf "%-15s%-30s\n" "Frontend URI:" $BASE_URL
    printf "%-15s%-30s\n" "Backend URI:" ${BASE_URL}${BACKEND_FRONTNAME}
    printf "%-15s%-30s\n" "Admin User:" ${ADMIN_USERNAME}
    printf "%-15s%-30s\n" "Password:" ${ADMIN_PASSWORD}
}

#######################################
# Main programm logic
#######################################
generateDockerEnvFile
createSharedDirectoriesIfNotExists
includeEnvVarFileAndExportVars

arguments=${*:-}
set -- "$arguments"

case $1 in
    install)
    installMagento
    ;;

    start|up)
    start
    ;;

    stop)
    stop
    ;;

    exec)
    shift 1
    executeBinMagentoInDocker $*
    ;;

    info)
    info
    ;;

    *)
    usage
    ;;
esac