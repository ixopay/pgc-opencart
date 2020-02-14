# Docker demo & development environment

We supply ready to use Docker environments for plugin development & testing. 

**Warning!** This docker image is dedicated for development & demo usage, we don't recommended to use it in production.

---

## Usage

To quickly spawn a Opencart test shop with a plugin tagged at our Github repository:
Clone our plugin repository and run the following command from the plugin root directory:

```bash
 REPOSITORY="https://github.com/ixopay/pgc-opencart" \
 BRANCH="master" \
 OPENCART_HOST="localhost" \
 OPENCART_USERNAME="dev" \
 OPENCART_PASSWORD="dev" \
  docker-compose -f docker-compose.github.yml up --build --force-recreate --renew-anon-volumes
```

To develop and test plugin changes, you can run the following docker-compose command from the plugin root directory, to start a Opencart shop & initialize a database with a bind mounted version of the plugin. The shop will be accessible via: `http://localhost/admin`.

```bash
 BITNAMI_IMAGE_VERSION="latest" \
 OPENCART_HOST="localhost" \
 OPENCART_USERNAME="dev" \
 OPENCART_PASSWORD="dev" \
  docker-compose up --build --force-recreate --renew-anon-volumes
```

To test a build you generated via build.php run the following command from the plugin root directory:

```bash
 php build.php sandbox.paymentgateway.cloud "My Payment Provider"
 BITNAMI_IMAGE_VERSION="latest" \
 BUILD_ARTIFACT="${PWD}/dist/opencart-my-payment-provider-1.3.1.ocmod.zip" \
 OPENCART_HOST="localhost" \
 OPENCART_USERNAME="dev" \
 OPENCART_PASSWORD="dev" \
  docker-compose up --build --force-recreate --renew-anon-volumes
```

Please note:

- By running the command we always run a complete `--build` for the shop container, `--force-recreate` to delete previous containers and always delete the previous instance's storage volumes via `--renew-anon-volumes`. We don't support to change variables without rebuilding the full container.
- We currently use Bitnami Docker images as base for the environment and add our plugin.
- Further environment variables can be set, please take a look at `docker/Dockerfile` for a complete list.

### Customize Settings

Defaults for the Docker build are configured in the `docker-compose` files. You can either:
 - set variables via environment variable or (like above)
 - persist them in the `environment:` section of the respective docker-compose file.

### Platform credentials

To successfully test a payment flow you will need merchant credentials for the payment platform and set them via the following environment variables:

```bash
 # Base url for payment plaform API
 SHOP_PGC_URL="https://sandbox.paymentgateway.cloud"
 # Credentials for payment platform API
 SHOP_PGC_USER="test-user"
 SHOP_PGC_PASSWORD="test-pass"
 SHOP_PGC_API_KEY="key"
 SHOP_PGC_SECRET="secret"
 SHOP_PGC_INTEGRATION_KEY="int-key"
```

Additional platform specific settings:

```bash
 # Enable or disable payments for specific schemes
 SHOP_PGC_CC_AMEX="True"
 SHOP_PGC_CC_DINERS="True"
 SHOP_PGC_CC_DISCOVER="True"
 SHOP_PGC_CC_JCB="True"
 SHOP_PGC_CC_MAESTRO="True"
 SHOP_PGC_CC_MASTERCARD="True"
 SHOP_PGC_CC_UNIONPAY="True"
 SHOP_PGC_CC_VISA="True"
 # Either use "debit" or "preauthorize" transaction requests
 SHOP_PGC_CC_TYPE="debit"
 SHOP_PGC_CC_TYPE_AMEX="debit"
 SHOP_PGC_CC_TYPE_DINERS="debit"
 SHOP_PGC_CC_TYPE_DISCOVER="debit"
 SHOP_PGC_CC_TYPE_JCB="debit"
 SHOP_PGC_CC_TYPE_MAESTRO="debit"
 SHOP_PGC_CC_TYPE_MASTERCARD="debit"
 SHOP_PGC_CC_TYPE_UNIONPAY="debit"
 SHOP_PGC_CC_TYPE_VISA="debit"
 ```