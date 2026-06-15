<?php

namespace App\Exceptions;

use RuntimeException;

class ApiException extends RuntimeException
{
    public function __construct(
        string $message,
        public string $errorCode,
        public int $statusCode,
        public array $errors = [],
    ) {
        parent::__construct($message);
    }
}
