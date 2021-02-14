#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Jan 25 14:17:23 2021

@author: formateur
"""

# import librairies
from pymongo import MongoClient
import config
from pprint import pprint
import requests
import sys

# Connection à MongoDB
client = MongoClient('mongodb://%s:%s@%s/?authSource=%s'% (config.user, config.password,'127.0.0.1', 'admin'))
db = client['bdd_grp3']
collec = db['MoocProject']

# connection à la session du Mooc
cookies = {
    'csrftoken': 'n5ufSiNCMg0hmGO2k5IqSAyQ8rMa0kaU',
    'acceptCookieFun': 'on',
    'atuserid': '%7B%22name%22%3A%22atuserid%22%2C%22val%22%3A%223d486efc-aa97-4bf2-a31c-3efaf98b22da%22%2C%22options%22%3A%7B%22end%22%3A%222022-02-09T08%3A03%3A55.410Z%22%2C%22path%22%3A%22%2F%22%7D%7D',
    'atidvisitor': '%7B%22name%22%3A%22atidvisitor%22%2C%22val%22%3A%7B%22vrn%22%3A%22-602676-%22%7D%2C%22options%22%3A%7B%22path%22%3A%22%2F%22%2C%22session%22%3A15724800%2C%22end%22%3A15724800%7D%7D',
    'edxloggedin': 'true',
    'edx_session': 'zytpalnc3n1h4ith1pf9920a785vk9cp',
    'edx-user-info': '{\\"username\\": \\"Isa-mi\\"\\054 \\"version\\": 1\\054 \\"email\\": \\"isa.minnaert@gmail.com\\"\\054 \\"header_urls\\": {\\"learner_profile\\": \\"https://www.fun-mooc.fr/u/Isa-mi\\"\\054 \\"logout\\": \\"https://www.fun-mooc.fr/logout\\"\\054 \\"account_settings\\": \\"https://www.fun-mooc.fr/account/settings\\"}}',
}

headers = {
    'User-Agent': 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:84.0) Gecko/20100101 Firefox/84.0',
    'Accept': 'application/json, text/javascript, */*; q=0.01',
    'Accept-Language': 'fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3',
    'X-CSRFToken': 'n5ufSiNCMg0hmGO2k5IqSAyQ8rMa0kaU',
    'X-Requested-With': 'XMLHttpRequest',
    'Connection': 'keep-alive',
    'Referer': 'https://www.fun-mooc.fr/courses/course-v1:lyon3+26006+session04/discussion/forum/a427e66c7957bbde8f0834e0393b1124c419c814/threads/600d4514a643390001000876',
}

# Récupération de tous les fils de discussions et toutes les pages du Mooc
for page in range(1,999):
    params = (
    ('ajax', '1'),
    ('page', page),
    ('sort_key', 'date'),
    ('sort_order', 'desc'),) # paramètres modifiés pour itérer sur toutes les pages
    response = requests.get('https://www.fun-mooc.fr/courses/course-v1:lyon3+26006+session04/discussion/forum?ajax=1&page=1&sort_key=date&sort_order=desc', headers=headers, params=params, cookies=cookies)
    res = response.json()
    #print(res) # validation de la prise en compte de la réponse
    print('page:', page)
    if len(res["discussion_data"]) == 0:
        print("Fin de page")
        sys.exit()
    for block in res["discussion_data"]:
        print(block["id"], block["title"])
        #print("---------------------------------------------------------------------------------------")
        url = "https://www.fun-mooc.fr/courses/course-v1:lyon3+26006+session04/discussion/forum/"+block["commentable_id"]+"/threads/"+block["id"]+"?ajax=1&resp_skip=0&resp_limit=25"
        #print(url) # validation de la prise en compte de la connection
        result = requests.get(url, headers=headers, cookies=cookies)
        #print(result.json()) # validation de la prise en compte des résultats
        x = collec.insert_one(result.json())  # envoi sur la bdd_grp3
       