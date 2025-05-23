import ballerina/http;
import ballerinax/ai;

final http:Client pizzaClient = check new ("http://localhost:8080/v1");

# Retrieves all available pizzas.
#
# + return - Array of pizzas or error
@ai:AgentTool
@display {
    label: "",
    iconPath: ""
}
isolated function getPizzas() returns Pizza[]|error {
    Pizza[] pizzas = check pizzaClient->/pizzas;
    return pizzas;
}

# Creates a new order.
#
# + orderRequest - The order details
# + return - Created order or error
@ai:AgentTool
@display {
    label: "",
    iconPath: ""
}
isolated function createOrder(OrderRequest orderRequest) returns Order|error {
    Order 'order = check pizzaClient->/orders.post(orderRequest);
    return 'order;
}

# Retrieves all orders with optional customer filter.
#
# + customerName - customer Name to filter orders
# + return - Array of orders or error
@ai:AgentTool
@display {
    label: "",
    iconPath: ""
}
isolated function getOrders(string customerName) returns Order[]|error {
    return pizzaClient->/orders(customerName = customerName);
}

# Retrieves a specific order by ID.
#
# + orderId - ID of the order to retrieve
# + return - Order details or error
@ai:AgentTool
@display {
    label: "",
    iconPath: ""
}
isolated function getOrder(string orderId) returns Order|error {
    Order 'order = check pizzaClient->/orders/[orderId];
    return 'order;
}

# Updates the status of an order.
#
# + orderId - ID of the order to update
# + orderUpdate - New status for the order
# + return - Updated order or error
@ai:AgentTool
@display {
    label: "",
    iconPath: ""
}
isolated function updateOrder(string orderId, OrderUpdate orderUpdate) returns Order|error {
    Order updatedOrder = check pizzaClient->/orders/[orderId].patch(orderUpdate);
    return updatedOrder;
}