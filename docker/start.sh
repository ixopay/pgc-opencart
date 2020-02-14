#!/bin/bash
# set -x
#set -euo pipefail

echo -e "Starting Opencart"

/app-entrypoint.sh nami start --foreground apache &

if [ ! -f "/setup_complete" ]; then

    echo -e "Waiting for Opencart to Initialize"

    while [ ! -f "/bitnami/opencart/.initialized" ]; do sleep 2s; done

    find /opt -name "config.php" -exec sed -i "s#https://#http://#g" {} \;

    while (! $(curl --silent http://localhost:80 | grep "Your Store" > /dev/null)); do sleep 2s; done

    echo -e "Installing PGC Extension"

    DB_FIELD_NAME="payment_gateway_cloud"
    # TODO: Support whitelabeling like in the other shops
    if [ "${BUILD_ARTIFACT}" != "undefined" ]; then
        if [ -f /dist/paymentgatewaycloud.zip ]; then
            echo -e "Using Supplied zip ${BUILD_ARTIFACT}"
            ZIP_NAME=$(basename "${BUILD_ARTIFACT}")
            mkdir /tmp/source
            unzip /dist/paymentgatewaycloud.zip -d /tmp/source
            DB_FIELD_NAME=$(ls /tmp/source/upload/image/catalog/)
            cp -rf /tmp/source/upload/admin/* /opt/bitnami/opencart/admin/
            cp -rf /tmp/source/upload/catalog/* /opt/bitnami/opencart/catalog/
            cp -rf /tmp/source/upload/image/catalog/* /opt/bitnami/opencart/image/catalog/
            cp -rf /tmp/source/upload/system/library/* /opt/bitnami/opencart/system/library/
            # Tell Opencart about the extension
            OC_EXT_ID=$(mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO \`oc_extension_install\`  (extension_download_id, filename, date_added) VALUES (0,'${ZIP_NAME}',NOW()); SELECT LAST_INSERT_ID();" | tail -n1)
            # Add all Extension files to Opencart DB
            for file_path in $(find /tmp/source/upload -not -path '*/\.*' -printf "%P\n"); do
                mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO \`oc_extension_path\`  SET \`extension_install_id\`  = '${OC_EXT_ID}', \`path\`  = '${file_path}', \`date_added\`  = NOW();"
            done
            # Register and Enable Extension
            LOCAL_XML=$(cat /source/src/install.xml)
            mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO \`oc_modification\` SET \`extension_install_id\` = '${OC_EXT_ID}', \`name\` = '${DB_FIELD_NAME}', \`code\` = '${DB_FIELD_NAME}', \`author\` = '${DB_FIELD_NAME}', \`version\` = 'zip', \`link\` = '', \`xml\` = '${LOCAL_XML}', \`status\` = '1', \`date_added\` = NOW();"
        else
            echo "Faled to build!, there is no such file: ${BUILD_ARTIFACT}"
            exit 1
        fi
    else
        # Emulate Zip installation
        if [ ! -d "/source/.git" ] && [ ! -f  "/source/.git" ]; then
            if [ ! -f "/paymentgatewaycloud.zip" ]; then
                # Checkout and Package github code
                SRC_PATH="./src"
                echo -e "Checking out branch ${BRANCH} from ${REPOSITORY}"
                git clone $REPOSITORY /tmp/paymentgatewaycloud
                cd /tmp/paymentgatewaycloud
                git checkout $BRANCH
                if [ ! -z "${WHITELABEL}" ]; then
                    echo -e "Running Whitelabel Script for ${WHITELABEL}"
                    echo "y" | php build.php "gateway.mypaymentprovider.com" "${WHITELABEL}"
                    DEST_FILE="$(echo "y" | php build.php "gateway.mypaymentprovider.com" "${WHITELABEL}" 2>/dev/null | tail -n 1 | sed 's/.*Created file "\(.*\)".*/\1/g')"
                    unzip "${DEST_FILE}" -d /tmp/source
                    SRC_PATH="/tmp/source"
                    DB_FIELD_NAME=$(ls $SRC_PATH/upload/image/catalog/)
                fi
                # Copy Files
                cp -rf $SRC_PATH/upload/admin/* /opt/bitnami/opencart/admin/
                cp -rf $SRC_PATH/upload/catalog/* /opt/bitnami/opencart/catalog/
                cp -rf $SRC_PATH/upload/image/catalog/* /opt/bitnami/opencart/image/catalog/
                cp -rf $SRC_PATH/upload/system/library/* /opt/bitnami/opencart/system/library/
                # Tell Opencart about the extension
                OC_EXT_ID=$(mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO \`oc_extension_install\`  (extension_download_id, filename, date_added) VALUES (0,'opencart-${DB_FIELD_NAME}-github-${BRANCH}',NOW()); SELECT LAST_INSERT_ID();" | tail -n1)
                # Add all Extension files to Opencart DB
                for file_path in $(find $SRC_PATH/upload -not -path '*/\.*' -printf "%P\n"); do
                    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO \`oc_extension_path\`  SET \`extension_install_id\`  = '${OC_EXT_ID}', \`path\`  = '${file_path}', \`date_added\`  = NOW();"
                done
                # Register and Enable Extension
                LOCAL_XML=$(cat $SRC_PATH/install.xml)
                mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO \`oc_modification\`  SET \`extension_install_id\`  = '${OC_EXT_ID}', \`name\`  = '${DB_FIELD_NAME}', \`code\`  = '${DB_FIELD_NAME}', \`author\`  = '${DB_FIELD_NAME}', \`version\`  = '${BRANCH}', \`link\`  = '', \`xml\`  = '${LOCAL_XML}', \`status\`  = '1', \`date_added\`  = NOW();"
            fi
        else
            # Copy Files
            SRC_PATH="/source/src"
            echo -e "Deploying development Source!"
            cd /source
            if [ ! -z "${WHITELABEL}" ]; then
                echo -e "Running Whitelabel Script for ${WHITELABEL}"
                DEST_FILE="$(echo "y" | php build.php "gateway.mypaymentprovider.com" "${WHITELABEL}" 2>/dev/null | tail -n 1 | sed 's/.*Created file "\(.*\)".*/\1/g')"
                unzip "${DEST_FILE}" -d /tmp/source
                SRC_PATH="/tmp/source"
                DB_FIELD_NAME=$(ls $SRC_PATH/upload/image/catalog/)
            fi
            cp -rf $SRC_PATH/upload/admin/* /opt/bitnami/opencart/admin/
            cp -rf $SRC_PATH/upload/catalog/* /opt/bitnami/opencart/catalog/
            cp -rf $SRC_PATH/upload/image/catalog/* /opt/bitnami/opencart/image/catalog/
            cp -rf $SRC_PATH/upload/system/library/* /opt/bitnami/opencart/system/library/
            # Tell Opencart about the extension
            OC_EXT_ID=$(mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO \`oc_extension_install\`  (extension_download_id, filename, date_added) VALUES (0,'opencart-${DB_FIELD_NAME}-local-dev',NOW()); SELECT LAST_INSERT_ID();" | tail -n1)
            # Add all Extension files to Opencart DB
            for file_path in $(find $SRC_PATH/upload -not -path '*/\.*' -printf "%P\n"); do
                mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO \`oc_extension_path\`  SET \`extension_install_id\`  = '${OC_EXT_ID}', \`path\`  = '${file_path}', \`date_added\`  = NOW();"
            done
            # Register Extension
            LOCAL_XML=$(cat $SRC_PATH/install.xml)
            mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO \`oc_modification\` SET \`extension_install_id\` = '${OC_EXT_ID}', \`name\` = '${DB_FIELD_NAME}', \`code\` = '${DB_FIELD_NAME}', \`author\` = '${DB_FIELD_NAME}', \`version\` = 'local-dev', \`link\` = '', \`xml\` = '${LOCAL_XML}', \`status\` = '1', \`date_added\` = NOW();"
        fi
    fi

    # Enable Extension
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO \`oc_extension\` (type, code) VALUES ('payment','${DB_FIELD_NAME}_creditcard');"
    
    echo -e "Configuring Extensions"

    # Configure Payment Providers
    mysql -B -h mariadb -u root bitnami_opencart -e "UPDATE oc_user_group SET permission = '{\"access\":[\"catalog\\/attribute\",\"catalog\\/attribute_group\",\"catalog\\/category\",\"catalog\\/download\",\"catalog\\/filter\",\"catalog\\/information\",\"catalog\\/manufacturer\",\"catalog\\/option\",\"catalog\\/product\",\"catalog\\/recurring\",\"catalog\\/review\",\"common\\/column_left\",\"common\\/developer\",\"common\\/filemanager\",\"common\\/profile\",\"common\\/security\",\"customer\\/custom_field\",\"customer\\/customer\",\"customer\\/customer_approval\",\"customer\\/customer_group\",\"design\\/banner\",\"design\\/layout\",\"design\\/theme\",\"design\\/translation\",\"design\\/seo_url\",\"event\\/statistics\",\"event\\/theme\",\"extension\\/advertise\\/google\",\"extension\\/analytics\\/google\",\"extension\\/captcha\\/basic\",\"extension\\/captcha\\/google\",\"extension\\/dashboard\\/activity\",\"extension\\/dashboard\\/chart\",\"extension\\/dashboard\\/customer\",\"extension\\/dashboard\\/map\",\"extension\\/dashboard\\/online\",\"extension\\/dashboard\\/order\",\"extension\\/dashboard\\/recent\",\"extension\\/dashboard\\/sale\",\"extension\\/extension\\/advertise\",\"extension\\/extension\\/analytics\",\"extension\\/extension\\/captcha\",\"extension\\/extension\\/dashboard\",\"extension\\/extension\\/feed\",\"extension\\/extension\\/fraud\",\"extension\\/extension\\/menu\",\"extension\\/extension\\/module\",\"extension\\/extension\\/payment\",\"extension\\/extension\\/report\",\"extension\\/extension\\/shipping\",\"extension\\/extension\\/theme\",\"extension\\/extension\\/total\",\"extension\\/feed\\/google_base\",\"extension\\/feed\\/google_sitemap\",\"extension\\/feed\\/openbaypro\",\"extension\\/fraud\\/fraudlabspro\",\"extension\\/fraud\\/ip\",\"extension\\/fraud\\/maxmind\",\"extension\\/marketing\\/remarketing\",\"extension\\/module\\/account\",\"extension\\/module\\/amazon_login\",\"extension\\/module\\/amazon_pay\",\"extension\\/module\\/banner\",\"extension\\/module\\/bestseller\",\"extension\\/module\\/carousel\",\"extension\\/module\\/category\",\"extension\\/module\\/divido_calculator\",\"extension\\/module\\/ebay_listing\",\"extension\\/module\\/featured\",\"extension\\/module\\/filter\",\"extension\\/module\\/google_hangouts\",\"extension\\/module\\/html\",\"extension\\/module\\/information\",\"extension\\/module\\/klarna_checkout_module\",\"extension\\/module\\/latest\",\"extension\\/module\\/laybuy_layout\",\"extension\\/module\\/pilibaba_button\",\"extension\\/module\\/pp_button\",\"extension\\/module\\/pp_login\",\"extension\\/module\\/sagepay_direct_cards\",\"extension\\/module\\/sagepay_server_cards\",\"extension\\/module\\/slideshow\",\"extension\\/module\\/special\",\"extension\\/module\\/store\",\"extension\\/openbay\\/amazon\",\"extension\\/openbay\\/amazon_listing\",\"extension\\/openbay\\/amazon_product\",\"extension\\/openbay\\/amazonus\",\"extension\\/openbay\\/amazonus_listing\",\"extension\\/openbay\\/amazonus_product\",\"extension\\/openbay\\/ebay\",\"extension\\/openbay\\/ebay_profile\",\"extension\\/openbay\\/ebay_template\",\"extension\\/openbay\\/etsy\",\"extension\\/openbay\\/etsy_product\",\"extension\\/openbay\\/etsy_shipping\",\"extension\\/openbay\\/etsy_shop\",\"extension\\/openbay\\/fba\",\"extension\\/payment\\/amazon_login_pay\",\"extension\\/payment\\/authorizenet_aim\",\"extension\\/payment\\/authorizenet_sim\",\"extension\\/payment\\/bank_transfer\",\"extension\\/payment\\/bluepay_hosted\",\"extension\\/payment\\/bluepay_redirect\",\"extension\\/payment\\/cardconnect\",\"extension\\/payment\\/cardinity\",\"extension\\/payment\\/cheque\",\"extension\\/payment\\/cod\",\"extension\\/payment\\/divido\",\"extension\\/payment\\/eway\",\"extension\\/payment\\/firstdata\",\"extension\\/payment\\/firstdata_remote\",\"extension\\/payment\\/free_checkout\",\"extension\\/payment\\/g2apay\",\"extension\\/payment\\/globalpay\",\"extension\\/payment\\/globalpay_remote\",\"extension\\/payment\\/klarna_account\",\"extension\\/payment\\/klarna_checkout\",\"extension\\/payment\\/klarna_invoice\",\"extension\\/payment\\/laybuy\",\"extension\\/payment\\/liqpay\",\"extension\\/payment\\/nochex\",\"extension\\/payment\\/paymate\",\"extension\\/payment\\/paypoint\",\"extension\\/payment\\/payza\",\"extension\\/payment\\/perpetual_payments\",\"extension\\/payment\\/pilibaba\",\"extension\\/payment\\/pp_express\",\"extension\\/payment\\/pp_payflow\",\"extension\\/payment\\/pp_payflow_iframe\",\"extension\\/payment\\/pp_pro\",\"extension\\/payment\\/pp_pro_iframe\",\"extension\\/payment\\/pp_standard\",\"extension\\/payment\\/realex\",\"extension\\/payment\\/realex_remote\",\"extension\\/payment\\/sagepay_direct\",\"extension\\/payment\\/sagepay_server\",\"extension\\/payment\\/sagepay_us\",\"extension\\/payment\\/securetrading_pp\",\"extension\\/payment\\/securetrading_ws\",\"extension\\/payment\\/skrill\",\"extension\\/payment\\/twocheckout\",\"extension\\/payment\\/web_payment_software\",\"extension\\/payment\\/worldpay\",\"extension\\/module\\/pp_braintree_button\",\"extension\\/payment\\/pp_braintree\",\"extension\\/report\\/customer_activity\",\"extension\\/report\\/customer_order\",\"extension\\/report\\/customer_reward\",\"extension\\/report\\/customer_search\",\"extension\\/report\\/customer_transaction\",\"extension\\/report\\/marketing\",\"extension\\/report\\/product_purchased\",\"extension\\/report\\/product_viewed\",\"extension\\/report\\/sale_coupon\",\"extension\\/report\\/sale_order\",\"extension\\/report\\/sale_return\",\"extension\\/report\\/sale_shipping\",\"extension\\/report\\/sale_tax\",\"extension\\/shipping\\/auspost\",\"extension\\/shipping\\/ec_ship\",\"extension\\/shipping\\/fedex\",\"extension\\/shipping\\/flat\",\"extension\\/shipping\\/free\",\"extension\\/shipping\\/item\",\"extension\\/shipping\\/parcelforce_48\",\"extension\\/shipping\\/pickup\",\"extension\\/shipping\\/royal_mail\",\"extension\\/shipping\\/ups\",\"extension\\/shipping\\/usps\",\"extension\\/shipping\\/weight\",\"extension\\/theme\\/default\",\"extension\\/total\\/coupon\",\"extension\\/total\\/credit\",\"extension\\/total\\/handling\",\"extension\\/total\\/klarna_fee\",\"extension\\/total\\/low_order_fee\",\"extension\\/total\\/reward\",\"extension\\/total\\/shipping\",\"extension\\/total\\/sub_total\",\"extension\\/total\\/tax\",\"extension\\/total\\/total\",\"extension\\/total\\/voucher\",\"localisation\\/country\",\"localisation\\/currency\",\"localisation\\/geo_zone\",\"localisation\\/language\",\"localisation\\/length_class\",\"localisation\\/location\",\"localisation\\/order_status\",\"localisation\\/return_action\",\"localisation\\/return_reason\",\"localisation\\/return_status\",\"localisation\\/stock_status\",\"localisation\\/tax_class\",\"localisation\\/tax_rate\",\"localisation\\/weight_class\",\"localisation\\/zone\",\"mail\\/affiliate\",\"mail\\/customer\",\"mail\\/forgotten\",\"mail\\/return\",\"mail\\/reward\",\"mail\\/transaction\",\"marketing\\/contact\",\"marketing\\/coupon\",\"marketing\\/marketing\",\"marketplace\\/api\",\"marketplace\\/event\",\"marketplace\\/extension\",\"marketplace\\/install\",\"marketplace\\/installer\",\"marketplace\\/marketplace\",\"marketplace\\/modification\",\"marketplace\\/openbay\",\"report\\/online\",\"report\\/report\",\"report\\/statistics\",\"sale\\/order\",\"sale\\/recurring\",\"sale\\/return\",\"sale\\/voucher\",\"sale\\/voucher_theme\",\"setting\\/setting\",\"setting\\/store\",\"startup\\/error\",\"startup\\/event\",\"startup\\/login\",\"startup\\/permission\",\"startup\\/router\",\"startup\\/sass\",\"startup\\/startup\",\"tool\\/backup\",\"tool\\/log\",\"tool\\/upload\",\"user\\/api\",\"user\\/user\",\"user\\/user_permission\",\"extension\\/payment\\/${DB_FIELD_NAME}_creditcard\"],\"modify\":[\"catalog\\/attribute\",\"catalog\\/attribute_group\",\"catalog\\/category\",\"catalog\\/download\",\"catalog\\/filter\",\"catalog\\/information\",\"catalog\\/manufacturer\",\"catalog\\/option\",\"catalog\\/product\",\"catalog\\/recurring\",\"catalog\\/review\",\"common\\/column_left\",\"common\\/developer\",\"common\\/filemanager\",\"common\\/profile\",\"common\\/security\",\"customer\\/custom_field\",\"customer\\/customer\",\"customer\\/customer_approval\",\"customer\\/customer_group\",\"design\\/banner\",\"design\\/layout\",\"design\\/theme\",\"design\\/translation\",\"design\\/seo_url\",\"event\\/statistics\",\"event\\/theme\",\"extension\\/advertise\\/google\",\"extension\\/analytics\\/google\",\"extension\\/captcha\\/basic\",\"extension\\/captcha\\/google\",\"extension\\/dashboard\\/activity\",\"extension\\/dashboard\\/chart\",\"extension\\/dashboard\\/customer\",\"extension\\/dashboard\\/map\",\"extension\\/dashboard\\/online\",\"extension\\/dashboard\\/order\",\"extension\\/dashboard\\/recent\",\"extension\\/dashboard\\/sale\",\"extension\\/extension\\/advertise\",\"extension\\/extension\\/analytics\",\"extension\\/extension\\/captcha\",\"extension\\/extension\\/dashboard\",\"extension\\/extension\\/feed\",\"extension\\/extension\\/fraud\",\"extension\\/extension\\/menu\",\"extension\\/extension\\/module\",\"extension\\/extension\\/payment\",\"extension\\/extension\\/report\",\"extension\\/extension\\/shipping\",\"extension\\/extension\\/theme\",\"extension\\/extension\\/total\",\"extension\\/feed\\/google_base\",\"extension\\/feed\\/google_sitemap\",\"extension\\/feed\\/openbaypro\",\"extension\\/fraud\\/fraudlabspro\",\"extension\\/fraud\\/ip\",\"extension\\/fraud\\/maxmind\",\"extension\\/marketing\\/remarketing\",\"extension\\/module\\/account\",\"extension\\/module\\/amazon_login\",\"extension\\/module\\/amazon_pay\",\"extension\\/module\\/banner\",\"extension\\/module\\/bestseller\",\"extension\\/module\\/carousel\",\"extension\\/module\\/category\",\"extension\\/module\\/divido_calculator\",\"extension\\/module\\/ebay_listing\",\"extension\\/module\\/featured\",\"extension\\/module\\/filter\",\"extension\\/module\\/google_hangouts\",\"extension\\/module\\/html\",\"extension\\/module\\/information\",\"extension\\/module\\/klarna_checkout_module\",\"extension\\/module\\/latest\",\"extension\\/module\\/laybuy_layout\",\"extension\\/module\\/pilibaba_button\",\"extension\\/module\\/pp_button\",\"extension\\/module\\/pp_login\",\"extension\\/module\\/sagepay_direct_cards\",\"extension\\/module\\/sagepay_server_cards\",\"extension\\/module\\/slideshow\",\"extension\\/module\\/special\",\"extension\\/module\\/store\",\"extension\\/openbay\\/amazon\",\"extension\\/openbay\\/amazon_listing\",\"extension\\/openbay\\/amazon_product\",\"extension\\/openbay\\/amazonus\",\"extension\\/openbay\\/amazonus_listing\",\"extension\\/openbay\\/amazonus_product\",\"extension\\/openbay\\/ebay\",\"extension\\/openbay\\/ebay_profile\",\"extension\\/openbay\\/ebay_template\",\"extension\\/openbay\\/etsy\",\"extension\\/openbay\\/etsy_product\",\"extension\\/openbay\\/etsy_shipping\",\"extension\\/openbay\\/etsy_shop\",\"extension\\/openbay\\/fba\",\"extension\\/payment\\/amazon_login_pay\",\"extension\\/payment\\/authorizenet_aim\",\"extension\\/payment\\/authorizenet_sim\",\"extension\\/payment\\/bank_transfer\",\"extension\\/payment\\/bluepay_hosted\",\"extension\\/payment\\/bluepay_redirect\",\"extension\\/payment\\/cardconnect\",\"extension\\/payment\\/cardinity\",\"extension\\/payment\\/cheque\",\"extension\\/payment\\/cod\",\"extension\\/payment\\/divido\",\"extension\\/payment\\/eway\",\"extension\\/payment\\/firstdata\",\"extension\\/payment\\/firstdata_remote\",\"extension\\/payment\\/free_checkout\",\"extension\\/payment\\/g2apay\",\"extension\\/payment\\/globalpay\",\"extension\\/payment\\/globalpay_remote\",\"extension\\/payment\\/klarna_account\",\"extension\\/payment\\/klarna_checkout\",\"extension\\/payment\\/klarna_invoice\",\"extension\\/payment\\/laybuy\",\"extension\\/payment\\/liqpay\",\"extension\\/payment\\/nochex\",\"extension\\/payment\\/paymate\",\"extension\\/payment\\/paypoint\",\"extension\\/payment\\/payza\",\"extension\\/payment\\/perpetual_payments\",\"extension\\/payment\\/pilibaba\",\"extension\\/payment\\/pp_express\",\"extension\\/payment\\/pp_payflow\",\"extension\\/payment\\/pp_payflow_iframe\",\"extension\\/payment\\/pp_pro\",\"extension\\/payment\\/pp_pro_iframe\",\"extension\\/payment\\/pp_standard\",\"extension\\/payment\\/realex\",\"extension\\/payment\\/realex_remote\",\"extension\\/payment\\/sagepay_direct\",\"extension\\/payment\\/sagepay_server\",\"extension\\/payment\\/sagepay_us\",\"extension\\/payment\\/securetrading_pp\",\"extension\\/payment\\/securetrading_ws\",\"extension\\/payment\\/skrill\",\"extension\\/payment\\/twocheckout\",\"extension\\/payment\\/web_payment_software\",\"extension\\/payment\\/worldpay\",\"extension\\/module\\/pp_braintree_button\",\"extension\\/payment\\/pp_braintree\",\"extension\\/report\\/customer_activity\",\"extension\\/report\\/customer_order\",\"extension\\/report\\/customer_reward\",\"extension\\/report\\/customer_search\",\"extension\\/report\\/customer_transaction\",\"extension\\/report\\/marketing\",\"extension\\/report\\/product_purchased\",\"extension\\/report\\/product_viewed\",\"extension\\/report\\/sale_coupon\",\"extension\\/report\\/sale_order\",\"extension\\/report\\/sale_return\",\"extension\\/report\\/sale_shipping\",\"extension\\/report\\/sale_tax\",\"extension\\/shipping\\/auspost\",\"extension\\/shipping\\/ec_ship\",\"extension\\/shipping\\/fedex\",\"extension\\/shipping\\/flat\",\"extension\\/shipping\\/free\",\"extension\\/shipping\\/item\",\"extension\\/shipping\\/parcelforce_48\",\"extension\\/shipping\\/pickup\",\"extension\\/shipping\\/royal_mail\",\"extension\\/shipping\\/ups\",\"extension\\/shipping\\/usps\",\"extension\\/shipping\\/weight\",\"extension\\/theme\\/default\",\"extension\\/total\\/coupon\",\"extension\\/total\\/credit\",\"extension\\/total\\/handling\",\"extension\\/total\\/klarna_fee\",\"extension\\/total\\/low_order_fee\",\"extension\\/total\\/reward\",\"extension\\/total\\/shipping\",\"extension\\/total\\/sub_total\",\"extension\\/total\\/tax\",\"extension\\/total\\/total\",\"extension\\/total\\/voucher\",\"localisation\\/country\",\"localisation\\/currency\",\"localisation\\/geo_zone\",\"localisation\\/language\",\"localisation\\/length_class\",\"localisation\\/location\",\"localisation\\/order_status\",\"localisation\\/return_action\",\"localisation\\/return_reason\",\"localisation\\/return_status\",\"localisation\\/stock_status\",\"localisation\\/tax_class\",\"localisation\\/tax_rate\",\"localisation\\/weight_class\",\"localisation\\/zone\",\"mail\\/affiliate\",\"mail\\/customer\",\"mail\\/forgotten\",\"mail\\/return\",\"mail\\/reward\",\"mail\\/transaction\",\"marketing\\/contact\",\"marketing\\/coupon\",\"marketing\\/marketing\",\"marketplace\\/event\",\"marketplace\\/api\",\"marketplace\\/extension\",\"marketplace\\/install\",\"marketplace\\/installer\",\"marketplace\\/marketplace\",\"marketplace\\/modification\",\"marketplace\\/openbay\",\"report\\/online\",\"report\\/report\",\"report\\/statistics\",\"sale\\/order\",\"sale\\/recurring\",\"sale\\/return\",\"sale\\/voucher\",\"sale\\/voucher_theme\",\"setting\\/setting\",\"setting\\/store\",\"startup\\/error\",\"startup\\/event\",\"startup\\/login\",\"startup\\/permission\",\"startup\\/router\",\"startup\\/sass\",\"startup\\/startup\",\"tool\\/backup\",\"tool\\/log\",\"tool\\/upload\",\"user\\/api\",\"user\\/user\",\"user\\/user_permission\",\"extension\\/payment\\/${DB_FIELD_NAME}_creditcard\"]}' WHERE user_group_id = '1';"
    mysql -B -h mariadb -u root bitnami_opencart -e "DELETE FROM oc_setting WHERE store_id = '0' AND \`code\` = 'payment_${DB_FIELD_NAME}_creditcard';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_status', \`value\` = '1', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_title', \`value\` = '{\"en\":\"Credit Card\"}', serialized = '1';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_sort_order', \`value\` = '1', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_api_host', \`value\` = '${SHOP_PGC_URL}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_status_cc', \`value\` = '${SHOP_PGC_CC_ENABLED}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_title_cc', \`value\` = 'Credit Card', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_user_cc', \`value\` = '${SHOP_PGC_USER}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_password_cc', \`value\` = '${SHOP_PGC_PASSWORD}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_key_cc', \`value\` = '${SHOP_PGC_API_KEY}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_secret_cc', \`value\` = '${SHOP_PGC_SECRET}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_method_cc', \`value\` = '${SHOP_PGC_CC_MODE}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_seamless_cc', \`value\` = '${SHOP_PGC_CC_SEAMLESS}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_integration_key_cc', \`value\` = '${SHOP_PGC_INTEGRATION_KEY}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_status_visa', \`value\` = '${SHOP_PGC_CC_VISA}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_title_visa', \`value\` = 'Visa', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_user_visa', \`value\` = '${SHOP_PGC_USER}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_password_visa', \`value\` = '${SHOP_PGC_PASSWORD}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_key_visa', \`value\` = '${SHOP_PGC_API_KEY}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_secret_visa', \`value\` = '${SHOP_PGC_SECRET}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_method_visa', \`value\` = '${SHOP_PGC_CC_VISA_MODE}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_seamless_visa', \`value\` = '${SHOP_PGC_CC_VISA_SEAMLESS}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_integration_key_visa', \`value\` = '${SHOP_PGC_INTEGRATION_KEY}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_status_mastercard', \`value\` = '${SHOP_PGC_CC_MASTERCARD}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_title_mastercard', \`value\` = 'MasterCard', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_user_mastercard', \`value\` = '${SHOP_PGC_USER}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_password_mastercard', \`value\` = '${SHOP_PGC_PASSWORD}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_key_mastercard', \`value\` = '${SHOP_PGC_API_KEY}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_secret_mastercard', \`value\` = '${SHOP_PGC_SECRET}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_method_mastercard', \`value\` = '${SHOP_PGC_CC_MASTERCARD_MODE}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_seamless_mastercard', \`value\` = '${SHOP_PGC_CC_MASTERCARD_SEAMLESS}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_integration_key_mastercard', \`value\` = '${SHOP_PGC_INTEGRATION_KEY}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_status_amex', \`value\` = '${SHOP_PGC_CC_AMEX}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_title_amex', \`value\` = 'Amex', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_user_amex', \`value\` = '${SHOP_PGC_USER}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_password_amex', \`value\` = '${SHOP_PGC_PASSWORD}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_key_amex', \`value\` = '${SHOP_PGC_API_KEY}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_secret_amex', \`value\` = '${SHOP_PGC_SECRET}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_method_amex', \`value\` = '${SHOP_PGC_CC_AMEX_MODE}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_seamless_amex', \`value\` = '${SHOP_PGC_CC_AMEX_SEAMLESS}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_integration_key_amex', \`value\` = '${SHOP_PGC_INTEGRATION_KEY}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_status_diners', \`value\` = '${SHOP_PGC_CC_DINERS}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_title_diners', \`value\` = 'Diners', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_user_diners', \`value\` = '${SHOP_PGC_USER}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_password_diners', \`value\` = '${SHOP_PGC_PASSWORD}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_key_diners', \`value\` = '${SHOP_PGC_API_KEY}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_secret_diners', \`value\` = '${SHOP_PGC_SECRET}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_method_diners', \`value\` = '${SHOP_PGC_CC_DINERS_MODE}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_seamless_diners', \`value\` = '${SHOP_PGC_CC_DINERS_SEAMLESS}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_integration_key_diners', \`value\` = '${SHOP_PGC_INTEGRATION_KEY}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_status_jcb', \`value\` = '${SHOP_PGC_CC_JCB}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_title_jcb', \`value\` = 'JCB', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_user_jcb', \`value\` = '${SHOP_PGC_USER}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_password_jcb', \`value\` = '${SHOP_PGC_PASSWORD}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_key_jcb', \`value\` = '${SHOP_PGC_API_KEY}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_secret_jcb', \`value\` = '${SHOP_PGC_SECRET}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_method_jcb', \`value\` = '${SHOP_PGC_CC_JCB_MODE}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_seamless_jcb', \`value\` = '${SHOP_PGC_CC_JCB_SEAMLESS}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_integration_key_jcb', \`value\` = '${SHOP_PGC_INTEGRATION_KEY}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_status_discover', \`value\` = '${SHOP_PGC_CC_DISCOVER}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_title_discover', \`value\` = 'Discover', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_user_discover', \`value\` = '${SHOP_PGC_USER}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_password_discover', \`value\` = '${SHOP_PGC_PASSWORD}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_key_discover', \`value\` = '${SHOP_PGC_API_KEY}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_secret_discover', \`value\` = '${SHOP_PGC_SECRET}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_method_discover', \`value\` = '${SHOP_PGC_CC_DISCOVER_MODE}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_seamless_discover', \`value\` = '${SHOP_PGC_CC_DISCOVER_SEAMLESS}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_integration_key_discover', \`value\` = '${SHOP_PGC_INTEGRATION_KEY}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_status_unionpay', \`value\` = '${SHOP_PGC_CC_UNIONPAY}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_title_unionpay', \`value\` = 'UnionPay', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_user_unionpay', \`value\` = '${SHOP_PGC_USER}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_password_unionpay', \`value\` = '${SHOP_PGC_PASSWORD}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_key_unionpay', \`value\` = '${SHOP_PGC_API_KEY}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_secret_unionpay', \`value\` = '${SHOP_PGC_SECRET}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_method_unionpay', \`value\` = '${SHOP_PGC_CC_UNIONPAY_MODE}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_seamless_unionpay', \`value\` = '${SHOP_PGC_CC_UNIONPAY_SEAMLESS}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_integration_key_unionpay', \`value\` = '${SHOP_PGC_INTEGRATION_KEY}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_status_maestro', \`value\` = '${SHOP_PGC_CC_MAESTRO}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_title_maestro', \`value\` = 'Maestro', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_user_maestro', \`value\` = '${SHOP_PGC_USER}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_password_maestro', \`value\` = '${SHOP_PGC_PASSWORD}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_key_maestro', \`value\` = '${SHOP_PGC_API_KEY}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_api_secret_maestro', \`value\` = '${SHOP_PGC_SECRET}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_method_maestro', \`value\` = '${SHOP_PGC_CC_MAESTRO_MODE}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_seamless_maestro', \`value\` = '${SHOP_PGC_CC_MAESTRO_SEAMLESS}', serialized = '0';"
    mysql -B -h mariadb -u root bitnami_opencart -e "INSERT INTO oc_setting SET store_id = '0', \`code\` = 'payment_${DB_FIELD_NAME}_creditcard', \`key\` = 'payment_${DB_FIELD_NAME}_creditcard_cc_integration_key_maestro', \`value\` = '${SHOP_PGC_INTEGRATION_KEY}', serialized = '0';"

    echo -e "Setup Complete! You can access the instance at: http://${OPENCART_HOST}"

    touch /setup_complete

    if [ $PRECONFIGURE ]; then
        echo -e "Prepare for Pre-Configured build"
        unlink /opt/bitnami/opencart/config.php
        unlink /opt/bitnami/opencart/admin/view/stylesheet/bootstrap.css
        unlink /opt/bitnami/opencart/admin/config.php
        unlink /opt/bitnami/opencart/image
        unlink /opt/bitnami/opencart/system/storage
        mkdir /opt/bitnami/opencart/image
        mkdir /opt/bitnami/opencart/system/storage
        cp /bitnami/opencart/admin/config.php /opt/bitnami/opencart/admin/config.php
        cp /bitnami/opencart/admin/view/stylesheet/bootstrap.css /opt/bitnami/opencart/admin/view/stylesheet/bootstrap.css
        cp /bitnami/opencart/config.php /opt/bitnami/opencart/config.php
        cp -rf /bitnami/opencart/image/* /opt/bitnami/opencart/image/
        mkdir /opt/bitnami/storage
        cp -rf /bitnami/opencart/system/storage/* /opt/bitnami/storage/
        mkdir /opt/bitnami/opencart/system/storage/logs
        chown -R bitnami:daemon /opt/bitnami/opencart
        chmod -R 775 /opt/bitnami/opencart
        chmod -R 777 /opt/bitnami/storage/
        chmod -R 777 /opt/bitnami/opencart/system/storage
        sed -i "s#'/bitnami#'/opt/bitnami#g" /opt/bitnami/opencart/config.php /opt/bitnami/opencart/admin/config.php
        sed -i "s#http://#https://#g" /opt/bitnami/opencart/config.php /opt/bitnami/opencart/admin/config.php
        sed -i "s#define('DIR_STORAGE', '/opt/bitnami/opencart/system/storage/');#define('DIR_STORAGE', '/opt/bitnami/storage/');#g" /opt/bitnami/opencart/config.php /opt/bitnami/opencart/admin/config.php

        kill 1
    else 
        find /opt -name "config.php" -exec sed -i "s#https://#http://#g" {} \;
        # Keep script Running
        trap : TERM INT; (while true; do sleep 1m; done) & wait
    fi

else
    if [ ! -d "/bitnami/opencart" ]; then
        ln -s /opt/bitnami/opencart /bitnami/opencart
    fi

    # Keep script Running
    trap : TERM INT; (while true; do sleep 1m; done) & wait

fi
