#!/bin/bash

# API Test Script for Food Ordering Microservices Application
# This script performs comprehensive API tests on all endpoints

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results
PASSED=0
FAILED=0
TOTAL=0

# Configuration
GATEWAY_URL="${GATEWAY_URL:-http://localhost:8080}"
VERBOSE="${VERBOSE:-false}"

# Test report file
REPORT_FILE="api-test-report-$(date +%Y%m%d-%H%M%S).txt"

# Function to log test results
log_test() {
    local message="$1"
    echo "$message" | tee -a "$REPORT_FILE"
}

# Function to perform API test
test_api() {
    local method=$1
    local endpoint=$2
    local expected_status=$3
    local data=$4
    local description=$5

    ((TOTAL++))

    echo -e "${BLUE}Test $TOTAL:${NC} $description"
    log_test "Test $TOTAL: $description"

    local curl_opts="-s -w \n%{http_code} --max-time 15"

    if [ "$VERBOSE" = "true" ]; then
        curl_opts="$curl_opts -v"
    fi

    local response
    local http_code

    if [ "$method" = "GET" ]; then
        response=$(curl $curl_opts "$GATEWAY_URL$endpoint" 2>&1)
    elif [ "$method" = "POST" ]; then
        response=$(curl $curl_opts -X POST -H "Content-Type: application/json" -d "$data" "$GATEWAY_URL$endpoint" 2>&1)
    elif [ "$method" = "PUT" ]; then
        response=$(curl $curl_opts -X PUT -H "Content-Type: application/json" -d "$data" "$GATEWAY_URL$endpoint" 2>&1)
    elif [ "$method" = "DELETE" ]; then
        response=$(curl $curl_opts -X DELETE "$GATEWAY_URL$endpoint" 2>&1)
    fi

    # Extract HTTP code (last line)
    http_code=$(echo "$response" | tail -n 1)
    # Extract body (all lines except last)
    body=$(echo "$response" | head -n -1)

    echo -e "  Method: $method"
    echo -e "  Endpoint: $endpoint"
    echo -e "  Expected Status: $expected_status"
    echo -e "  Actual Status: $http_code"

    log_test "  Method: $method"
    log_test "  Endpoint: $endpoint"
    log_test "  Expected Status: $expected_status"
    log_test "  Actual Status: $http_code"

    if [ "$VERBOSE" = "true" ] || [ "$http_code" != "$expected_status" ]; then
        echo -e "  Response Body:"
        echo "$body" | head -n 20
        log_test "  Response Body: $body"
    fi

    if [ "$http_code" = "$expected_status" ]; then
        echo -e "  Result: ${GREEN}✓ PASSED${NC}"
        log_test "  Result: PASSED"
        ((PASSED++))
    else
        echo -e "  Result: ${RED}✗ FAILED${NC}"
        log_test "  Result: FAILED"
        ((FAILED++))
    fi

    echo ""
    log_test ""

    # Return the response body for chaining tests
    echo "$body"
}

echo "=========================================="
echo "     Food Ordering App - API Tests"
echo "=========================================="
echo ""
log_test "=========================================="
log_test "     Food Ordering App - API Tests"
log_test "=========================================="
log_test "Start Time: $(date)"
log_test ""

echo "Testing API Gateway: $GATEWAY_URL"
echo ""
log_test "Testing API Gateway: $GATEWAY_URL"
log_test ""

# ==========================================
# User Service API Tests
# ==========================================
echo "=========================================="
echo "       User Service API Tests"
echo "=========================================="
echo ""
log_test "=========================================="
log_test "       User Service API Tests"
log_test "=========================================="
log_test ""

# Test 1: Get all users
test_api "GET" "/api/users" "200" "" "Get all users (should return empty array or user list)" > /dev/null

# Test 2: Create a new user
USER_DATA='{"name":"John Doe","email":"john.doe@example.com","phone":"1234567890","address":"123 Main St"}'
create_user_response=$(test_api "POST" "/api/users" "201" "$USER_DATA" "Create a new user")

# Extract user ID if available (assuming JSON response)
USER_ID=$(echo "$create_user_response" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

if [ -n "$USER_ID" ]; then
    echo -e "${GREEN}Created user with ID: $USER_ID${NC}"
    log_test "Created user with ID: $USER_ID"

    # Test 3: Get user by ID
    test_api "GET" "/api/users/$USER_ID" "200" "" "Get user by ID: $USER_ID" > /dev/null

    # Test 4: Update user
    UPDATE_USER_DATA='{"name":"John Doe Updated","email":"john.doe.updated@example.com","phone":"9876543210","address":"456 Oak Ave"}'
    test_api "PUT" "/api/users/$USER_ID" "200" "$UPDATE_USER_DATA" "Update user with ID: $USER_ID" > /dev/null

    # Test 5: Get updated user
    test_api "GET" "/api/users/$USER_ID" "200" "" "Verify user update" > /dev/null
else
    echo -e "${YELLOW}Warning: Could not extract user ID from response${NC}"
    log_test "Warning: Could not extract user ID from response"
fi

# Test 6: Get non-existent user
test_api "GET" "/api/users/99999" "404" "" "Get non-existent user (should return 404)" > /dev/null

# ==========================================
# Menu Service API Tests
# ==========================================
echo "=========================================="
echo "       Menu Service API Tests"
echo "=========================================="
echo ""
log_test "=========================================="
log_test "       Menu Service API Tests"
log_test "=========================================="
log_test ""

# Test 7: Get all menu items
test_api "GET" "/api/menu" "200" "" "Get all menu items" > /dev/null

# Test 8: Create a new menu item
MENU_DATA='{"name":"Margherita Pizza","description":"Classic Italian pizza with tomato and mozzarella","price":12.99,"category":"Pizza","available":true}'
create_menu_response=$(test_api "POST" "/api/menu" "201" "$MENU_DATA" "Create a new menu item")

# Extract menu item ID
MENU_ID=$(echo "$create_menu_response" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

if [ -n "$MENU_ID" ]; then
    echo -e "${GREEN}Created menu item with ID: $MENU_ID${NC}"
    log_test "Created menu item with ID: $MENU_ID"

    # Test 9: Get menu item by ID
    test_api "GET" "/api/menu/$MENU_ID" "200" "" "Get menu item by ID: $MENU_ID" > /dev/null

    # Test 10: Update menu item
    UPDATE_MENU_DATA='{"name":"Margherita Pizza Deluxe","description":"Premium Italian pizza","price":15.99,"category":"Pizza","available":true}'
    test_api "PUT" "/api/menu/$MENU_ID" "200" "$UPDATE_MENU_DATA" "Update menu item with ID: $MENU_ID" > /dev/null

    # Test 11: Get updated menu item
    test_api "GET" "/api/menu/$MENU_ID" "200" "" "Verify menu item update" > /dev/null

    # Test 12: Delete menu item
    test_api "DELETE" "/api/menu/$MENU_ID" "204" "" "Delete menu item with ID: $MENU_ID" > /dev/null

    # Test 13: Verify deletion
    test_api "GET" "/api/menu/$MENU_ID" "404" "" "Verify menu item deletion (should return 404)" > /dev/null
else
    echo -e "${YELLOW}Warning: Could not extract menu ID from response${NC}"
    log_test "Warning: Could not extract menu ID from response"
fi

# Test 14: Get non-existent menu item
test_api "GET" "/api/menu/99999" "404" "" "Get non-existent menu item (should return 404)" > /dev/null

# Test 15: Filter menu by category
test_api "GET" "/api/menu?category=Pizza" "200" "" "Filter menu items by category" > /dev/null

# ==========================================
# Order Service API Tests
# ==========================================
echo "=========================================="
echo "       Order Service API Tests"
echo "=========================================="
echo ""
log_test "=========================================="
log_test "       Order Service API Tests"
log_test "=========================================="
log_test ""

# Test 16: Get all orders
test_api "GET" "/api/orders" "200" "" "Get all orders" > /dev/null

# Test 17: Create a new order (requires valid user and menu items)
if [ -n "$USER_ID" ]; then
    # First, create some menu items for the order
    PIZZA_DATA='{"name":"Pepperoni Pizza","description":"Pizza with pepperoni","price":14.99,"category":"Pizza","available":true}'
    pizza_response=$(test_api "POST" "/api/menu" "201" "$PIZZA_DATA" "Create pizza for order")
    PIZZA_ID=$(echo "$pizza_response" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

    DRINK_DATA='{"name":"Coca Cola","description":"Refreshing drink","price":2.99,"category":"Drinks","available":true}'
    drink_response=$(test_api "POST" "/api/menu" "201" "$DRINK_DATA" "Create drink for order")
    DRINK_ID=$(echo "$drink_response" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

    if [ -n "$PIZZA_ID" ] && [ -n "$DRINK_ID" ]; then
        ORDER_DATA="{\"userId\":$USER_ID,\"items\":[{\"menuItemId\":$PIZZA_ID,\"quantity\":2},{\"menuItemId\":$DRINK_ID,\"quantity\":3}],\"deliveryAddress\":\"123 Main St\",\"status\":\"PENDING\"}"
        create_order_response=$(test_api "POST" "/api/orders" "201" "$ORDER_DATA" "Create a new order")

        # Extract order ID
        ORDER_ID=$(echo "$create_order_response" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

        if [ -n "$ORDER_ID" ]; then
            echo -e "${GREEN}Created order with ID: $ORDER_ID${NC}"
            log_test "Created order with ID: $ORDER_ID"

            # Test 18: Get order by ID
            test_api "GET" "/api/orders/$ORDER_ID" "200" "" "Get order by ID: $ORDER_ID" > /dev/null

            # Test 19: Get orders by user ID
            test_api "GET" "/api/orders/user/$USER_ID" "200" "" "Get all orders for user ID: $USER_ID" > /dev/null

            # Test 20: Update order status
            UPDATE_ORDER_DATA="{\"userId\":$USER_ID,\"items\":[{\"menuItemId\":$PIZZA_ID,\"quantity\":2}],\"deliveryAddress\":\"123 Main St\",\"status\":\"CONFIRMED\"}"
            test_api "PUT" "/api/orders/$ORDER_ID" "200" "$UPDATE_ORDER_DATA" "Update order status to CONFIRMED" > /dev/null

            # Test 21: Cancel order
            CANCEL_ORDER_DATA="{\"userId\":$USER_ID,\"items\":[{\"menuItemId\":$PIZZA_ID,\"quantity\":2}],\"deliveryAddress\":\"123 Main St\",\"status\":\"CANCELLED\"}"
            test_api "PUT" "/api/orders/$ORDER_ID" "200" "$CANCEL_ORDER_DATA" "Cancel order (update status to CANCELLED)" > /dev/null
        fi
    fi
fi

# Test 22: Get non-existent order
test_api "GET" "/api/orders/99999" "404" "" "Get non-existent order (should return 404)" > /dev/null

# Test 23: Get orders for non-existent user
test_api "GET" "/api/orders/user/99999" "200" "" "Get orders for non-existent user (should return empty array)" > /dev/null

# ==========================================
# Integration Tests
# ==========================================
echo "=========================================="
echo "       Integration Tests"
echo "=========================================="
echo ""
log_test "=========================================="
log_test "       Integration Tests"
log_test "=========================================="
log_test ""

# Test 24: Complete order flow
echo -e "${BLUE}Test 24:${NC} Complete order flow (Create User -> Browse Menu -> Place Order)"
log_test "Test 24: Complete order flow"

# Create a new user
FLOW_USER_DATA='{"name":"Jane Smith","email":"jane.smith@example.com","phone":"5551234567","address":"789 Elm St"}'
flow_user_response=$(curl -s -X POST -H "Content-Type: application/json" -d "$FLOW_USER_DATA" "$GATEWAY_URL/api/users" 2>/dev/null)
FLOW_USER_ID=$(echo "$flow_user_response" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

if [ -n "$FLOW_USER_ID" ]; then
    echo -e "  ${GREEN}✓${NC} User created with ID: $FLOW_USER_ID"

    # Browse menu
    menu_items=$(curl -s "$GATEWAY_URL/api/menu" 2>/dev/null)
    if [ -n "$menu_items" ]; then
        echo -e "  ${GREEN}✓${NC} Menu items retrieved"

        # Get first available menu item
        FLOW_MENU_ID=$(echo "$menu_items" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

        if [ -n "$FLOW_MENU_ID" ]; then
            # Place order
            FLOW_ORDER_DATA="{\"userId\":$FLOW_USER_ID,\"items\":[{\"menuItemId\":$FLOW_MENU_ID,\"quantity\":1}],\"deliveryAddress\":\"789 Elm St\",\"status\":\"PENDING\"}"
            flow_order_response=$(curl -s -w "\n%{http_code}" -X POST -H "Content-Type: application/json" -d "$FLOW_ORDER_DATA" "$GATEWAY_URL/api/orders" 2>/dev/null)
            flow_order_code=$(echo "$flow_order_response" | tail -n 1)

            if [ "$flow_order_code" = "201" ]; then
                echo -e "  ${GREEN}✓${NC} Order placed successfully"
                echo -e "  Result: ${GREEN}✓ PASSED${NC}"
                ((PASSED++))
            else
                echo -e "  ${RED}✗${NC} Failed to place order (HTTP $flow_order_code)"
                echo -e "  Result: ${RED}✗ FAILED${NC}"
                ((FAILED++))
            fi
        else
            echo -e "  ${YELLOW}!${NC} No menu items available for order"
            ((FAILED++))
        fi
    else
        echo -e "  ${RED}✗${NC} Failed to retrieve menu items"
        ((FAILED++))
    fi
else
    echo -e "  ${RED}✗${NC} Failed to create user"
    ((FAILED++))
fi

((TOTAL++))
echo ""
log_test ""

# Test 25: Invalid request handling
test_api "POST" "/api/users" "400" '{"invalid":"data"}' "Create user with invalid data (should return 400)" > /dev/null

# Test 26: Unauthorized access (if security is implemented)
test_api "GET" "/api/orders" "200" "" "Access orders without authentication (may return 200 or 401 depending on security config)" > /dev/null

# ==========================================
# Performance Tests (Basic)
# ==========================================
echo "=========================================="
echo "       Basic Performance Tests"
echo "=========================================="
echo ""
log_test "=========================================="
log_test "       Basic Performance Tests"
log_test "=========================================="
log_test ""

# Test 27: Response time test
echo -e "${BLUE}Test 27:${NC} Average response time for GET requests"
log_test "Test 27: Average response time for GET requests"

total_time=0
num_requests=10

for i in $(seq 1 $num_requests); do
    response_time=$(curl -o /dev/null -s -w "%{time_total}" "$GATEWAY_URL/api/menu" 2>/dev/null)
    total_time=$(echo "$total_time + $response_time" | bc)
done

avg_time=$(echo "scale=3; $total_time / $num_requests" | bc)
echo -e "  Average response time: ${avg_time}s (over $num_requests requests)"
log_test "  Average response time: ${avg_time}s (over $num_requests requests)"

if (( $(echo "$avg_time < 1.0" | bc -l) )); then
    echo -e "  Result: ${GREEN}✓ PASSED${NC} (response time under 1 second)"
    log_test "  Result: PASSED"
    ((PASSED++))
else
    echo -e "  Result: ${YELLOW}! WARNING${NC} (response time over 1 second)"
    log_test "  Result: WARNING"
    ((FAILED++))
fi

((TOTAL++))
echo ""
log_test ""

# ==========================================
# Final Report
# ==========================================
echo "=========================================="
echo "           API Test Summary"
echo "=========================================="
echo -e "${GREEN}Passed:${NC}  $PASSED / $TOTAL"
echo -e "${RED}Failed:${NC}  $FAILED / $TOTAL"
echo ""

pass_rate=$(echo "scale=2; $PASSED * 100 / $TOTAL" | bc)
echo "Pass Rate: ${pass_rate}%"
echo ""

log_test "=========================================="
log_test "           API Test Summary"
log_test "=========================================="
log_test "Passed:  $PASSED / $TOTAL"
log_test "Failed:  $FAILED / $TOTAL"
log_test "Pass Rate: ${pass_rate}%"
log_test "End Time: $(date)"

echo "Test report saved to: $REPORT_FILE"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All API tests passed!${NC}"
    echo "The application is ready for deployment."
    exit 0
else
    echo -e "${RED}✗ Some API tests failed!${NC}"
    echo "Please review the failures above before deploying."
    exit 1
fi
