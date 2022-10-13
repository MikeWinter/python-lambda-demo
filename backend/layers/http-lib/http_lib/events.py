from typing import Mapping, Sequence, Text, TypedDict


class HttpRequestEvent(TypedDict, total=False):
    cookies: Sequence[Text]
    headers: Mapping[Text, Text]
    queryStringParameters: Mapping[Text, Text]
    body: Text
    pathParameters: Mapping[Text, Text]
    isBase64Encoded: bool


class HttpResponseEvent(TypedDict, total=False):
    statusCode: int
    headers: Mapping[Text, Text]
    body: Text
    isBase64Encoded: bool
