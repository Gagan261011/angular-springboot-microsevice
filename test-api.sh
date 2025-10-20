#!/bin/bash
curl -v localhost:8080/api/menu/items  # Expect JSON: [{"id":1,"name":"Pizza","price":12.99}]
curl -v -X POST localhost:8080/api/orders -H "Content-Type: application/json" -d '{"userId":1,"items":[{"id":1,"qty":2}]}'  # Expect 201 Created
curl -v localhost:8080/api/users/1  # Expect user JSON
