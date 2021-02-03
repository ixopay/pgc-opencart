#!/usr/bin/env bash
set -euo pipefail

error_exit() {
    echo "$1" 1>&2
    exit 1
}

link_folders() {
  find $1/ -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | xargs -L1 -I{} ln -s "$1/{}" "$2/{}" || error_exit "Failed to link source code";
}

SRC_PATH="/source_code/src"

echo "Linking Source to Extension folder"

mkdir -p "/opt/bitnami/opencart/catalog"
mkdir -p "/opt/bitnami/opencart/image/catalog"
mkdir -p "/opt/bitnami/opencart/system/library"
link_folders "${SRC_PATH}/upload/admin" "/opt/bitnami/opencart/admin"
link_folders "${SRC_PATH}/upload/catalog" "/opt/bitnami/opencart/catalog"
link_folders "${SRC_PATH}/upload/image/catalog" "/opt/bitnami/opencart/image/catalog"
link_folders "${SRC_PATH}/upload/system/library" "/opt/bitnami/opencart/system/library"

echo "Activate Extension"

DB_FIELD_NAME="PaymentGatewayCloud"

# Tell Opencart about the extension
OC_EXT_ID=$(mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO \`oc_extension_install\` SET \`filename\` = 'opencart-${DB_FIELD_NAME,,}-local-dev.ocmod.zip', \`extension_download_id\` = '0', \`date_added\` = NOW(); SELECT LAST_INSERT_ID();" | tail -n1) || error_exit "Failed to register Extension"
# Add all Extension files to Opencart DB
for file_path in $(find $SRC_PATH/upload -not -path '*/\.*' -printf "%P\n"); do
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO \`oc_extension_path\` SET \`extension_install_id\` = '${OC_EXT_ID}', \`path\`  = '${file_path}', \`date_added\`  = NOW();"
done
# Register Extension
mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO \`oc_modification\` SET \`extension_install_id\` = '${OC_EXT_ID}', \`name\` = '${DB_FIELD_NAME}', \`code\` = '$(echo "${DB_FIELD_NAME}" | sed '/^/{s/^//;s/\b\([[:alpha:]]\)\([[:alpha:]]*\)\b/\u\1\L\2/g;s/^//;}')', \`author\` = '${DB_FIELD_NAME}', \`version\` = 'local-dev', \`link\` = '', \`xml\` = '<modification>\n    <name>${DB_FIELD_NAME}</name>\n    <version>local-dev</version>\n    <author>${DB_FIELD_NAME}</author>\n    <code>$(echo "${DB_FIELD_NAME}" | sed '/^/{s/^//;s/\b\([[:alpha:]]\)\([[:alpha:]]*\)\b/\u\1\L\2/g;s/^//;}')</code>\n</modification>', \`status\` = '1', \`date_added\` = NOW();"
DB_FIELD_NAME=${DB_FIELD_NAME,,}

# Enable Extension
mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO \`oc_extension\` (type, code) VALUES ('payment','${DB_FIELD_NAME}_creditcard');"

