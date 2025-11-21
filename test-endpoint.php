<?php
require 'vendor/autoload.php';

$party = new NumNum\UBL\Party();
$party->setEndpointId('0088:BE123456789', '0088');
echo "EndpointId set successfully:\n";
echo "Endpoint ID: " . $party->getEndpointId() . "\n";
