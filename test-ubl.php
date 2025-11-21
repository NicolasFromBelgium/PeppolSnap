<?php
require 'vendor/autoload.php';

$address = new NumNum\UBL\Address();
$address->setPostalCode('1000');
$address->setCityName('Brussels');
$address->setCountrySubdivisionCode('BE');

echo "Address created successfully with basic methods:\n";
var_dump($address);
