<?php


namespace PaymentGatewayCloud\Client\Data\Result;

/**
 * Class ResultData
 *
 * @package PaymentGatewayCloud\Client\Data\Result
 */
abstract class ResultData {

    /**
     * @return array
     */
    abstract public function toArray();

}
