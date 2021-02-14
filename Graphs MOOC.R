library('mongolite')
library('config')
library('jsonlite')
library('ggplot2')
library('dplyr')  
library('httr')
library("wordcloud")
library("RColorBrewer")
library("wordcloud2")
library("tidyverse")
library("tm")
library("forcats")

#connection----------
credentials <- config::get("mongo")
url <- paste("mongodb://", credentials$username, ":", credentials$password, "@127.0.0.1/bdd_grp3?authSource=admin", sep="")
m <- mongo("NewMooc_NEW", url = url) 
print(url)
#--------------------

n <- m$find(query = '{}', fields = '{"_id" : 1, "created_at":1, "updated_at" : 1, "course_id" : 1, "votes" : 1, "title" : 1, "body" : 1, "username" : 1, "score.neg" : 1, "score.neu" : 1, "score.pos" : 1, "score.compound" : 1}')
mydata <- flatten(n) 

#Word Cloud Plot---------------
cloud <- m$find(query = '{}', fields = '{"_id" : 0, "body": 1}')

docs <- Corpus(VectorSource(cloud))
docs <- docs %>%
  tm_map(removeNumbers) %>%
  tm_map(removePunctuation) %>%
  tm_map(stripWhitespace)
docs <- tm_map(docs, content_transformer(tolower))
docs <- tm_map(docs, removeWords, stopwords("french"))

dtm <- TermDocumentMatrix(docs) 
matrix <- as.matrix(dtm) 
words <- sort(rowSums(matrix),decreasing=TRUE) 
df <- data.frame(word = names(words),freq=words)
dfCourt <- df[1:130,]
set.seed(1234)
wordcloud2(data=dfCourt, size=1.1, color="brewer.pal"(8, "Dark2"))
#------------------------------

#wordstitres GRAPH

titles <- m$find(query = '{}', fields = '{"_id" : 0, "title": 1}')

# complete.cases(titles)
# titles <- titles[complete.cases(titles$title),]

docsT <- Corpus(VectorSource(titles))
docsT <- docsT %>%
  tm_map(removeNumbers) %>%
  tm_map(removePunctuation) %>%
  tm_map(stripWhitespace)
docsT <- tm_map(docsT, content_transformer(tolower))
docsT <- tm_map(docsT, removeWords, stopwords("french"))

termDoc <- TermDocumentMatrix(docsT) 
matrixT <- as.matrix(termDoc) 
wordsT <- sort(rowSums(matrixT),decreasing=TRUE) 
dfTitle <- data.frame(word = names(wordsT),Frequency=wordsT)
dfTitle <- dfTitle[1:20,]

dfTitle %>%
  mutate(word = fct_reorder(word, Frequency)) %>%
  ggplot( aes(x=word, y=Frequency)) +
        geom_bar(stat="identity", fill="#f68060", alpha=.6, width=.4) +
        coord_flip() +
        xlab("") +
        theme_bw()


# total des messages par cours
t_cours <- m$aggregate('[{"$group": {"_id":"$course_id","TotalCours": {"$sum": 1 } } }]')
colnames(t_cours)[1] <- "Cours"
colnames(t_cours)[2] <- "Messages"
t_cours <- mutate(t_cours, 
                  Cours = case_when(
                    Cours == "course-v1:Agreenium+66004+session02" ~ "L'environnement et l'aménagement du territoire",
                    Cours == "course-v1:Uness+181001+session01" ~ "Métier de la santé",
                    Cours == "course-v1:ulg+108006+session04" ~ "Chimie",
                    Cours == "course-v1:umontpellier+08013+session02" ~ "Apprentissage dans l'enseignement supérieur",
                    Cours == "course-v1:uved+34011+session02" ~ "Transition écologique",
                    Cours == "course-v1:lyon3+26006+session04" ~ "Sciences Humaines"
                  ))
treePlot <- treemap(t_cours,index = c("Cours"),vSize ="Messages", palette = "Set2")


#Emotions
emotionsRate <- m$aggregate('[{"$group": {"_id": "$course_id", "N": {"$sum": 1},\
                            "neg": {"$sum": {"$cond": {"if": {"$gt": ["$score.neg", 0.5]},\
                            "then": 1, "else": 0}}}, "pos": {"$sum": {"$cond": {"if": {"$gt": ["$score.pos", 0.5]},\
                            "then": 1, "else": 0}}}, "neu": {"$sum": {"$cond": {"if": {"$gt": ["$score.neu", 0.5]}, \
                            "then": 1, "else": 0}}}}}]')

emo <- emotionsRate[,3:5]

emo <- emo
row.names(emo)[1] <- 'L\'enseignement supérieur'
row.names(emo)[2] <- 'Sciences Humaines'
row.names(emo)[3] <- 'L\'aménagement du territoire'
row.names(emo)[4] <- 'Chimie'
row.names(emo)[5] <- 'Transition écologique'
row.names(emo)[6] <- 'Métier de la santé'

names(emo)[1] <- "Negatif"
names(emo)[2] <- "Positif"
names(emo)[3] <- "Neutre"

emo_matrix <- data.matrix(emo)

my_palette <- hcl.colors(100, palette = "Blues", alpha = NULL, rev = TRUE, fixup = TRUE)[-c(1:20)]
emo_heatmap <- heatmap(emo_matrix, Rowv=NA, Colv=NA, col = my_palette, cexCol = 1.1, cexRow = 1.1, scale="none", margins=c(8,13))


