import { Component, OnInit } from '@angular/core';
import { MenuService, MenuItem } from '../menu.service';
import { CartService } from '../cart.service';
import { CommonModule } from '@angular/common';
import { MaterialModule } from '../material.module';

@Component({
  selector: 'app-menu-list',
  templateUrl: './menu-list.html',
  styleUrls: ['./menu-list.scss'],
  standalone: true,
  imports: [CommonModule, MaterialModule]
})
export class MenuListComponent implements OnInit {

  menuItems: MenuItem[] = [];

  constructor(private menuService: MenuService, private cartService: CartService) { }

  ngOnInit(): void {
    this.menuService.getMenuItems().subscribe(data => {
      this.menuItems = data;
    });
  }

  addToCart(menuItem: MenuItem) {
    this.cartService.addToCart(menuItem);
  }
}
