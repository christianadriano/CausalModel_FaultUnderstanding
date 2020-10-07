
"
Causal discovery for the programming skill related factors

"  
"There are two packages in R for Bayesian Network Learning (or causal graph learning):
bnlearn and pcalg. I decided to use bnlearn, because its installation was easier than
pcalg. The pcalg requires the BiocManager (install.packages(BiocManager)), which is
very larger framework, which is not installing smoothly"

#-----------------------------------
#Example with BNLEARN (will move it to the bottom later)
#install.packages("bnlearn")
#
library(bnlearn)
data(learning.test)
str(learning.test)
bn.gs <- gs(learning.test)
bn.gs
plot(bn.gs)
#-----------------------------------            
"APPLY TO THE PROGRAMMING SKILL FACTORS 

profession [exogenous];
years_programming [exogenous];
age [exogenous]
qualification_score [outcome];
file_name [exogenous] work as block, because programmers were tested for each file_name
need to consider unique worker-id, i.e., programmer took a single qualification test, even
if they have taken multiple tasks.
" 
#install.packages("tidyverse")
"Load data with treatment field (isBugCovering) and ground truth (answer correct)"
source("C://Users//Christian//Documents//GitHub//CausalModel_FaultUnderstanding//data_loaders//load_ground_truth_E2.R")
#summary(df_E2_ground)

source("C://Users//Christian//Documents//GitHub//CausalModel_FaultUnderstanding//data_loaders//create_indexes_E2.R")
#source("C://Users//Christian//Documents//GitHub//CausalModel_FaultUnderstanding//util//Multiplot.R")
df_E2_ground<- run(df_E2_ground)

library(dplyr)
df_selected <-
  dplyr::select(df_E2_ground,
                years_programming,
                z1,#IRT qualification score
                age,
                profession
                );



node.names <- colnames(df_selected)
#Avoid that age have parent nodes
blacklist_1 <- data.frame(from = node.names[-grep("age", node.names)], 
                          to   = c("age"))
blacklist_2 <- data.frame(from = node.names[-grep("isAnswerCorrect", node.names)], 
                          to   = c("isAnswerCorrect"))
#Avoid z1 and isAnswerCorrect to be parents
blacklist_3 <- data.frame(from = c("z1"),
                          to   = node.names[-grep("z1", node.names)])

#Task Accuracy can only be measured with all tasks data. 
#Here we are dealing only with programmer demographic data.
#blacklist_4 <- data.frame(from = c("isAnswerCorrect"),
#                          to   = node.names[-grep("isAnswerCorrect", node.names)])

blacklist_all <- rbind(blacklist_1,blacklist_2,blacklist_3)#,blacklist_4) 
#Remove profession from blacklist
blacklist_all <- blacklist_all[!(blacklist_all$from %in% c("profession") ),]
blacklist_all <- blacklist_all[!(blacklist_all$to %in% c("profession") ),]


#Run structure discovery for each profession
professions = c("Other", "Undergraduate_Student","Graduate_Student","Hobbyist",
                "Professional_Developer")

#Constraint-Based Algorithm
for (i in 1:length(professions)) {
  choice = professions[i]
  df_prof <- df_selected[df_selected$profession==choice,]
  df_prof <- 
    dplyr::select(df_prof,
                  years_programming,
                  z1,
                  age,
                  isAnswerCorrect
    );
  bn <-pc.stable(df_prof,blacklist = blacklist_all)
  plot(bn,main=choice)
  #graphviz.plot(bn,main=choice,shape="ellipse",layout = "circo");
}

#Score-based algorithm - Hill Climbing
for (i in 1:length(professions)) {
  choice = professions[i]
  df_prof <- df_selected[df_selected$profession==choice,]
  df_prof <- 
    dplyr::select(df_prof,
                  years_programming,
                  z1,
                  age
    );
  bn <-tabu(df_prof,blacklist = blacklist_all)
  plot(bn,main=choice)
  #graphviz.plot(bn,main=choice,shape="ellipse",layout = "circo");
}

#TODO
#Graphs resulting from IRT are very different from qualification_score
#compare how professions are distinct in terms of z1 and qualification_score
#Compare the strength of graph connections using z1 and qualification_score

#https://arxiv.org/pdf/0908.3817.pdf
