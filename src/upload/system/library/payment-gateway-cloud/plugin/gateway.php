<?php

namespace PaymentGatewayCloud;

trait PaymentGatewayCloudGateway
{
    /**
     * @return array
     */
    private function getCardTypes()
    {
        /**
         * Comment/disable adapters that are not applicable
         */
        return [
            'cc' => 'Credit Card',
            'visa' => 'Visa',
            'mastercard' => 'MasterCard',
            'amex' => 'Amex',
            'diners' => 'Diners',
            'jcb' => 'JCB',
            'discover' => 'Discover',
            'unionpay' => 'UnionPay',
            'maestro' => 'Maestro',
            // 'uatp' => 'UATP',
        ];
    }

    /**
     * @return array
     */
    private function getMethods()
    {
        return [
            PaymentGatewayCloudPlugin::METHOD_DEBIT,
            PaymentGatewayCloudPlugin::METHOD_PREAUTHORIZE,
        ];
    }

    /**
     * @return array
     */
    private function getCreditCards()
    {
        $cardTypes = $this->getCardTypes();
        $creditCards = [];
        foreach ($cardTypes as $cardType => $cardName) {
            $title = $this->getConfig('cc_title_' . $cardType) ?: $cardName;
            $creditCards[$cardType] = [
                'type' => $cardType,
                'name' => $cardName,
                'status' => $this->getConfig('cc_status_' . $cardType),
                'title' => $title,
                'api_user' => $this->getConfig('cc_api_user_' . $cardType),
                'api_password' => $this->getConfig('cc_api_password_' . $cardType),
                'api_key' => $this->getConfig('cc_api_key_' . $cardType),
                'api_secret' => $this->getConfig('cc_api_secret_' . $cardType),
                'integration_key' => $this->getConfig('cc_integration_key_' . $cardType),
                'seamless' => $this->getConfig('cc_seamless_' . $cardType),
                'method' => $this->getConfig('cc_method_' . $cardType),
            ];
        }
        return $creditCards;
    }

    /**
     *
     */
    private function getCreditCardsPublic()
    {
        $creditCards = $this->getCreditCards();
        $creditCardsPublic = [];
        foreach ($creditCards as $cardType => $creditCard) {
            if (!$creditCard['status']) {
                continue;
            }
            if (empty($creditCard['api_key']) || empty($creditCard['api_secret'])) {
                continue;
            }
            if (!empty($creditCard['seamless']) && empty($creditCard['integration_key'])) {
                continue;
            }
            $creditCardPublic = [
                'type' => $creditCard['type'],
                'name' => $creditCard['name'],
                'title' => $creditCard['title'],
                // 'viewUrl' => $this->url->link('extension/payment/payment_gateway_cloud_' . $this->type . '/creditCardView&cardType=' . $cardType),
            ];
            if (!empty($creditCard['seamless']) && !empty($creditCard['integration_key'])) {
                $creditCardPublic['integrationKey'] = $creditCard['integration_key'];
            }
            $creditCardsPublic[$cardType] = $creditCardPublic;
        }
        return $creditCardsPublic;
    }

    /**
     * @param $key
     * @return mixed
     */
    private function getConfig($key)
    {
        $prefix = $this->prefix . $this->type . '_';
        if ($this->config->get($prefix . $key) != null) {
            return $this->config->get($prefix . $key);
        }
        return isset($this->default[$key]) ? $this->default[$key] : null;
    }
}
