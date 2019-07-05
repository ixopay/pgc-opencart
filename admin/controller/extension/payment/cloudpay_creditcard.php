<?php
include_once(DIR_SYSTEM . 'library/cloudpay/autoload.php');

class ControllerExtensionPaymentCloudPayCreditCard extends Controller
{
    protected $type = 'creditcard';

    protected $prefix = 'payment_cloudpay_';

    protected $default = [
        'status' => 0,
        'title' => 'CloudPay Credit Card',
        'sort_order' => 1,

        'api_host' => '',
        'api_password' => '',
        'api_user' => '',

        /**
         * TODO: load in dynamically
         */
        // 'cc_enabled' => true,
        // 'cc_api_key' => '',
        // 'cc_api_secret' => '',
        // 'cc_integration_key' => '',
        // 'cc_seamless' => false,
    ];

    protected $config_fields = [
        'status',

        'api_host',
        'api_user',
        'api_password',
        'sort_order',

        /**
         * TODO: load in dynamically
         */
        // 'cc_enabled_cc',
        'cc_api_key_cc',
        'cc_api_secret_cc',
        // 'cc_integration_key_cc',
        // 'cc_seamless_cc',
    ];

    protected $multi_lang_fields = [
        'title',
    ];

    protected $mandatory_fields = [
        'status',

        'api_host',
        'api_user',
        'api_password',

        /**
         * TODO: handle those like multi lang fields -> set as mandatory dynamically
         */
        // 'cc_enabled_cc',
        // 'cc_api_key_cc',
        // 'cc_api_secret_cc',
        // 'cc_integration_key_cc',
        // 'cc_seamless_cc',
    ];

    protected $language_fields = [
        'text_enabled',
        'text_disabled',
        'config_status',
        'config_status_desc',
        'config_title',
        'config_title_desc',
        'config_sort_order',
        'config_sort_order_desc',

        'text_credentials',
        'wrong_url_format',
        'config_api_host',
        'config_api_user',
        'config_api_password',

        'config_cc_api_key',
        'config_cc_api_secret',
    ];

    public function index()
    {
        $this->load->language('extension/payment/cloudpay_creditcard');

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

        $basic_data = new CloudPayPlugin();
        // prefix for payment type
        $data['prefix'] = $this->prefix . $this->type . '_';
        $data['type'] = $this->type;

        $data['header'] = $this->load->controller('common/header');
        $data['column_left'] = $this->load->controller('common/column_left');
        $data['footer'] = $this->load->controller('common/footer');

        $data['action'] = $this->url->link('extension/payment/cloudpay_' . $this->type, 'user_token=' . $this->session->data['user_token'], true);
        $data['cancel'] = $this->url->link('marketplace/extension', 'user_token=' . $this->session->data['user_token'] . '&type=payment', true);
        $data['user_token'] = $this->session->data['user_token'];

        $this->load->model('localisation/country');
        $data['countries'] = $this->model_localisation_country->getCountries();
        $this->load->model('localisation/currency');
        $data['currencies'] = $this->model_localisation_currency->getCurrencies();

        $data = array_merge(
            $data,
            $this->createBreadcrumbs(),
            $this->getConfigText(),
            $this->getRequestData(),
            $basic_data->getTemplateData()
        );
        $data = $this->loadConfigBlocks($data);

        $this->response->setOutput($this->load->view('extension/payment/cloudpay', $data));
    }

    protected function createBreadcrumbs()
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
            'href' => $this->url->link('extension/payment/cloudpay_' . $this->type, 'user_token=' . $this->session->data['user_token'], true),
        ];

        return $data;
    }

    protected function getLogger()
    {
        return new Logger($this->config);
    }

    protected function getConfigText()
    {
        return $this->getLanguageFields($this->language_fields);
    }

    protected function getRequestData()
    {
        $data = [];
        foreach ($this->config_fields as $config_field) {
            $data[$config_field] = is_array($this->getConfigVal($config_field)) ? $this->getConfigVal($config_field) : (string)$this->getConfigVal($config_field);
        }
        return $data;
    }

    private function getConfigVal($key)
    {
        $prefix = $this->prefix . $this->type . '_';
        if ($this->config->get($prefix . $key) != null) {
            return $this->config->get($prefix . $key);
        }
        return isset($this->default[$key]) ? $this->default[$key] : null;
    }

    public function loadConfigBlocks($data)
    {
        $data['language_code'] = $this->getActiveLanguageCode();
        $data = array_merge($data, $this->getConfigFields($this->multi_lang_fields, $this->prefix, $this->type, $this->default));
        return $data;
    }

    protected function validate($formFields)
    {
        if (!$this->user->hasPermission('modify', 'extension/payment/cloudpay_' . $this->type)) {
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

    private function getLanguageFields($config_field_texts)
    {
        $data = [];
        foreach ($config_field_texts as $field_text) {
            $data[$field_text] = $this->language->get($field_text);
        }
        return $data;
    }

    public function getConfigFields($fields, $prefix, $type, $default)
    {
        $prefix = $prefix . $type . '_';
        $keys = [];
        foreach ($fields as $field) {
            foreach ($this->getAllLanguagesCodes() as $code) {
                $keys[$field][$code] = $default[$field];
                if (is_array($this->config->get($prefix . $field)) &&
                    array_key_exists($code, $this->config->get($prefix . $field))) {
                    $keys[$field][$code] = $this->config->get($prefix . $field)[$code];
                }
            }
        }
        return $keys;
    }

    /**
     * Get the currently active language code (e.g. en_gb, de_de, ..)
     *
     * @return string
     */
    public function getActiveLanguageCode()
    {
        $this->load->model('localisation/language');
        $available_languages = $this->model_localisation_language->getLanguages();
        $current_language_id = $this->config->get('config_language_id');

        $current_language = array_filter($available_languages, function ($language) use ($current_language_id) {
            return $current_language_id == $language['language_id'];
        });

        return str_replace('-', '_', reset($current_language)['code']);
    }

    /**
     * Get shop language codes
     *
     * @return array
     */
    private function getAllLanguagesCodes()
    {
        $this->load->model('localisation/language');

        $data = [];
        foreach ($this->model_localisation_language->getLanguages() as $language) {
            array_push($data, preg_split('/[-_]/', $language['code'])[0]);
        }
        return $data;
    }
}
