# Whitelabel OpenCart Payment Provider Extension

## Requirements

- PHP 7.1+
- [OpenCart 3+ Requirements](https://docs.opencart.com/requirements/)

## Build

* Clone or download the source from this repository.
* Update images in [src/admin/view/image/payment_gateway_cloud](src/upload/admin/view/image/payment_gateway_cloud) and [src/image/catalog/payment_gateway_cloud](src/upload/image/catalog/payment_gateway_cloud).
* Comment/disable adapters in [src/upload/system/library/payment-gateway-cloud/plugin/gateway.php](src/upload/system/library/payment-gateway-cloud/plugin/gateway.php) - see [getCardTypes()](src/upload/system/library/payment-gateway-cloud/plugin/gateway.php#L10) method.
* Copy language files from [src/upload/admin/language/en-gb](src/upload/admin/language/en-gb) and [src/upload/catalog/language/en-gb](src/upload/catalog/language/en-gb) to additional languages folders (ISO 639-1) and update the translations within.
* Run the build script to apply desired branding and create a zip file ready for distribution:
```shell script
php build.php gateway.mypaymentprovider.com "My Payment Provider"
```
- Verify the contents of `build` to make sure they meet desired results.
- Find the newly versioned zip file in the `dist` folder.
- Test by installing the extension in an existing shop installation (see [src/readme.txt](src/readme.txt)).
- Distribute the versioned zip file.

## Provide Updates

- Fetch the updated source from this repository (see [CHANGELOG.md](CHANGELOG.md)).<br>Note: make sure to not overwrite any previous changes you've made for the previous version, or re-apply these changes.
- Run the build script with the same parameters as the first time:
```shell script
php build.php gateway.mypaymentprovider.com "My Payment Provider"
```
- Find the newly versioned zip file in the `dist` folder.
- Test by updating the extension in an existing shop installation (see [src/readme.txt](src/readme.txt)).
- Distribute the newly versioned zip file.
