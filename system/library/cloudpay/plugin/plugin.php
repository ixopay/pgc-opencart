<?php

final class CloudPayPlugin
{
    public function getVersion()
    {
        return '1.1.0';
    }

    public function getName()
    {
        return 'CloudPay OpenCart Extension';
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
