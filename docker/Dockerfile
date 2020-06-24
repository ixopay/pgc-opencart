FROM bitnami/opencart:3-debian-10

EXPOSE 80

VOLUME /bitnami
VOLUME /source
VOLUME /dist

ENV PRECONFIGURE="" \
    REPOSITORY="https://github.com/user/repo" \
    BRANCH="master" \
    WHITELABEL="" \
    SCHEMA="" \
    MAGENTO_HOST="" \
    DEMO_CUSTOMER_PASSWORD="customer" \
    BUILD_ARTIFACT="undefined" \
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
    SHOP_PGC_CC_UNIONPAY="0" \
    SHOP_PGC_CC_UNIONPAY_MODE="debit" \
    SHOP_PGC_CC_UNIONPAY_SEAMLESS="0" \
    SHOP_PGC_CC_VISA="0" \
    SHOP_PGC_CC_VISA_MODE="debit" \
    SHOP_PGC_CC_VISA_SEAMLESS="0"

RUN apt-get update && apt-get install --no-install-recommends -y \
  git \
  unzip \
  && apt-get autoclean

COPY start.sh /start.sh
COPY whitelabel_vars.php /whitelabel.php

ENTRYPOINT ["/start.sh"]
