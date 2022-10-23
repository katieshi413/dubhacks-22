# -*- coding: utf-8 -*-
"""Untitled0.ipynb

Automatically generated by Colaboratory.

Original file is located at
    https://colab.research.google.com/drive/1Pc-oeUyfVkG0XTCo4VNKVFd2VE_Jf_N8
"""

import requests
import json
import polyline

def get_routes(origin="Seattle", destination="Husky Union Building, East Stevens Way Northeast, Seattle, WA"):
  url = "https://maps.googleapis.com/maps/api/directions/json?origin="+origin+"&destination="+destination+"&alternatives=true&key=AIzaSyBm8o4sZAjh-VxR8t6KAraVprTylMGHbEE"
  payload={}
  headers = {}

  response = requests.request("GET", url, headers=headers, data=payload)
  printer = 0
  valid_locations=[]
  #print(response.text)
  response.text
  for line in response.iter_lines():
    line=str(line)
    if "overview_polyline" in line or printer ==1:
      printer = not(printer)
      if printer == 0:
        text= line.split(':')
        text=text[1]
        
        valid_locations.append(polyline.decode(text[2:-2]+"@"))
        print(valid_locations)
  return valid_locations

 

def send_sms():
    print("type y to confrim you're okay")

def am_i_safe(polling=10, valid_gps=0):
  if valid_locations ==0:
    print ("bad route info - please try inputing route again")
    return
  hardware_value = (47.60638, -122.33223)
  actual_location= hardware_value
  count=0
  #coords =actual_location.split(",")
  for path in valid_gps:
    for spot in path:
      distance =abs(spot[0]-actual_location[0])
      if distance > 0.001:
        count=+1
        if count >4:
          send_sms()
          #start timer
          #wait 2-5 min for response then call emergy contact/911
      else:
        count=0

      if message_check()=="y":


valid_locations=get_routes()
am_i_safe(valid_gps=valid_locations)