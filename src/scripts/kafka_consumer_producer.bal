import ballerina/lang.value;
import ballerinax/kafka;

configurable string groupId = "order-consumers";
configurable string orders = "orders";
configurable string paymentSuccessOrders = "payment-success-orders";
configurable decimal pollingInterval = 1;
configurable string kafkaEndpoint = kafka:DEFAULT_URL;

type Order readonly & record {|
    int id;
    string desc;
    PaymentStatus paymentStatus;
|};

enum PaymentStatus {
    SUCCESS,
    FAIL
}

final kafka:ConsumerConfiguration consumerConfigs = {
    groupId: groupId,
    topics: [orders],
    offsetReset: kafka:OFFSET_RESET_EARLIEST,
    pollingInterval: pollingInterval
};

service on new kafka:Listener(kafkaEndpoint, consumerConfigs) {
    private final kafka:Producer orderProducer;

    function init() returns error? {
        self.orderProducer = check new (kafkaEndpoint);
    }

    remote function onConsumerRecord(kafka:ConsumerRecord[] records) returns error? {
        check from kafka:ConsumerRecord {value} in records
            let string orderString = check string:fromBytes(value)
            let Order 'order = check value:fromJsonStringWithType(orderString)
            where 'order.paymentStatus == SUCCESS
            do {
                check self.orderProducer->send({
                    topic: paymentSuccessOrders,
                    value: 'order.toString().toBytes()
                });
            };
    }
}
