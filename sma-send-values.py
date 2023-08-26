#!/usr/bin/env python3

from pymodbus.client import ModbusTcpClient
from influxdb_client import InfluxDBClient, Point


influx_client = InfluxDBClient(
        url='https://eu-central-1-1.aws.cloud2.influxdata.com',
        token='QvdsSkuhCZXkQHAAnxezFO36BrRXYrXQc_JenRK7ckn6I5mQyXbTllTFe-QpxM2HMzZ8D2JFGl0oz8DYOZvYxQ==',
        org='99702231a4477a51')

client = ModbusTcpClient('192.168.178.26',port=502)
client.connect()

def read32(reg,factor=1):
  res = client.read_holding_registers(reg,2,slave=3)
  val = (res.getRegister(0)<<16)+res.getRegister(1)
  if val == 2147483648:
    return None
  return val*factor

total_yield_Wh = read32(30529,1.0)

dc_amperage_1=read32(30769,1/1000)
dc_voltage_1=read32(30771,1/100)
dc_amperage_2=read32(30957,1/1000)
dc_voltage_2=read32(30959,1/100)
temperature_C=read32(34109,1/10)

client.close()

import datetime
print(datetime.datetime.now())

import requests
def send(idx,value):
  if value is None:
    return 0
  url="http://192.168.178.101:8080/json.htm"
  params={
    "type": "command",
    "param": "udevice",
    "idx": idx,
    "svalue": value
  }
  r = requests.get(url,params=params)
  print(r.url,r.status_code)
  return r.status_code

#send(144,total_yield_Wh)
#send(145,temperature_C)
#send(146,dc_amperage_1)
#send(147,dc_voltage_1)
#send(148,dc_amperage_2)
#send(149,dc_voltage_2)

def send_influx_success(self,data):
  print(f"{data}")
def send_influx(table,idx,name,value):
  point=Point(table).tag("idx",idx).tag("name",name).field("value",value)
  with influx_client.write_api(success_callback=send_influx_success) as write_api:
    write_api.write(bucket='oranienbaum-energy', record=[point], content_encoding="identity", content_type="text/plain; charset=utf-8",)
    write_api.close()
def send_influx1(table,idx,name,value):
  url="http://192.168.178.101:8086/write?db=domoticz"
  data="%s,idx=%i,name=%s value=%f" % (table,idx,name,value)
  r = requests.post(url,data=data)
  print(r.url,data,r.status_code)
  return r.status_code

send_influx("Current",146,"SMA1-A",dc_amperage_1)
send_influx("Current",148,"SMA2-A",dc_amperage_2)
send_influx("Counter",144,"SMA-Wh",total_yield_Wh)
send_influx("Temperature",145,"SMA-C",temperature_C)
send_influx("Voltage",147,"SMA1-V",dc_voltage_1)
send_influx("Voltage",149,"SMA2-V",dc_voltage_2)

