var selectedCard;
var $paymentForm = $('#payment_gateway_cloud_form');
var $paymentFormSubmitButton = $("#payment_gateway_cloud_form_submit");
var $paymentFormCardTypeInput = $('#payment_gateway_cloud_card_type');
var $paymentFormTokenInput = $('#payment_gateway_cloud_token');

$('button[data-card-type]').on('click', function () {
    selectCard($(this).data('cardType'));
});

$paymentFormSubmitButton.on('click', function () {
    submitForm();
});

var selectCard = function (cardType) {
    var card = cards[cardType];
    if (!card) {
        return;
    }
    selectedCard = card;

    /**
     * reset
     */
    paymentGatewayCloudSeamless.reset();
    $paymentFormSubmitButton.prop("disabled", true);

    /**
     * show selection
     */
    $('button[data-card-type]').removeClass('btn-success');
    $('button[data-card-type="' + card.type + '"]').addClass('btn-success');

    /**
     * set form data
     */
    $paymentFormCardTypeInput.val(selectedCard.type);

    /**
     * seamless integration
     */
    if (card.integrationKey) {
        paymentGatewayCloudSeamless.init(
            card.integrationKey,
            function () {
                $paymentFormSubmitButton.prop("disabled", true);
            },
            function () {
                $paymentFormSubmitButton.prop("disabled", false);
            });
        return;
    }

    /**
     * redirect integration
     */
    $paymentFormSubmitButton.prop("disabled", false);
};

var submitForm = function (e) {
    /**
     * seamless integration
     */
    if (selectedCard.integrationKey) {
        paymentGatewayCloudSeamless.submit(
            function (token) {
                $paymentFormTokenInput.val(token);
                $paymentForm.submit();
            },
            function (errors) {
                errors.forEach(function (error) {
                    console.error(error);
                });
            });
        return;
    }
    /**
     * redirect integration
     */
    $paymentForm.submit();
};

/**
 * seamless
 */
var paymentGatewayCloudSeamless = function () {
    var payment;
    var validDetails;
    var validNumber;
    var validCvv;
    var _invalidCallback;
    var _validCallback;
    var $seamlessForm = $('#payment_gateway_cloud_seamless');
    var $seamlessCardHolderInput = $('#payment_gateway_cloud_seamless_card_holder', $seamlessForm);
    var $seamlessEmailInput = $('#payment_gateway_cloud_seamless_email', $seamlessForm);
    var $seamlessExpiryMonthInput = $('#payment_gateway_cloud_seamless_expiry_month', $seamlessForm);
    var $seamlessExpiryYearInput = $('#payment_gateway_cloud_seamless_expiry_year', $seamlessForm);
    var $seamlessCardNumberInput = $('#payment_gateway_cloud_seamless_card_number', $seamlessForm);
    var $seamlessCvvInput = $('#payment_gateway_cloud_seamless_cvv', $seamlessForm);

    var init = function (integrationKey, invalidCallback, validCallback) {
        _invalidCallback = invalidCallback;
        _validCallback = validCallback;

        $seamlessForm.show();
        var style = {
            'border': 'none',
            'height': '32px',
            'padding': '6px 12px',
            'font-size': '14px',
            'color': '#555',
        };
        payment = new PaymentJs("1.2");
        payment.init(integrationKey, $seamlessCardNumberInput.prop('id'), $seamlessCvvInput.prop('id'), function (payment) {
            payment.setNumberStyle(style);
            payment.setCvvStyle(style);
            payment.numberOn('input', function (data) {
                validNumber = data.validNumber;
                validate();
            });
            payment.cvvOn('input', function (data) {
                validCvv = data.validCvv;
                validate();
            });
        });
        $('input, select', $seamlessForm).on('input', validate);
    };

    var validate = function () {
        $('.form-group', $seamlessForm).removeClass('has-error');
        $seamlessCardNumberInput.closest('.form-group').toggleClass('has-error', !validNumber);
        $seamlessCvvInput.closest('.form-group').toggleClass('has-error', !validCvv);
        validDetails = true;
        if (!$seamlessCardHolderInput.val().length) {
            $seamlessCardHolderInput.closest('.form-group').addClass('has-error');
            validDetails = false;
        }
        if (validNumber && validCvv && validDetails) {
            _validCallback.call();
            return;
        }
        _invalidCallback.call();
    };

    var reset = function () {
        $seamlessForm.hide();
    };

    var submit = function (success, error) {
        payment.tokenize(
            {
                card_holder: $seamlessCardHolderInput.val(),
                month: $seamlessExpiryMonthInput.val(),
                year: $seamlessExpiryYearInput.val(),
                email: $seamlessEmailInput.val()
            },
            function (token, cardData) {
                success.call(this, token);
            },
            function (errors) {
                error.call(this, errors);
            }
        );
    };

    return {
        init: init,
        reset: reset,
        submit: submit,
    };
}();

