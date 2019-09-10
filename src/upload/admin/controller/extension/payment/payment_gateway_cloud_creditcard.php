<?php

include_once(DIR_SYSTEM . 'library/payment-gateway-cloud/autoload.php');

use PaymentGatewayCloud\PaymentGatewayCloudGateway;
use PaymentGatewayCloud\PaymentGatewayCloudPlugin;

final class ControllerExtensionPaymentPaymentGatewayCloudCreditCard extends Controller
{
    use PaymentGatewayCloudGateway;

    private $type = 'creditcard';

    private $prefix = 'payment_payment_gateway_cloud_';

    private $default = [
        'status' => 0,
        'title' => 'Credit Card',
        'sort_order' => 1,
        'api_host' => '',
    ];

    private $config_fields = [
        'status',
        'api_host',
        'sort_order',
    ];

    private $multi_lang_fields = [
        'title',
    ];

    private $mandatory_fields = [
        'status',
        'api_host',
    ];

    private $language_fields = [
        'text_enabled',
        'text_disabled',
        'config_status',
        'config_status_desc',
        'config_title',
        'config_title_desc',
        'config_sort_order',
        'config_sort_order_desc',

        'text_credentials',
        'config_api_host',
        'config_cc_title',
        'config_cc_api_user',
        'config_cc_api_password',
        'config_cc_api_key',
        'config_cc_api_secret',
        'config_cc_integration_key',
    ];

    public function index()
    {
        $this->load->language('extension/payment/payment_gateway_cloud_creditcard');
        $this->load->model('setting/setting');

        $this->document->setTitle($this->language->get('heading_title'));

        if ($this->request->server['REQUEST_METHOD'] == 'POST') {
            $data['error'] = $this->language->get('error_mandatory_fields');
            if ($this->validate($this->request->post)) {
                $this->model_setting_setting->editSetting($this->prefix . $this->type, $this->request->post);
                $this->session->data['success'] = $this->language->get('text_success');

                $this->response->redirect($this->url->link('marketplace/extension',
                    'user_token=' . $this->session->data['user_token'] . '&type=payment', true));
            }
        }

        $data['prefix'] = $this->prefix . $this->type . '_';
        $data['type'] = $this->type;

        $data['header'] = $this->load->controller('common/header');
        $data['column_left'] = $this->load->controller('common/column_left');
        $data['footer'] = $this->load->controller('common/footer');

        $data['action'] = $this->url->link('extension/payment/payment_gateway_cloud_' . $this->type, 'user_token=' . $this->session->data['user_token'], true);
        $data['cancel'] = $this->url->link('marketplace/extension', 'user_token=' . $this->session->data['user_token'] . '&type=payment', true);
        $data['user_token'] = $this->session->data['user_token'];

        $creditCards = $this->getCreditCards();
        foreach ($creditCards as $creditCard) {
            $this->config_fields[] = 'cc_status_' . $creditCard['type'];
            $this->config_fields[] = 'cc_title_' . $creditCard['type'];
            $this->config_fields[] = 'cc_api_key_' . $creditCard['type'];
            $this->config_fields[] = 'cc_api_secret_' . $creditCard['type'];
            $this->config_fields[] = 'cc_integration_key_' . $creditCard['type'];
            $this->config_fields[] = 'cc_seamless_' . $creditCard['type'];
            $this->mandatory_fields[] = 'cc_status_' . $creditCard['type'];
        }
        $data['credit_cards'] = $creditCards;

        $plugin = new PaymentGatewayCloudPlugin();
        $data = array_merge(
            $data,
            $this->getBreadcrumbData(),
            $this->getLanguageData(),
            $this->getConfigData(),
            $plugin->getTemplateData()
        );

        $data = $this->loadConfigBlocks($data);

        $this->response->setOutput($this->load->view('extension/payment/payment_gateway_cloud', $data));
    }

    private function getBreadcrumbData()
    {
        $data['breadcrumbs'] = [];

        $data['breadcrumbs'][] = [
            'text' => $this->language->get('text_home'),
            'href' => $this->url->link('common/dashboard', 'user_token=' . $this->session->data['user_token'], true),
        ];

        $data['breadcrumbs'][] = [
            'text' => $this->language->get('text_extension'),
            'href' => $this->url->link('marketplace/extension', 'user_token=' . $this->session->data['user_token'] . '&type=payment', true),
        ];

        $data['breadcrumbs'][] = [
            'text' => $this->language->get('heading_title'),
            'href' => $this->url->link('extension/payment/payment_gateway_cloud_' . $this->type, 'user_token=' . $this->session->data['user_token'], true),
        ];

        return $data;
    }

    private function getLanguageData()
    {
        $data = [];
        foreach ($this->language_fields as $field_text) {
            $data[$field_text] = $this->language->get($field_text);
        }
        return $data;
    }

    private function getConfigData()
    {
        $data = [];
        foreach ($this->config_fields as $config_field) {
            $data[$config_field] = is_array($this->getConfig($config_field)) ? $this->getConfig($config_field) : (string)$this->getConfig($config_field);
        }
        return $data;
    }

    private function loadConfigBlocks($data)
    {
        $data = array_merge($data, $this->getConfigFields($this->multi_lang_fields, $this->prefix, $this->type, $this->default));
        return $data;
    }

    private function validate($formFields)
    {
        if (!$this->user->hasPermission('modify', 'extension/payment/payment_gateway_cloud_' . $this->type)) {
            $this->error['warning'] = $this->language->get('error_permission');
        }

        foreach ($this->mandatory_fields as $field) {
            if (!array_key_exists($this->prefix . $this->type . '_' . $field, $formFields) ||
                $formFields[$this->prefix . $this->type . '_' . $field] === '') {
                return false;
            }
        }

        return !$this->error;
    }

    private function getConfigFields($fields, $prefix, $type, $default)
    {
        $this->load->model('localisation/language');

        $language_codes = [];
        foreach ($this->model_localisation_language->getLanguages() as $language) {
            array_push($language_codes, preg_split('/[-_]/', $language['code'])[0]);
        }

        $prefix = $prefix . $type . '_';
        $keys = [];
        foreach ($fields as $field) {
            foreach ($language_codes as $code) {
                $keys[$field][$code] = $default[$field];
                if (is_array($this->config->get($prefix . $field)) &&
                    array_key_exists($code, $this->config->get($prefix . $field))) {
                    $keys[$field][$code] = $this->config->get($prefix . $field)[$code];
                }
            }
        }
        return $keys;
    }
}
