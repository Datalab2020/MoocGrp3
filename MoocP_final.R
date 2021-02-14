# import librairies
library(mongolite)
library(ggplot2)
library(jsonlite)
library(config)
library(dplyr)
library(ggridges)

# connexion bdd
credentials <- config::get("mongo")
url <- paste("mongodb://", credentials$user, ":", credentials$password,"@127.0.0.1/bdd_grp3?authSource=admin", sep="")
print(url)
m <- mongo("NewMooc_msg", url = url)

# selection des colonnes et mise à plat de la df
t <- m$find(query = '{}', fields = '{"_id": 1,"course_id": 1, "body": 1, "username": 1, "votes": 1, "created_at": 1}') %>%
  mutate(course_id = case_when(course_id == "course-v1:Agreenium+66004+session02" ~ "L'environnement et l'aménagement du territoire",
                               course_id == "course-v1:Uness+181001+session01" ~ "Métier de la santé",
                               course_id == "course-v1:ulg+108006+session04" ~ "Chimie",
                               course_id == "course-v1:umontpellier+08013+session02" ~ "Apprentissage dans l'enseignement supérieur",
                               course_id == "course-v1:uved+34011+session02" ~ "Transition écologique",
                               course_id == "course-v1:lyon3+26006+session04" ~ "Sciences Humaines"))
df <- flatten(t)
print(df)

# total des messages dans la collection
som <- df$aggregate('[{"$count": "total"}]')
print(som)

# total des messages par cours
t_cours <- df$aggregate('[{"$group": {"_id":"$course_id","TotalCours": {"$sum": 1 } } }]')
print(t_cours)

# nbre messages par username
Nbr_D <- df$aggregate('[{"$group": {"_id":"$username","NbrDiscussion": {"$sum": 1 } } }, {"$sort": {"NbrDiscussion": -1 } } ]')
print(Nbr_D)
Nbr_D = data.frame(Nbr_D)

dis <- Nbr_D %>%
  group_by(NbrDiscussion) %>%
  count()

dis <- dis %>%
  arrange(desc(NbrDiscussion)) %>%
  mutate(lab.ypos = cumsum(n))

# anonymous
anon <- df$aggregate('[{"$project": {"_id": "$id", "Anonymous" : 1 } }]')
print(anon)

anon = data.frame(anon)

cnt <- anon %>%
  group_by(anonymous) %>%
  count()

cnt <- cnt %>%
  arrange(desc(anonymous)) %>%
  mutate(lab.ypos = cumsum(n) - 0.5*n)

# nbre de votes par cours
v_cours <- m$aggregate('[{"$group": {"_id": "$course_id", "N": {"$sum": "$votes.count"} } } ]') %>%
  rename(course_id = "_id") %>%
  arrange(desc(N)) %>%
  mutate(course_id = case_when(course_id == "course-v1:Agreenium+66004+session02" ~ "L'environnement et l'aménagement du territoire",
                               course_id == "course-v1:Uness+181001+session01" ~ "Métier de la santé",
                               course_id == "course-v1:ulg+108006+session04" ~ "Chimie",
                               course_id == "course-v1:umontpellier+08013+session02" ~ "Apprentissage dans l'enseignement supérieur",
                               course_id == "course-v1:uved+34011+session02" ~ "Transition écologique",
                               course_id == "course-v1:lyon3+26006+session04" ~ "Sciences Humaines"))
print(v_cours)

# Messages par heures et par cours
dd <- m$find(query = '{}', fields = '{"course_id": 1, "created_at": 1}') %>%
  mutate(course_id = case_when(course_id == "course-v1:Agreenium+66004+session02" ~ "L'environnement et l'aménagement du territoire",
                               course_id == "course-v1:Uness+181001+session01" ~ "Métier de la santé",
                               course_id == "course-v1:ulg+108006+session04" ~ "Chimie",
                               course_id == "course-v1:umontpellier+08013+session02" ~ "Apprentissage dans l'enseignement supérieur",
                               course_id == "course-v1:uved+34011+session02" ~ "Transition écologique",
                               course_id == "course-v1:lyon3+26006+session04" ~ "Sciences Humaines"))
print(dd)

var <- as.POSIXct(dd$created_at, format = "%Y-%m-%dT%H:%M:%SZ")
hours <- format(var, "%H")
print(hours)

# Fréquence des discussions par cours dans le temps
dp <- m$find(query = '{}', fields = '{"thread": 1, "created_at": 1, "course_id": 1}') %>%
  mutate(course_id = case_when(course_id == "course-v1:Agreenium+66004+session02" ~ "L'environnement et l'aménagement du territoire",
                               course_id == "course-v1:Uness+181001+session01" ~ "Métier de la santé",
                               course_id == "course-v1:ulg+108006+session04" ~ "Chimie",
                               course_id == "course-v1:umontpellier+08013+session02" ~ "Apprentissage dans l'enseignement supérieur",
                               course_id == "course-v1:uved+34011+session02" ~ "Transition écologique",
                               course_id == "course-v1:lyon3+26006+session04" ~ "Sciences Humaines"))
print(dp)

dtps <- dp %>%
  mutate(dates = format(as.Date(created_at),"%Y-%m-%d")) %>%
  group_by(dates, course_id) %>%
  count(name = "nbdisc")

# -----------------------------------------------------------GRAPHS----------------------------------------------------------------

# graph nbr mess par users
Nbr_D %>%
  drop_na() %>%
  ggplot( aes(x= reorder(X_id, -NbrDiscussion), y= NbrDiscussion)) +
  geom_segment( aes(x= reorder(X_id, -NbrDiscussion), xend= reorder(X_id, -NbrDiscussion), y=0, yend= NbrDiscussion), color="darkblue") +
  geom_point( color="blue", size=2, alpha=0.8) +
  theme_light() + xlab("Users") + ylab("Nombre de discussions") +
  theme(
    panel.grid.major.x = element_blank(),
    panel.border = element_blank(),
    axis.text.x = element_blank(),
    axis.text.y = element_text(face="bold", color="black", size=12),
    axis.title.x = element_text(color="#696969", size=15, face="bold"),
    axis.title.y = element_text(color="#696969", size=15, face="bold"))

# graph nbr mess pour les 20 premiers users
Nbr_D %>%
  slice(1:20) %>%
  drop_na() %>%
  ggplot( aes(x= reorder(X_id, -NbrDiscussion), y= NbrDiscussion)) +
  geom_segment( aes(x= reorder(X_id, -NbrDiscussion), xend= reorder(X_id, -NbrDiscussion), y=0, yend= NbrDiscussion), color="darkblue") +
  geom_point( color="blue", size=8, alpha=0.8) +
  theme_light() +
  coord_flip() + xlab("Users") + ylab("Nombre de discussions") +
  theme(
    panel.grid.major.y = element_blank(),
    panel.border = element_blank(),
    axis.title.x = element_text(color="#696969", size=15, face="bold"),
    axis.title.y = element_text(color="#696969", size=15, face="bold"),
    axis.text.x = element_text(face="bold", color="black", size=12),
    axis.text.y = element_text(face="bold", color="black", size=11))

# graph anonymous
mycols <- c("#EFC000FF","#0073C2FF")
ggplot(cnt, aes(x="", y=n, fill=anonymous))+
  geom_bar(width = 1, stat = "identity", color = "white")+
  coord_polar("y", start=0)+
  geom_text(aes(y = lab.ypos, label = n), color = "white", size=13)+
  scale_fill_manual(values = mycols) +
  theme_void() + labs(fill = "ANONYMES") +
  theme(
    legend.title = element_text(colour="#696969", size=16, face="bold"),
    legend.text = element_text(colour="#696969", size=13, face="bold"))

# graph nbre de votes par cours
ggplot(v_cours, aes(x= reorder(course_id, -N), y=N, fill=course_id)) + 
  geom_histogram(stat = "identity", color = "white") +
  theme(legend.position = "none") +
  xlab("Cours") + ylab("Votes") +
  scale_fill_hue(c=120, l=80) +
  theme(
    axis.title.x = element_text(color="#696969", size=15, face="bold"),
    axis.title.y = element_text(color="#696969", size=15, face="bold"),
    axis.text.x = element_text(face="bold", color="black", size=11),
    axis.text.y = element_text(face="bold", color="black", size=12))

# graph des messages par heure et par cours
ggplot(dd, aes(x= hours, y="", fill=`course_id`)) + geom_col() +
  xlab("Heures") + ylab("Messages") + labs(fill = "Cours") + 
  annotation_logticks(sides = "l", short = unit(0,"mm"),
                        mid = unit(0,"mm"),
                        long = unit(2,"mm")) +
  scale_fill_hue(c=120, l=80) +
  theme(
    axis.title.x = element_text(color="#696969", size=15, face="bold"),
    axis.title.y = element_text(color="#696969", size=15, face="bold"),
    legend.title = element_text(colour="#696969", size=16, face="bold"),
    legend.text = element_text(colour="#696969", size=13, face="bold"),
    axis.text.x = element_text(face="bold", color="black", size=11))

# graph fréquence des discussions par cours dans le temps
dtps %>%
  filter(dates >= "2020-09-22") %>%
  ggplot(aes(x= as.Date(dates), y= nbdisc, group= course_id, fill = course_id)) + geom_col() +
  scale_fill_hue(c=120, l=80) +
  xlab("Dates") + ylab("Nombre Discussions") + labs(fill = "Cours") +
  theme(
    axis.title.x = element_text(color="#696969", size=15, face="bold"),
    axis.title.y = element_text(color="#696969", size=15, face="bold")) +
  theme(
    legend.title = element_text(colour="#696969", size=16, face="bold"),
    legend.text = element_text(colour="#696969", size=13, face="bold"),
    axis.text.x = element_text(face="bold", color="black", size=11),
    axis.text.y = element_text(face="bold", color="black", size=12))
  
# Graph de la fréquence des discussions par cours par jour
ggplot(dtps, aes(x = nbdisc, y = course_id, fill = course_id)) +
  geom_density_ridges() +
  theme_ridges() + 
  theme(legend.position = "none") +
  scale_fill_hue(c=120, l=80) +
  xlab("Nombre discussions / Jour") +
  theme(
    axis.title.x = element_text(color="#696969", size=15, face="bold"),
    axis.title.y = element_blank(),
    axis.text.x = element_text(face="bold", color="black", size=12),
    axis.text.y = element_text(face="bold", color="black", size=11))

# graph variance des discussions par semaine et par heure
x <- dp %>%
  mutate(Jours = wday(created_at, label = TRUE, abbr = FALSE, week_start = 1),
         Heures = format(as.POSIXct(created_at, format = "%Y-%m-%dT%H:%M:%SZ"), "%H")) %>%
  group_by(Jours, Heures) %>%
  summarise(total = n()) %>%
  ungroup() %>%
  mutate(Pourcentage = total/sum(total)*100) %>%
  ggplot(aes(Heures, Jours)) + 
  geom_tile(aes(fill = Pourcentage), colour = "white") + 
  scale_fill_distiller(palette = "RdPu", direction = 1) +
  scale_x_discrete(labels = 00:23) + 
  theme_minimal() +
  theme(legend.position = "bottom", legend.key.width = unit(2, "cm"),
        panel.grid = element_blank()) + 
  theme(axis.line = element_line(colour = "black", 
        size = 0.25, linetype = "solid")) +
  theme(
    axis.title.x = element_text(color="#696969", size=15, face="bold"),
    axis.title.y = element_text(color="#696969", size=15, face="bold"),
    legend.title = element_text(colour="#696969", size=16, face="bold"),
    legend.text = element_text(colour="#696969", size=13, face="bold"),
    axis.text.x = element_text(face="bold", color="black", size=11),
    axis.text.y = element_text(face="bold", color="black", size=11)) +
  coord_equal()
print(x)
