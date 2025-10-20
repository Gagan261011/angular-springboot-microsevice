package com.example.orderservice;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

@FeignClient(name = "menu-service")
public interface MenuServiceFeignClient {

    @GetMapping("/api/menu/{id}")
    MenuItem getMenuItemById(@PathVariable Long id);
}
