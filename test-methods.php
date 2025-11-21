<?php
require 'vendor/autoload.php';

$reflection = new ReflectionClass('NumNum\UBL\Address');
$methods = $reflection->getMethods(ReflectionMethod::IS_PUBLIC);

echo "Available public methods on Address:\n";
foreach ($methods as $method) {
    echo $method->getName() . "\n";
}
