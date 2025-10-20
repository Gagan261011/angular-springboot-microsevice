import { Injectable } from '@angular/core';
import { MenuItem } from './menu.service';

export interface CartItem {
  menuItem: MenuItem;
  quantity: number;
}

@Injectable({
  providedIn: 'root'
})
export class CartService {

  private items: CartItem[] = [];

  constructor() { }

  addToCart(menuItem: MenuItem) {
    const existingItem = this.items.find(item => item.menuItem.id === menuItem.id);
    if (existingItem) {
      existingItem.quantity++;
    } else {
      this.items.push({ menuItem, quantity: 1 });
    }
  }

  getItems(): CartItem[] {
    return this.items;
  }

  clearCart() {
    this.items = [];
    return this.items;
  }
}
