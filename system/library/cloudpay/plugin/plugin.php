<?php

class CloudPayPlugin
{
    public function getVersion()
    {
        return '1.0.0';
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
            'credit_cards' => self::getCreditCards(),
        ];
    }

    public function getCreditCards()
    {
        return [
            'cc' => 'Credit Card',
            // 'visa' => 'Visa',
            // 'mastercard' => 'MasterCard',
            // 'amex' => 'Amex',
            // 'diners' => 'Diners',
            // 'jcb' => 'JCB',
            // 'discover' => 'Discover',
            // 'unionpay' => 'UnionPay',
            // 'maestro' => 'Maestro',
            // 'uatp' => 'UATP',
        ];
    }
}
