import { Routes } from '@angular/router';
import { HomeComponent } from './home/home';
import { MenuListComponent } from './menu-list/menu-list';
import { CartComponent } from './cart/cart';
import { OrderPlacementComponent } from './order-placement/order-placement';
import { OrderHistoryComponent } from './order-history/order-history';

export const routes: Routes = [
  { path: '', component: HomeComponent },
  { path: 'menu', component: MenuListComponent },
  { path: 'cart', component: CartComponent },
  { path: 'order', component: OrderPlacementComponent },
  { path: 'history', component: OrderHistoryComponent },
];
