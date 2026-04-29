import http.client
import json

conn = http.client.HTTPSConnection("api.gold-api.com")
headers = { 'x-api-key': "544786918e979e7739e8d3059dd38285c4020709f158a2df2b171d7515987c98" }
conn.request("GET", "/price/XAU", headers=headers)
res = conn.getresponse()
data = res.read()
print(data.decode("utf-8"))
