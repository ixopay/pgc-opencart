<?php

namespace PaymentGatewayCloud\Client\Transaction;

use PaymentGatewayCloud\Client\Transaction\Base\AbstractTransactionWithReference;
use PaymentGatewayCloud\Client\Transaction\Base\AmountableInterface;
use PaymentGatewayCloud\Client\Transaction\Base\AmountableTrait;
use PaymentGatewayCloud\Client\Transaction\Base\ItemsInterface;
use PaymentGatewayCloud\Client\Transaction\Base\ItemsTrait;

/**
 * Capture: Charge a previously preauthorized transaction.
 *
 * @package PaymentGatewayCloud\Client\Transaction
 */
class Capture extends AbstractTransactionWithReference implements AmountableInterface, ItemsInterface {
    use AmountableTrait;
    use ItemsTrait;
}
