import ballerina/http;
import ballerina/test;
import ballerinax/mysql;
import ballerina/uuid;

// Initialize HTTP client for API testing
final http:Client clientEp = check new ("http://localhost:8080/v1");

// Initialize test database client
final mysql:Client testDbClient = check new (
    host = dbHost,
    user = dbUser,
    password = dbPassword,
    database = dbName,
    port = dbPort
);

@test:BeforeSuite
function setupTestData() returns error? {
    // Insert test pizza data
    _ = check testDbClient->execute(`
        INSERT INTO pizzas (id, name, description, base_price, toppings) 
        VALUES 
        ('p1', 'Margherita', 'Classic tomato and cheese', 10.99, '["cheese", "tomato"]'),
        ('p2', 'Pepperoni', 'Spicy pepperoni pizza', 12.99, '["cheese", "pepperoni"]')
    `);
}

@test:AfterSuite
function cleanupTestData() returns error? {
    _ = check testDbClient->execute(`DELETE FROM order_pizzas`);
    _ = check testDbClient->execute(`DELETE FROM orders`);
    _ = check testDbClient->execute(`DELETE FROM pizzas`);
}

// Test Scenario 1.1: Get all pizzas (Happy Path)
@test:Config {}
function testGetPizzas() returns error? {
    Pizza[] pizzas = check clientEp->/pizzas;
    
    test:assertEquals(pizzas.length(), 2, "Should return exactly 2 pizzas");
    test:assertEquals(pizzas[0].name, "Margherita", "First pizza should be Margherita");
    test:assertEquals(pizzas[0].basePrice, 10.99d, "Margherita price should be 10.99");
}

// Test Scenario 2.1: Create new order (Happy Path)
@test:Config {
    dependsOn: [testGetPizzas]
}
function testCreateOrder() returns error? {
    OrderRequest orderRequest = {
        customerId: "cust123",
        pizzas: [
            {
                pizzaId: "p1",
                quantity: 2,
                customizations: ["extra_cheese"]
            }
        ]
    };

    Order newOrder = check clientEp->/orders.post(orderRequest);
    
    test:assertTrue(newOrder.id.length() > 0, "Order ID should be generated");
    test:assertEquals(newOrder.status, "PENDING", "Initial order status should be PENDING");
    test:assertEquals(newOrder.customerId, "cust123", "Customer ID should match request");
}

// Test Scenario 3.1: Get orders with and without customerId
@test:Config {
    dependsOn: [testCreateOrder]
}
function testGetOrders() returns error? {
    // Test without customerId
    Order[] allOrders = check clientEp->/orders;
    test:assertTrue(allOrders.length() >= 1, "Should return at least one order");

    // Test with customerId
    Order[] customerOrders = check clientEp->/orders(customerId = "cust123");
    test:assertTrue(customerOrders.length() >= 1, "Should return at least one order for customer");
    test:assertEquals(customerOrders[0].customerId, "cust123", "Should only return orders for specified customer");
}

// Test Scenario 4.1: Get specific order by ID (Happy Path)
@test:Config {
    dependsOn: [testCreateOrder]
}
function testGetOrderById() returns error? {
    // First create an order to get a known ID
    OrderRequest orderRequest = {
        customerId: "cust123",
        pizzas: [{pizzaId: "p1", quantity: 1, customizations: []}]
    };
    Order createdOrder = check clientEp->/orders.post(orderRequest);
    
    // Now retrieve the order by ID
    Order retrievedOrder = check clientEp->/orders/[createdOrder.id];
    test:assertEquals(retrievedOrder.id, createdOrder.id, "Retrieved order ID should match");
    test:assertEquals(retrievedOrder.status, "PENDING", "Retrieved order status should be PENDING");
}

// Test Scenario 4.2: Get non-existent order (Error Path)
@test:Config {}
function testGetNonExistentOrder() returns error? {
    string nonExistentId = uuid:createType1AsString();
    Order|error result = clientEp->/orders/[nonExistentId];
    test:assertTrue(result is error, "Should return an error for non-existent order");
    if result is error {
        test:assertEquals(result.message(), "Order not found", "Should return 'Order not found' error");
    }
}

// Test Scenario 5.1: Update order status (Happy Path)
@test:Config {
    dependsOn: [testCreateOrder]
}
function testUpdateOrderStatus() returns error? {
    // First create an order
    OrderRequest orderRequest = {
        customerId: "cust123",
        pizzas: [{pizzaId: "p1", quantity: 1, customizations: []}]
    };
    Order createdOrder = check clientEp->/orders.post(orderRequest);
    
    // Update the order status
    OrderUpdate updateRequest = {
        status: "PREPARING"
    };
    Order updatedOrder = check clientEp->/orders/[createdOrder.id].patch(updateRequest);
    
    test:assertEquals(updatedOrder.status, "PREPARING", "Order status should be updated to PREPARING");
    test:assertEquals(updatedOrder.id, createdOrder.id, "Order ID should remain unchanged");
}

// Test Scenario 5.2: Update non-existent order (Error Path)
@test:Config {}
function testUpdateNonExistentOrder() returns error? {
    string nonExistentId = uuid:createType1AsString();
    OrderUpdate updateRequest = {
        status: "PREPARING"
    };
    
    Order|error result = clientEp->/orders/[nonExistentId].patch(updateRequest);
    test:assertTrue(result is error, "Should return an error for non-existent order");
    if result is error {
        test:assertEquals(result.message(), "Order not found", "Should return 'Order not found' error");
    }
}