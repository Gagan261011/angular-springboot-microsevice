package com.example.orderservice;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Collections;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class OrderServiceTest {

    @InjectMocks
    private OrderService orderService;

    @Mock
    private OrderRepository orderRepository;

    @Mock
    private MenuServiceFeignClient menuServiceFeignClient;

    @Test
    public void testCreateOrder() {
        MenuItem menuItem = new MenuItem(1L, "Pizza", "Delicious pizza", 12.99);
        OrderItem orderItem = new OrderItem(1L, 1, 12.99);
        Order order = new Order(1L, Collections.singletonList(orderItem), 0.0);

        when(menuServiceFeignClient.getMenuItemById(1L)).thenReturn(menuItem);
        when(orderRepository.save(any(Order.class))).thenReturn(order);

        Order result = orderService.createOrder(order);

        assertEquals(12.99, result.getTotalPrice());
    }
}
