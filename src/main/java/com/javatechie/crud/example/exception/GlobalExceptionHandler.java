package com.javatechie.crud.example.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.HashMap;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, Object>> handleIllegalArgument(IllegalArgumentException ex) {
        Map<String, Object> body = new HashMap<>();
        Map<String, String> errorDetails = new HashMap<>();
        errorDetails.put("code", "BAD_REQUEST");
        errorDetails.put("message", ex.getMessage());
        body.put("error", errorDetails);
        return new ResponseEntity<>(body, HttpStatus.BAD_REQUEST);
    }
}
