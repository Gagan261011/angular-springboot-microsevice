import { Component, OnInit } from '@angular/core';
import { CartService, CartItem } from '../cart.service';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { MaterialModule } from '../material.module';

@Component({
  selector: 'app-cart',
  templateUrl: './cart.html',
  styleUrls: ['./cart.scss'],
  standalone: true,
  imports: [CommonModule, MaterialModule]
})
export class CartComponent implements OnInit {

  items: CartItem[] = [];

  constructor(private cartService: CartService, private router: Router) { }

  ngOnInit(): void {
    this.items = this.cartService.getItems();
  }

  clearCart() {
    this.items = this.cartService.clearCart();
  }

  placeOrder() {
    this.router.navigate(['/order']);
  }
}
