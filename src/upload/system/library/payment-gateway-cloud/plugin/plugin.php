<?php

namespace PaymentGatewayCloud;

final class PaymentGatewayCloudPlugin
{
    public function getVersion()
    {
        return 'X.Y.Z';
    }

    public function getName()
    {
        return 'Payment Gateway Cloud OpenCart Extension';
    }

    public function getShopName()
    {
        return 'OpenCart';
    }

    public function getShopVersion()
    {
        return VERSION;
    }

    public function getTemplateData()
    {
        return [
            'plugin_name' => self::getName(),
            'plugin_version' => self::getVersion(),
        ];
    }
}
