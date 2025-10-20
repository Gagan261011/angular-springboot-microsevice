package com.example.orderservice;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/orders")
public class OrderController {

    @Autowired
    private OrderService orderService;

    @GetMapping
    public List<Order> getAllOrders() {
        return orderService.getAllOrders();
    }

    @GetMapping("/{id}")
    public Order getOrderById(@PathVariable Long id) {
        return orderService.getOrderById(id);
    }

    @GetMapping("/user/{userId}")
    public List<Order> getOrdersByUserId(@PathVariable Long userId) {
        return orderService.getOrdersByUserId(userId);
    }

    @PostMapping
    public Order createOrder(@RequestBody OrderRequestDTO orderRequestDTO) {
        Order order = new Order();
        order.setUserId(orderRequestDTO.getUserId());
        List<OrderItem> orderItems = orderRequestDTO.getOrderItems().stream()
                .map(cartItemDTO -> {
                    OrderItem orderItem = new OrderItem();
                    orderItem.setMenuItemId(cartItemDTO.getMenuItem().getId());
                    orderItem.setQuantity(cartItemDTO.getQuantity());
                    return orderItem;
                })
                .collect(Collectors.toList());
        order.setOrderItems(orderItems);
        return orderService.createOrder(order);
    }
}
