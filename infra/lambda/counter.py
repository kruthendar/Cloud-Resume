import os, json, boto3, traceback

TABLE = os.environ.get("TABLE_NAME")
PARTITION_KEY = os.environ.get("PARTITION_KEY", "pk")
PARTITION_VALUE = os.environ.get("PARTITION_VALUE", "visitors")

dynamodb = boto3.client("dynamodb")

def handler(event, context):
    print("DEBUG: Incoming event:", json.dumps(event))  # log entire event
    print("DEBUG: Env TABLE_NAME:", TABLE)

    try:
        resp = dynamodb.update_item(
            TableName=TABLE,
            Key={PARTITION_KEY: {"S": PARTITION_VALUE}},
            UpdateExpression="ADD visit_count :inc",
            ExpressionAttributeValues={":inc": {"N": "1"}},
            ReturnValues="UPDATED_NEW"
        )
        print("DEBUG: DynamoDB response:", resp)

        count = int(resp["Attributes"]["visit_count"]["N"])

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "https://d61lbue2vh6ls.cloudfront.net",
                "Access-Control-Allow-Methods": "GET,OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type",
            },
            "body": json.dumps({"count": count}),
        }

    except Exception as e:
        print("ERROR:", str(e))
        traceback.print_exc()  # full stack trace
        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps({"error": str(e)}),
        }
