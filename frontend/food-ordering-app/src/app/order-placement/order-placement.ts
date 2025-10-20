import { Component, OnInit } from '@angular/core';
import { CartService, CartItem } from '../cart.service';
import { OrderService } from '../order.service';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { MaterialModule } from '../material.module';


@Component({
  selector: 'app-order-placement',
  templateUrl: './order-placement.html',
  styleUrls: ['./order-placement.scss'],
  standalone: true,
  imports: [CommonModule, MaterialModule]
})
export class OrderPlacementComponent implements OnInit {

  items: CartItem[] = [];
  totalPrice = 0;

  constructor(
    private cartService: CartService,
    private orderService: OrderService,
    private router: Router
  ) { }

  ngOnInit(): void {
    this.items = this.cartService.getItems();
    this.totalPrice = this.items.reduce((acc, item) => acc + (item.menuItem.price * item.quantity), 0);
  }

  placeOrder() {
    const order = {
      userId: 1, // Hardcoded user ID
      orderItems: this.items,
      totalPrice: this.totalPrice
    };

    this.orderService.placeOrder(order).subscribe(() => {
      this.cartService.clearCart();
      this.router.navigate(['/history']);
    });
  }
}
