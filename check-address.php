<?php
require 'vendor/autoload.php';

$reflection = new ReflectionClass('NumNum\UBL\Address');
$methods = $reflection->getMethods(ReflectionMethod::IS_PUBLIC);

echo "=== Address Public Methods (v1.3.0) ===\n";
foreach ($methods as $method) {
    echo $method->getName() . "(" . implode(', ', $method->getParameters()) . ")\n";
}
