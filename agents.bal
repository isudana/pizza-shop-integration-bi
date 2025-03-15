import ballerinax/ai.agent;

final agent:AzureOpenAiModel _orderManagementAgentModel = check new (serviceUrl, apiKey, deploymentId, apiVersion);
final agent:Agent _orderManagementAgentAgent = check new (systemPrompt = {role: "Order Management Assistant", instructions: string `You are a pizza order management assistant, designed to guide cashiers through each step of the order management process, asking relevant questions to ensure orders are handled accurately and efficiently.`}, model = _orderManagementAgentModel, tools = [getPizzas, createOrder, getOrders, getOrder, updateOrder]);
