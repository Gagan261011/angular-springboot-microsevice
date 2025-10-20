import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { CartItem } from './cart.service';

export interface Order {
  id: number;
  userId: number;
  orderItems: CartItem[];
  totalPrice: number;
}

@Injectable({
  providedIn: 'root'
})
export class OrderService {

  private apiUrl = '/api/orders';

  constructor(private http: HttpClient) { }

  placeOrder(order: any): Observable<Order> {
    return this.http.post<Order>(this.apiUrl, order);
  }

  getOrdersByUserId(userId: number): Observable<Order[]> {
    return this.http.get<Order[]>(`${this.apiUrl}/user/${userId}`);
  }
}
