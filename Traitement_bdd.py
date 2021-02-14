#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Created on Fri Jan 22 12:07:00 2021

@author: frand
"""

# import des librairies
from pymongo import MongoClient
import yaml, pymongo, io
from colorama import Fore, Back, Style
import sys
from vaderSentiment_fr.vaderSentiment import SentimentIntensityAnalyzer
import urllib.parse


# paramètre à indiquer au départ sur le terminal ./Traitement_bdd.py archives
print(sys.argv)
config = yaml.safe_load(open("../config.yaml")) 
print('user:'+Fore.RED+config['mongo']['user']+Style.RESET_ALL)

# Analyse des sentiments
SIA = SentimentIntensityAnalyzer()

# connection à mongoDB
client = MongoClient('mongodb://%s:%s@%s/?authSource=%s'
% (config['mongo']['user'],urllib.parse.quote_plus(config['mongo']['password']),
'127.0.0.1', 'admin'))
db = client['bdd_grp3']
collec = db[sys.argv[1]]

# Aplanissement et gestion des doublons
def process(msg,level): 
    endorsed_responses = msg['endorsed_responses'] if("endorsed_responses" in msg ) else []
    children = msg['children']  if("children" in msg ) else []
    non_endorsed = msg['non_endorsed_responses']  if("non_endorsed_responses" in msg ) else []
    # Analyse des sentiments
    score = SIA.polarity_scores(msg['body'])
    print(score)
    if("endorsed_responses" in msg) :
        del msg['endorsed_responses']
    if("children" in msg) :
        del msg['children']
    if("non_endorsed_responses" in msg) :
        del msg['non_endorsed_responses']
    msg['level'] = level
    msg['score'] = score
    print(level, msg['id']+ " ")
    # Envoi dans la bdd
    db[sys.argv[1] + '_msg'].delete_one({'id': msg['id']})
    db[sys.argv[1] + '_msg'].insert(msg)
    # prise en compte de tous les niveaux
    for resp in children + non_endorsed + endorsed_responses:
      process(resp, level+1)
        
for elem in collec.find():
    process(elem['content'], 0)
   # print(elem)