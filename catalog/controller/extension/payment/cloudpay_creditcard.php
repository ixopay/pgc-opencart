<?php

include_once(DIR_SYSTEM . 'library/cloudpay/autoload.php');

use CloudPay\Client\Client;
use CloudPay\Client\Data\Customer;
use CloudPay\Client\Transaction\Debit;
use CloudPay\Client\Transaction\Result as TransactionResult;

final class ControllerExtensionPaymentCloudPayCreditCard extends Controller
{
    use CloudPayGateway;

    const PENDING = 1;
    const PROCESSING = 2;
    const CANCELED = 7;
    const FAILED = 10;
    const REFUNDED = 11;
    const REVERSED = 12;
    const PROCESSED = 15;

    private $type = 'creditcard';

    private $prefix = 'payment_cloudpay_';

    public function index($data = null)
    {
        $data['type'] = $this->type;
        $data['action'] = $this->url->link('extension/payment/cloudpay_' . $this->type . '/confirm', '', true);

        $this->load->language('extension/payment/cloudpay');
        $data['loading_text'] = $this->language->get('loading_text');
        $data['button_confirm'] = $this->language->get('button_confirm');

        $creditCards = $this->getCreditCardsPublic();
        $data['credit_cards'] = $creditCards;
        $data['credit_cards_json'] = json_encode($creditCards);

        $year = date('Y');
        $data['months'] = range(1, 12);
        $data['years'] = range($year, $year + 50);

        $orderId = $this->session->data['order_id'];
        $order = $this->model_checkout_order->getOrder($orderId);
        $data['email'] = $order['email'];

        $apiHost = rtrim($this->getConfig('api_host'), '/') . '/';
        $data['api_host'] = $apiHost;

        return $this->load->view('extension/payment/cloudpay', $data);
    }

    public function confirm()
    {
        $this->load->model('checkout/order');
        $this->load->language('extension/payment/cloudpay');

        $orderId = $this->session->data['order_id'];
        $this->model_checkout_order->addOrderHistory($orderId, self::PENDING);

        $order = $this->model_checkout_order->getOrder($orderId);
        $amount = round($order['total'], 2);

        $cardType = $this->request->post['card_type'];

        try {

            $apiHost = rtrim($this->getConfig('api_host'), '/') . '/';
            Client::setApiUrl($apiHost);

            $apiUser = $this->getConfig('api_user');
            $apiPassword = htmlspecialchars_decode($this->getConfig('api_password'));
            $apiKey = $this->getConfig('cc_api_key_' . $cardType);
            $apiSecret = $this->getConfig('cc_api_secret_' . $cardType);
            $client = new Client($apiUser, $apiPassword, $apiKey, $apiSecret);

            $debit = new Debit();

            if ($this->getConfig('cc_seamless_' . $cardType)) {
                $token = (string)$this->request->post['token'];
                if (empty($token)) {
                    die('empty token');
                }
                $debit->setTransactionToken($token);
            }

            $debit->setTransactionId($this->session->data['order_id']);
            $debit->setAmount(number_format($amount, 2, '.', ''));
            $debit->setCurrency($order['currency_code']);

            $customer = new Customer();
            $customer->setFirstName($order['payment_firstname']);
            $customer->setLastName($order['payment_lastname']);
            $customer->setEmail($order['email']);
            $customer->setIpAddress($order['ip']);
            $debit->setCustomer($customer);

            $debit->setSuccessUrl(str_replace('&amp;', '&', $this->url->link('extension/payment/cloudpay_' . $this->type . '/response', ['orderId' => $orderId, 'success' => 1])));
            $debit->setCancelUrl(str_replace('&amp;', '&', $this->url->link('extension/payment/cloudpay_' . $this->type . '/response', ['orderId' => $orderId, 'cancelled' => 1])));
            $debit->setErrorUrl(str_replace('&amp;', '&', $this->url->link('extension/payment/cloudpay_' . $this->type . '/response', ['orderId' => $orderId, 'failed' => 1])));
            $debit->setCallbackUrl(str_replace('&amp;', '&', $this->url->link('extension/payment/cloudpay_' . $this->type . '/callback', 'orderId=' . $orderId, '&cardType=' . $cardType)));

            $paymentResult = $client->debit($debit);
        } catch (\Throwable $e) {
            $this->processFailure($order);
        }

        if ($paymentResult->hasErrors()) {
            $this->processFailure($order);
        }

        if ($paymentResult->isSuccess()) {
            $gatewayReferenceId = $paymentResult->getReferenceId();
            if ($paymentResult->getReturnType() == TransactionResult::RETURN_TYPE_ERROR) {
                $errors = $paymentResult->getErrors();
                $this->processFailure($order);
            } elseif ($paymentResult->getReturnType() == TransactionResult::RETURN_TYPE_REDIRECT) {
                $this->response->redirect($paymentResult->getRedirectUrl());
            } elseif ($paymentResult->getReturnType() == TransactionResult::RETURN_TYPE_PENDING) {
                // payment is pending, wait for callback to complete
            } elseif ($paymentResult->getReturnType() == TransactionResult::RETURN_TYPE_FINISHED) {
                // seamless will finish here
                $this->model_checkout_order->addOrderHistory($orderId, self::PROCESSING, '', false);
                $this->response->redirect($this->url->link('checkout/success'));
                return;
            }
        }

        // nothing happened after successful payment - go back
        $this->response->redirect($this->url->link('checkout/checkout'));
    }

    private function processFailure($order)
    {
        if ($order['order_status_id'] == self::PENDING) {
            $this->model_checkout_order->addOrderHistory($order['order_id'], self::FAILED);
            $this->session->data['error'] = $this->language->get('order_error');
            $this->response->redirect($this->url->link('checkout/checkout'));
        }
    }

    public function response()
    {
        $this->load->model('checkout/order');
        $this->load->language('extension/payment/cloudpay');

        $orderId = isset($_REQUEST['orderId']) ? (int)$_REQUEST['orderId'] : null;
        $order = $this->model_checkout_order->getOrder($orderId);

        if (!$order) {
            $this->session->data['error'] = $this->language->get('order_cancelled');
            $this->response->redirect($this->url->link('checkout/checkout'));
        }

        $cancelled = !empty($_REQUEST['cancelled']);
        if ($cancelled) {
            $this->session->data['error'] = $this->language->get('order_cancelled');
            $this->model_checkout_order->addOrderHistory($orderId, self::CANCELED, '', false);
            $this->response->redirect($this->url->link('checkout/checkout'));
            return;
        }

        $success = !empty($_REQUEST['success']);
        if ($success) {
            $this->model_checkout_order->addOrderHistory($orderId, self::PROCESSING, '', false);
            $this->response->redirect($this->url->link('checkout/success'));
            return;
        }

        $this->session->data['error'] = $this->language->get('order_error');
        $this->model_checkout_order->addOrderHistory($orderId, self::FAILED, '', false);
        $this->response->redirect($this->url->link('checkout/checkout'));
    }

    public function callback()
    {
        $this->load->model('checkout/order');
        $this->load->language('extension/payment/cloudpay');

        $notification = file_get_contents('php://input');

        // $cardType = !empty($_REQUEST['cardType']) ? $_REQUEST['cardType'] : null;
        // $apiUser = $this->getConfig('api_user');
        // $apiPassword = htmlspecialchars_decode($this->getConfig('api_password'));
        // $apiKey = $this->getConfig('cc_api_key_' . $cardType);
        // $apiSecret = $this->getConfig('cc_api_secret_' . $cardType);
        // $client = new Client($apiUser, $apiPassword, $apiKey, $apiSecret);
        //
        // if (empty($_SERVER['HTTP_DATE']) || empty($_SERVER['HTTP_AUTHORIZATION']) ||
        //     $client->validateCallback($notification, $_SERVER['QUERY_STRING'], $_SERVER['HTTP_DATE'], $_SERVER['HTTP_AUTHORIZATION'])
        // ) {
        //     die('invalid callback');
        // }

        $xml = simplexml_load_string($notification);
        $data = json_decode(json_encode($xml), true);

        $orderId = $data['transactionId'];

        if ($data['result'] !== 'OK') {
            $this->model_checkout_order->addOrderHistory($orderId, self::FAILED);
            die('OK');
        }

        switch ($data['transactionType']) {
            case 'CHARGEBACK-REVERSAL':
                $this->model_checkout_order->addOrderHistory($orderId, self::REVERSED);
                break;
            case 'CHARGEBACK':
                $this->model_checkout_order->addOrderHistory($orderId, self::REFUNDED);
                break;
            case 'DEBIT':
                $this->model_checkout_order->addOrderHistory($orderId, self::PROCESSED);
                break;
        }

        die('OK');
    }
}

