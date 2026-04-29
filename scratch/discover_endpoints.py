import http.client
import json

conn = http.client.HTTPSConnection("api.gold-api.com")
headers = { 'x-api-key': "544786918e979e7739e8d3059dd38285c4020709f158a2df2b171d7515987c98" }

endpoints = ["/ohlc/XAU", "/history/XAU", "/prices/XAU", "/chart/XAU"]

for ep in endpoints:
    conn.request("GET", ep, headers=headers)
    res = conn.getresponse()
    print(f"Endpoint {ep}: {res.status} {res.reason}")
    print(res.read().decode("utf-8")[:100])
    print("-" * 20)
