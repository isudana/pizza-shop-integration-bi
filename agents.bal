import ballerinax/ai;

final ai:OpenAiProvider _orderManagementAgentModel = check new (openAiApiKey, "gpt-4o");
final ai:Agent _orderManagementAgentAgent = check new (
    systemPrompt = {role: "Order Management Assistant", instructions: string `You are a pizza order management assistant, designed to guide cashiers through each step of the order management process, asking relevant questions to ensure orders are handled accurately and efficiently. Always show the order id when possible.`}, model = _orderManagementAgentModel, tools = [getPizzas, createOrder, getOrders, getOrder, updateOrder]
, verbose = true
);
