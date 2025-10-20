package com.example.orderservice;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class OrderService {

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private MenuServiceFeignClient menuServiceFeignClient;

    public List<Order> getAllOrders() {
        return orderRepository.findAll();
    }

    public Order getOrderById(Long id) {
        return orderRepository.findById(id).orElse(null);
    }

    public List<Order> getOrdersByUserId(Long userId) {
        return orderRepository.findByUserId(userId);
    }

    public Order createOrder(Order order) {
        double totalPrice = 0.0;
        for (OrderItem orderItem : order.getOrderItems()) {
            MenuItem menuItem = menuServiceFeignClient.getMenuItemById(orderItem.getMenuItemId());
            totalPrice += menuItem.getPrice() * orderItem.getQuantity();
        }
        order.setTotalPrice(totalPrice);
        return orderRepository.save(order);
    }
}
