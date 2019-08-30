<?php

namespace PaymentGatewayCloud\Client\CustomerProfile;

use PaymentGatewayCloud\Client\Json\ResponseObject;

/**
 * Class GetProfileResponse
 *
 * @package PaymentGatewayCloud\Client\CustomerProfile
 *
 * @property bool $profileExists
 * @property string $profileGuid
 * @property string $customerIdentification
 * @property string $preferredMethod
 * @property CustomerData $customer
 * @property PaymentInstrument[] $paymentInstruments
 */
class GetProfileResponse extends ResponseObject {

}
