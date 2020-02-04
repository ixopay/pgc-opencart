FROM bitnami/opencart:3

EXPOSE 80

VOLUME /bitnami
VOLUME /source
VOLUME /dist

ENV ALLOW_EMPTY_PASSWORD="no" \
    BITNAMI_APP_NAME="opencart" \
    BITNAMI_IMAGE_VERSION="3.0.3-2-debian-9-r183" \
    MARIADB_HOST="mariadb" \
    MARIADB_PORT_NUMBER="3306" \
    MARIADB_ROOT_PASSWORD="" \
    MARIADB_ROOT_USER="root" \
    MYSQL_CLIENT_CREATE_DATABASE_NAME="" \
    MYSQL_CLIENT_CREATE_DATABASE_PASSWORD="" \
    MYSQL_CLIENT_CREATE_DATABASE_PRIVILEGES="ALL" \
    MYSQL_CLIENT_CREATE_DATABASE_USER="" \
    OPENCART_DATABASE_NAME="bitnami_opencart" \
    OPENCART_DATABASE_PASSWORD="" \
    OPENCART_DATABASE_USER="bn_opencart" \
    OPENCART_EMAIL="user@example.com" \
    OPENCART_HOST="127.0.0.1" \
    OPENCART_HTTP_TIMEOUT="120" \
    OPENCART_PASSWORD="bitnami1" \
    REPOSITORY="https://github.com/user/repo" \
    OPENCART_USERNAME="user" \
    PATH="/opt/bitnami/apache/bin:/opt/bitnami/php/bin:/opt/bitnami/php/sbin:/opt/bitnami/mysql/bin:$PATH" \
    SMTP_HOST="" \
    SMTP_PASSWORD="" \
    SMTP_PORT="" \
    SMTP_PROTOCOL="" \
    SMTP_USER="" \
    PRECONFIGURE="" \
    SHOP_PGC_URL="sandbox" \
    SHOP_PGC_USER="test-user" \
    SHOP_PGC_PASSWORD="test-pass" \
    SHOP_PGC_API_KEY="test-key" \
    SHOP_PGC_SECRET="test-secret" \
    SHOP_PGC_INTEGRATION_KEY="test-int-key" \
    SHOP_PGC_CC_ENABLED="1" \
    SHOP_PGC_CC_MODE="debit" \
    SHOP_PGC_CC_SEAMLESS="0" \
    SHOP_PGC_CC_AMEX="1" \
    SHOP_PGC_CC_AMEX_MODE="debit" \
    SHOP_PGC_CC_AMEX_SEAMLESS="1" \
    SHOP_PGC_CC_DINERS="0" \
    SHOP_PGC_CC_DINERS_MODE="debit" \
    SHOP_PGC_CC_DINERS_SEAMLESS="0" \
    SHOP_PGC_CC_DISCOVER="0" \
    SHOP_PGC_CC_DISCOVER_MODE="debit" \
    SHOP_PGC_CC_DISCOVER_SEAMLESS="0" \
    SHOP_PGC_CC_JCB="0" \
    SHOP_PGC_CC_JCB_MODE="debit" \
    SHOP_PGC_CC_JCB_SEAMLESS="0" \
    SHOP_PGC_CC_MAESTRO="0" \
    SHOP_PGC_CC_MAESTRO_MODE="debit" \
    SHOP_PGC_CC_MAESTRO_SEAMLESS="0" \
    SHOP_PGC_CC_MASTERCARD="0" \
    SHOP_PGC_CC_MASTERCARD_MODE="debit" \
    SHOP_PGC_CC_MASTERCARD_SEAMLESS="0" \
    SHOP_PGC_CC_UNIOPNPAY="0" \
    SHOP_PGC_CC_UNIONPAY_MODE="debit" \
    SHOP_PGC_CC_UNIOPNPAY_SEAMLESS="0" \
    SHOP_PGC_CC_VISA="0" \
    SHOP_PGC_CC_VISA_MODE="debit" \
    SHOP_PGC_CC_VISA_SEAMLESS="0"

RUN apt-get update && apt-get install -y \
  git \
  unzip \
  && apt-get autoclean

COPY start.sh /start.sh

ENTRYPOINT ["/start.sh"]
