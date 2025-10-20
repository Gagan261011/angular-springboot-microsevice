package com.example.orderservice;

import java.util.List;

public class OrderRequestDTO {
    private Long userId;
    private List<CartItemDTO> orderItems;

    // Getters and Setters
    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public List<CartItemDTO> getOrderItems() {
        return orderItems;
    }

    public void setOrderItems(List<CartItemDTO> orderItems) {
        this.orderItems = orderItems;
    }
}
