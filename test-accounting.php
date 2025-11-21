<?php
require 'vendor/autoload.php';

$party = new NumNum\UBL\Party();
$party->setName('Test Company');
$party->setEndpointId('0088:BE123', '0088');

$address = new NumNum\UBL\Address();
$address->setStreetName('Test Street');
$address->setPostalZone('1000');
$address->setCityName('Brussels');
$party->setPostalAddress($address);

$accountingParty = new NumNum\UBL\AccountingParty();
$accountingParty->setParty($party);

echo "AccountingParty created successfully:\n";
var_dump($accountingParty);
