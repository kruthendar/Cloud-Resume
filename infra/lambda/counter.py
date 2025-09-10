import os, json, boto3

TABLE = os.environ["TABLE_NAME"]
PARTITION_KEY = os.environ.get("PARTITION_KEY", "pk")
PARTITION_VALUE = os.environ.get("PARTITION_VALUE", "visitors")

dynamodb = boto3.client("dynamodb")

ALLOWED_ORIGIN = "http://cloud-resume-kruthendar.s3-website-us-east-1.amazonaws.com"

def handler(event, context):
    # Atomically: visit_count = visit_count + 1
    resp = dynamodb.update_item(
        TableName=TABLE,
        Key={PARTITION_KEY: {"S": PARTITION_VALUE}},
        UpdateExpression="ADD visit_count :inc",
        ExpressionAttributeValues={":inc": {"N": "1"}},
        ReturnValues="UPDATED_NEW"
    )
    count = int(resp["Attributes"]["visit_count"]["N"])
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
            "Access-Control-Allow-Methods": "GET,OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type"
        },
        "body": json.dumps({"count": count})
    }
