<?php
require 'vendor/autoload.php';

$reflection = new ReflectionClass('NumNum\UBL\Party');
$methods = $reflection->getMethods(ReflectionMethod::IS_PUBLIC);

echo "Available public methods on Party:\n";
foreach ($methods as $method) {
    echo $method->getName() . "\n";
}
