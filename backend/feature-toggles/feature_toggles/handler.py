import json

import boto3
from botocore.exceptions import ClientError
from http_lib.events import HttpRequestEvent, HttpResponseEvent

ssm_client = boto3.client('ssm')


def get_toggles(_event: HttpRequestEvent, _context) -> HttpResponseEvent:
    paginator = ssm_client.get_paginator('get_parameters_by_path')
    parameters_iterator = paginator.paginate(Path='/toggles/', Recursive=False)

    all_toggles = dict()
    try:
        for response in parameters_iterator:
            for parameter in response['Parameters']:
                all_toggles[parameter['Name']] = parameter['Value']

        return {
            'body': json.dumps(all_toggles),
        }

    except ClientError:
        return {
            'statusCode': 500,
        }
