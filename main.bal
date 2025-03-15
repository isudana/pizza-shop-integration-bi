import ballerina/http;
import ballerina/sql;
import ballerina/uuid;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

final mysql:Client dbClient = check new (
    host = dbHost,
    user = dbUser,
    password = dbPassword,
    database = dbName,
    port = dbPort
);

service /v1 on new http:Listener(8080) {
    resource function get pizzas() returns Pizza[]|error {
        sql:ParameterizedQuery query = `SELECT * FROM pizzas`;
        stream<Pizza, sql:Error?> pizzaStream = dbClient->query(query);
        Pizza[] pizzas = check from Pizza pizza in pizzaStream
            select pizza;
        return pizzas;
    }

    resource function post orders(@http:Payload OrderRequest orderRequest) returns Order|error {
        Order newOrder = {
            id: uuid:createType1AsString(),
            customerId: orderRequest.customerId,
            status: "PENDING",
            totalPrice: 0.0,
            pizzas: orderRequest.pizzas
        };

        sql:ParameterizedQuery query = `INSERT INTO orders (id, customer_id, status, total_price) 
                                      VALUES (${newOrder.id}, ${newOrder.customerId}, ${newOrder.status}, ${newOrder.totalPrice})`;
        _ = check dbClient->execute(query);

        foreach OrderPizza pizza in orderRequest.pizzas {
            sql:ParameterizedQuery pizzaQuery = `INSERT INTO order_pizzas (order_id, pizza_id, quantity) 
                                               VALUES (${newOrder.id}, ${pizza.pizzaId}, ${pizza.quantity})`;
            _ = check dbClient->execute(pizzaQuery);
        }

        return newOrder;
    }

    resource function get orders(string? customerId) returns Order[]|error {
        sql:ParameterizedQuery query;
        if customerId is string {
            query = `SELECT * FROM orders WHERE customer_id = ${customerId}`;
        } else {
            query = `SELECT * FROM orders`;
        }
        stream<Order, sql:Error?> orderStream = dbClient->query(query);
        Order[] orders = check from Order 'order in orderStream
            select 'order;
        return orders;
    }

    resource function get orders/[string orderId]() returns Order|error {
        sql:ParameterizedQuery query = `SELECT * FROM orders WHERE id = ${orderId}`;
        Order? 'order = check dbClient->queryRow(query);
        if 'order is () {
            return error("Order not found");
        }
        return 'order;
    }

    resource function patch orders/[string orderId](@http:Payload OrderUpdate orderUpdate) returns Order|error {
        sql:ParameterizedQuery query = `UPDATE orders SET status = ${orderUpdate.status} WHERE id = ${orderId}`;
        sql:ExecutionResult result = check dbClient->execute(query);
        if result.affectedRowCount == 0 {
            return error("Order not found");
        }

        // Query the updated order
        sql:ParameterizedQuery getQuery = `SELECT * FROM orders WHERE id = ${orderId}`;
        Order? updatedOrder = check dbClient->queryRow(getQuery);
        if updatedOrder is () {
            return error("Order not found after update");
        }
        return updatedOrder;
    }
}