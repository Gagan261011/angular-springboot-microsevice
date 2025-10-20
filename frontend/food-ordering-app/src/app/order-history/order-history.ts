import { Component, OnInit } from '@angular/core';
import { OrderService, Order } from '../order.service';
import { CommonModule } from '@angular/common';
import { MaterialModule } from '../material.module';

@Component({
  selector: 'app-order-history',
  templateUrl: './order-history.html',
  styleUrls: ['./order-history.scss'],
  standalone: true,
  imports: [CommonModule, MaterialModule]
})
export class OrderHistoryComponent implements OnInit {

  orders: Order[] = [];

  constructor(private orderService: OrderService) { }

  ngOnInit(): void {
    this.orderService.getOrdersByUserId(1).subscribe(data => { // Hardcoded user ID
      this.orders = data;
    });
  }
}
