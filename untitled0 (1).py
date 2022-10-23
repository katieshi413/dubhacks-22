# -*- coding: utf-8 -*-
"""Untitled0.ipynb

Automatically generated by Colaboratory.

Original file is located at
    https://colab.research.google.com/drive/1Pc-oeUyfVkG0XTCo4VNKVFd2VE_Jf_N8
"""

import requests
from timeit import default_timer
import time
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

def make_call():
  #user.emergy_number - covered in database implementation
  Print("calling emerency number in 30 seconds")

def check_message():
  #poll the servers to see if a text has been recived
  print("checking messages")

def send_sms():
    print("type y to confrim you're okay")

def get_dist(spot):
  hardware_value = (47.60638, -122.33223)
  actual_location= hardware_value
  distance =(abs(spot[0]-actual_location[0])**2+abs(spot[1]-actual_location[1])**2)**(1/2)
  return distance


def am_i_safe(valid_locations):
  #if valid_locations ==0:
   # print ("bad route info - please try inputing route again")
    #return
  
  count=0
  trip_done=0
  start =0
  index=0
  #coords =actual_location.split(",")
  
  path1=valid_locations[0]
  path2=valid_locations[1]
  path3=valid_locations[2]

  while trip_done==0:
    #loop through each path viewing current and next index - once closer to the next point of any increse index
    
      # we have move down a path
    lowest= get_dist(path1[index])
    if get_dist(path2[index])<lowest:
      lowest=get_dist(path2[index])
    if get_dist(path3[index])<lowest:
      lowest=get_dist(path3[index])

    temp=lowest

    if get_dist(path1[index+1])<lowest:
      lowest=get_dist(path1[index+1])
    if get_dist(path2[index])<lowest:
      lowest=get_dist(path2[index+1])
    if get_dist(path3[index+1])<lowest:
      lowest=get_dist(path3[index+1])


    if temp!= lowest:
      index+=1

    

    if lowest > 0.001:
      count=+1
      if count >5:
        #user.txt nummber - covered in database implementation
        send_sms()
        #start timer
        start = default_timer()
        
        #wait 2-5 min for response then call emergy contact/911
    else:
      count=0
  
    if start>0:
      response=check_message()
      if response =="y":
        start = 0
      elif( default_timer() - start )>180:
        make_call()
      
   


valid_locations=get_routes()
am_i_safe(valid_locations)