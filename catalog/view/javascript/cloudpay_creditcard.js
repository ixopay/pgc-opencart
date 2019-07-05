$(document).ready(function () {
    // $("#button-confirm").prop("disabled", true);
});



$('#button-confirm').on('click', function () {
    console.log(paymentType);
    if (paymentType === 'creditcard') {
        var form = $('#cloudpay-form');
        form.submit();
    }
});
