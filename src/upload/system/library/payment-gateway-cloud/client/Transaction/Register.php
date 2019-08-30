<?php

namespace PaymentGatewayCloud\Client\Transaction;

use PaymentGatewayCloud\Client\Transaction\Base\AbstractTransaction;
use PaymentGatewayCloud\Client\Transaction\Base\AddToCustomerProfileInterface;
use PaymentGatewayCloud\Client\Transaction\Base\AddToCustomerProfileTrait;
use PaymentGatewayCloud\Client\Transaction\Base\OffsiteInterface;
use PaymentGatewayCloud\Client\Transaction\Base\OffsiteTrait;
use PaymentGatewayCloud\Client\Transaction\Base\ScheduleInterface;
use PaymentGatewayCloud\Client\Transaction\Base\ScheduleTrait;

/**
 * Register: Register the customer's payment data for recurring charges.
 *
 * The registered customer payment data will be available for recurring transaction without user interaction.
 *
 * @package PaymentGatewayCloud\Client\Transaction
 */
class Register extends AbstractTransaction implements OffsiteInterface, ScheduleInterface, AddToCustomerProfileInterface {
    use OffsiteTrait;
    use ScheduleTrait;
    use AddToCustomerProfileTrait;
}
