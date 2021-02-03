# Docker demo & development environment

We supply ready to use Docker environments for plugin development & testing.

- `docker-compose.yml` Setup Opencart instance and configure Pgc Extension (Testing)
- `docker-compose.dev.yml` Setup Opencart instance with Pgc Extension, but without Configuration (Development)

**Warning!** This docker image is dedicated for development & demo usage, we don't recommended to use it in production.

---

## Usage

Run Development Environment
```
docker-compose -f docker-compose.dev.yml up --force-recreate --renew-anon-volumes

# Reload Extension Source Code in Opencart by flushing the caches:
docker-compose -f docker-compose.dev.yml exec opencart find /opt -name 'cache' -type d -exec rm -rf {}/* \;
docker-compose -f docker-compose.dev.yml exec opencart find /bitnami -name 'cache' -type d -exec rm -rf {}/* \;
```

Run Test Environment
```
docker-compose up --force-recreate --renew-anon-volumes
```


## Configuration

Settings can be supplied as Environment Variables inside the docker-compose file.


| Value                    |           Default            |                       Description                       |
| ------------------------ |:----------------------------:|:-------------------------------------------------------:|
| HTTPS                    |            false             |                  Enable/Disable HTTPS                   |
| REPOSITORY               | https://github.com/user/repo | URL to the Repo where your branded Extension is located |
| BRANCH                   |            master            |        Which Branch to checkout from REPOSITORY         |
| WHITELABEL               |          AwesomePay          |                  Whitelabel Extension                   |
| OPENCART_EMAIL           |       user@example.com       |                   Default Admin Email                   |
| OPENCART_USERNAME        |             user             |                 Default Admin Username                  |
| OPENCART_PASSWORD        |           bitnami1           |                 Default Admin Password                  |
| DEMO_CUSTOMER_PASSWORD   |           customer           |                  Default User Password                  |
| SHOP_PGC_URL             |           sandbox            |                 URL to your Gateway API                 |
| SHOP_PGC_USER            |          test-user           |                    Your Gateway User                    |
| SHOP_PGC_PASSWORD        |          test-pass           |               Your Gateway User Password                |
| SHOP_PGC_API_KEY         |             key              |                  Your Gateway API-Key                   |
| SHOP_PGC_SECRET          |            secret            |                 Your Gateway API-Secret                 |
| SHOP_PGC_INTEGRATION_KEY |           int_key            |              Your Gateway Integration Key               |
| SHOP_PGC_SEAMLESS        |              1               |      Whether to Enable (1) or Disable (0) Seamless      |


### You can also Configure seperate CC Brands with


| Value                        | Default |                   Description                   |
| ---------------------------- |:-------:|:-----------------------------------------------:|
| SHOP_PGC_CC_<BRAND>          |    1    |       Enable (1) or Disable (0) CC Brand        |
| SHOP_PGC_CC_<BRAND>_MODE     |  debit  |              debit / preauthorize               |
| SHOP_PGC_CC_<BRAND>_SEAMLESS |    1    | Enable (1) or Disable (0) Seamless for CC Brand |


#### Available Brands are:

- VISA
- MAESTRO
- AMEX
- DINERS
- DISCOVER
- JCB
- MASTERCARD
- UNIONPAY

## Default Credentials:

### User / Customer

> **Login:** RobertZJohnson@einrot.com
>
> **Password:** customer

### Admin

> **Login:** user
>
> **Password:** bitnami1
