
"
Causal discovery for the programming skill related factors

There are two packages in R for Bayesian Network Learning (or causal graph learning):
bnlearn and pcalg. I decided to use bnlearn, because its installation was easier than
pcalg. The pcalg requires the BiocManager (install.packages(BiocManager)), which is
very larger framework, which is not installing smoothly

"

#-----------------------------------
#Example with BNLEARN (will move it to the bottom later)
#install.packages("bnlearn")
#
# data(learning.test)
# str(learning.test)
# bn.gs <- gs(learning.test)
# bn.gs
# plot(bn.gs)
#-----------------------------------            
"APPLY TO THE PROGRAMMING SKILL FACTORS 

profession [exogenous];
years_programming [exogenous];
age [exogenous]
testDuration [endogenous];
qualification_score [outcome];
adjusted_score [outcome];

" 

library(bnlearn)
library(dplyr)

#Load only Consent data. No data from tasks, only from demographics and qualification test
source("C://Users//Christian//Documents//GitHub//CausalModel_FaultUnderstanding//data_loaders//load_consent_create_indexes_E2.R")

df_selected <-
  dplyr::select(df_consent,
                years_programming,
                adjusted_score,
                age,
                profession
                );


node.names <- colnames(df_selected)
#Avoid that age have parent nodes

#NO PARENTS
#blacklist_1 <- data.frame(from = node.names[-grep("age", node.names)], 
#                          to   = c("age"))
#Prevent Years of Programming to be parent of Age.
blacklist_1 <- data.frame(from = c("years_programming"), 
                          to   = c("age"))

#Avoid that profession has parent node
blacklist_2 <- data.frame(from = node.names[-grep("profession", node.names)], 
                          to   = c("profession"))
#NO CHILDS
#Avoid adjusted_score to be parent
blacklist_3 <- data.frame(from = c("adjusted_score"),
                          to   = node.names[-grep("adjusted_score", node.names)])

#Task Accuracy can only be measured with all tasks data. 
#Here we are dealing only with programmer demographic data.
#blacklist_4 <- data.frame(from = c("isAnswerCorrect"),
#                          to   = node.names[-grep("isAnswerCorrect", node.names)])

blacklist_all <- rbind(blacklist_1,blacklist_2,blacklist_3)#,blacklist_4) 


bn <-tabu(df_selected,blacklist = blacklist_all)
plot(bn,main="All Professions")

"Profession is a confounder for Age and Years_Programming, but Profession has no direct
effect on qualification_score. Same for adjusted_score score. Profession has an effect on the
membership of is_fast, and the is_fast has a direct effect on adjusted_score score."

#-----------------------------------------
#BY PROFESSION

#Remove profession from blacklist
blacklist_all <- blacklist_all[!(blacklist_all$from %in% c("profession") ),]
blacklist_all <- blacklist_all[!(blacklist_all$to %in% c("profession") ),]


#Run structure discovery for each profession
professions = c("Other", "Undergraduate_Student","Graduate_Student","Hobbyist",
                "Programmer","Professional")

#Constraint-Based Algorithm
for (i in 1:length(professions)) {
  choice = professions[i]
  df_prof <- df_selected[df_selected$profession==choice,]
  df_prof <- 
    dplyr::select(df_prof,
                  years_programming,
                  adjusted_score,
                  age,
                  #profession
                  #isAnswerCorrect
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
                  adjusted_score,
                  age
    );
  bn <-tabu(df_prof,blacklist = blacklist_all)
  plot(bn,main=choice)
  #graphviz.plot(bn,main=choice,shape="ellipse",layout = "circo");
}


#---------------------------------------------------------------
#---------------------------------------------------------------
#Using now qualification_score instead of IRT adjusted_score score 

df_selected <-
  dplyr::select(df_consent,
                years_programming,
                #adjusted_score,
                qualification_score,
                age,
                profession
  );



node.names <- colnames(df_selected)

#Avoid that age have parent nodes
#blacklist_1 <- data.frame(from = node.names[-grep("age", node.names)], 
#                          to   = c("age"))
#Prevent Years of Programming to be parent of Age.
blacklist_1 <- data.frame(from = c("years_programming"), 
                          to   = c("age"))
#Avoid that profession has parent nodes
blacklist_2 <- data.frame(from = node.names[-grep("profession", node.names)], 
                          to   = c("profession"))
#NO CHILDS
#Avoid qualification_score to be parent

blacklist_3 <- data.frame(from = c("qualification_score"),
                          to   = node.names[-grep("qualification_score", node.names)])

#Task Accuracy can only be measured with all tasks data. 
#Here we are dealing only with programmer demographic data.
#blacklist_4 <- data.frame(from = c("isAnswerCorrect"),
#                          to   = node.names[-grep("isAnswerCorrect", node.names)])

blacklist_all <- rbind(blacklist_1,blacklist_2,blacklist_3)#,blacklist_4) 


bn <-tabu(df_selected,blacklist = blacklist_all)
plot(bn,main="All Professions")



#Constraint-Based Algorithm
for (i in 1:length(professions)) {
  choice = professions[i]
  df_prof <- df_selected[df_selected$profession==choice,]
  df_prof <- 
    dplyr::select(df_prof,
                  years_programming,
                  qualification_score,
                  age,
                  #profession
                  #isAnswerCorrect
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
                  qualification_score,
                  age
    );
  bn <-tabu(df_prof,blacklist = blacklist_all)
  plot(bn,main=choice)
  #graphviz.plot(bn,main=choice,shape="ellipse",layout = "circo");
}



