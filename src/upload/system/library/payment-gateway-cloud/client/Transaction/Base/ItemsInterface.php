<?php

namespace PaymentGatewayCloud\Client\Transaction\Base;
use PaymentGatewayCloud\Client\Data\Item;

/**
 * Interface ItemsInterface
 *
 * @package PaymentGatewayCloud\Client\Transaction\Base
 */
interface ItemsInterface {

    /**
     * @param Item[] $items
     * @return void
     */
    public function setItems($items);

    /**
     * @return Item[]
     */
    public function getItems();

    /**
     * @param Item $item
     * @return void
     */
    public function addItem($item);

}
