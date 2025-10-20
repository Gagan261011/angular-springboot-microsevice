package com.example.menuservice;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Collections;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class MenuServiceTest {

    @InjectMocks
    private MenuService menuService;

    @Mock
    private MenuItemRepository menuItemRepository;

    @Test
    public void testGetAllMenuItems() {
        MenuItem menuItem = new MenuItem("Pizza", "Delicious pizza", 12.99);
        List<MenuItem> menuItems = Collections.singletonList(menuItem);

        when(menuItemRepository.findAll()).thenReturn(menuItems);

        List<MenuItem> result = menuService.getAllMenuItems();

        assertEquals(1, result.size());
        assertEquals("Pizza", result.get(0).getName());
    }
}
