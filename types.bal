type Pizza record {|
    string id;
    string name;
    string description;
    decimal basePrice;
    string[] toppings;
|};

type OrderPizza record {|
    string pizzaId;
    int quantity;
    string[] customizations;
|};

type OrderRequest record {|
    string customerId;
    OrderPizza[] pizzas;
|};

type OrderStatus "PENDING"|"PREPARING"|"OUT_FOR_DELIVERY"|"DELIVERED"|"CANCELLED";

type Order record {|
    string id;
    string customerId;
    OrderStatus status;
    decimal totalPrice;
    OrderPizza[] pizzas;
|};

type OrderUpdate record {|
    OrderStatus status;
|};