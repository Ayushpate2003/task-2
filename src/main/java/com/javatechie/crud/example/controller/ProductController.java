package com.javatechie.crud.example.controller;

import com.javatechie.crud.example.entity.Product;
import com.javatechie.crud.example.service.ProductService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
public class ProductController {

    @Autowired
    private ProductService service;

    @Value("${app.version:1.0}")
    private String version;

    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> healthCheck() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "UP");
        response.put("version", version);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/addProduct")
    public Product addProduct(@RequestBody Product product) {
        return service.saveProduct(product);
    }

    @PostMapping("/addProducts")
    public List<Product> addProducts(@RequestBody List<Product> products) {
        return service.saveProducts(products);
    }

    @GetMapping("/products")
    public List<Product> findAllProducts() {
        return service.getProducts();
    }

    @GetMapping("/productById/{id}")
    public Product findProductById(@PathVariable int id) {
        return service.getProductById(id);
    }

    @GetMapping("/product/{name}")
    public Product findProductByName(@PathVariable String name) {
        return service.getProductByName(name);
    }

    @PutMapping("/update")
    public Product updateProduct(@RequestBody Product product) {
        return service.updateProduct(product);
    }

    @DeleteMapping("/delete/{id}")
    public String deleteProduct(@PathVariable int id) {
        return service.deleteProduct(id);
    }

    @GetMapping("/products/search")
    public ResponseEntity<?> searchProducts(
            @RequestParam(value = "q", required = false) String q,
            @RequestParam(value = "page", required = false) Integer page,
            @RequestParam(value = "limit", required = false) Integer limit,
            @RequestParam(value = "maxPrice", required = false) Double maxPrice) {

        // Version 1.0 does not support search
        if ("1.0".equals(version)) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Not Found");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
        }

        // Version 1.1: Basic keyword search
        if ("1.1".equals(version)) {
            if (q == null || q.trim().isEmpty()) {
                return ResponseEntity.ok(new ArrayList<Product>());
            }
            return ResponseEntity.ok(service.searchProductsByName(q));
        }

        // Version 2.0: Search + pagination + price filtering + structured error handling
        if ("2.0".equals(version)) {
            int parsedPage = (page != null) ? page : 1;
            int parsedLimit = (limit != null) ? limit : 10;

            if (parsedPage < 1) {
                throw new IllegalArgumentException("Invalid page parameter. Must be a positive integer.");
            }
            if (parsedLimit < 1) {
                throw new IllegalArgumentException("Invalid limit parameter. Must be a positive integer.");
            }

            // Retrieve all matching products by search or full list
            List<Product> matches = (q != null && !q.trim().isEmpty())
                    ? service.searchProductsByName(q)
                    : service.getProducts();

            // Filter by maximum price if provided
            if (maxPrice != null) {
                matches = matches.stream()
                        .filter(p -> p.getPrice() <= maxPrice)
                        .collect(Collectors.toList());
            }

            // Calculate pagination indexes
            int total = matches.size();
            int startIndex = (parsedPage - 1) * parsedLimit;
            
            List<Product> paginated = new ArrayList<>();
            if (startIndex < total) {
                int endIndex = Math.min(startIndex + parsedLimit, total);
                paginated = matches.subList(startIndex, endIndex);
            }

            // Format paginated response metadata
            Map<String, Object> response = new HashMap<>();
            response.put("data", paginated);

            Map<String, Object> paginationMeta = new HashMap<>();
            paginationMeta.put("total", total);
            paginationMeta.put("page", parsedPage);
            paginationMeta.put("limit", parsedLimit);
            paginationMeta.put("pages", (int) Math.ceil((double) total / parsedLimit));
            response.put("pagination", paginationMeta);

            return ResponseEntity.ok(response);
        }

        Map<String, String> response = new HashMap<>();
        response.put("error", "Unknown version configuration");
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
    }
}
