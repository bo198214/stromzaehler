#!/usr/bin/env python3

from pymodbus.client.sync import ModbusTcpClient

client = ModbusTcpClient('192.168.178.26',port=502)
res = client.read_holding_registers(30529,2,unit=3)
total_yield_Wh = (res.getRegister(0)<<16)+res.getRegister(1)

res = client.read_holding_registers(30769,2,unit=3)
dc_amperage_1=((res.getRegister(0)<<16)+res.getRegister(1))/1000
res = client.read_holding_registers(30771,2,unit=3)
dc_voltage_1=((res.getRegister(0)<<16)+res.getRegister(1))/100
res = client.read_holding_registers(30957,2,unit=3)
dc_amperage_2=((res.getRegister(0)<<16)+res.getRegister(1))/1000
res = client.read_holding_registers(30959,2,unit=3)
dc_voltage_2=((res.getRegister(0)<<16)+res.getRegister(1))/100
print(total_yield_Wh,"Wh,",dc_amperage_1,"A,",dc_voltage_1,"V,",dc_amperage_2,"A,",dc_voltage_2,"V")
