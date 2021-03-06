"
Causal Inference Experiment-2
Outcome: Programming Score (score)
Covariates: Years of Programming (yoe), Age

Implication of a causal model
m1.1 yoe <- a + ba*ages (correlation coeficient)

Models: 
m1.2 <- a + by*yoe (total effect of Years of experience)
m1.3 <-  a+ ba*ages (total effect of age)

m1.4.1 <-  a+ ba*ages +by*yoe
m1.4.2 <-  a+ ba*ages +by*yoe +bd*testDuration
m1.5.1 <-  a+ ba*ages +by*yoe + bya*ages*yoe
m1.5.1.2 <-  a+ ba*ages +by*yoe + bya*ages*yoe + bdy*testDuration*yoe + bda*testDuration*ages + bdya*testDuration*ages*yoe

generalization by gender, country, and profession
m1.6 <- a + by[gender_id]*yoe + ba[gender_id]*ages
m1.7 <- a + by[country_id]*yoe + ba[country_id]*ages
m1.8 <- a + by[profession_id]*yoe + ba[profession_id]*ages


Overfitting - computed WAIC and PSIS

Posterior - plotted the posterior HPDI and PI both models 1.4 and 1.5.1

Note however that we would expect that duration (as well as other variables) are 
not linear with score increase...

"

library(rethinking)
library(stringr)
library(dplyr)
library(ggdag)
library( dagitty )
library (ggm)
#library(loo) #for running WAIC and Pareto-Smooth Leave One Out Cross-Validation
library(mvtnorm)
library(devtools)
library(tidyr)

#Load data
source("C://Users//Christian//Documents//GitHub//CausalModel_FaultUnderstanding//load_consent_create_indexes_E2.R")

"Remove participants for whom we did not have years of experience information (who did not complete the survey)"
df <- df_E2 %>% drop_na(years_programming) #initial 3567, left with 2062 rows

"Outlier in Age. Removing participants who reported to be below 18 years old."
df <- df[df$age>=18,] #removed one, left with 2061 rows

"Outlier in Yoe. Removing participants which the difference between age and yoe is less than ten
years-old"
age_minus_yoe <- df$age-df$years_programming
minimum_age_minus_yoe <- age_minus_yoe>=12
df <- df[minimum_age_minus_yoe,] #left with 2040 rows

#----------------------
#Scale and Rename fields to be easier to place in formulas
df$yoe <- as.vector(scale(df$years_programming))
df$ages <- as.vector(scale(df$age))

boxplot(df$yoe)

#Causal graph
#Create
dag1.1 <- dagitty( "dag {
score [outcome];
age [exogenous];
yoe [endogenous];
age -> score;
yoe -> score;
age -> yoe 
}")

coordinates(dag1.1) <- list( x=c(yoe=0,score=1,age=2) , y=c(yoe=0,score=1,age=0) )
plot( dag1.1 )
tidy_dagitty(dag1.1)
ggdag(dag1.1, layout = "circle")

condIndep <- impliedConditionalIndependencies(dag1.1)
#{}

#Conditional independence assumptions
paths(dag1.1,c("age"),"score",directed = TRUE)
# $paths [1] "age -> score"        "age -> yoe -> score"
# $open [1] TRUE TRUE

adjustmentSets(dag1.1,exposure = "age",outcome = "score",effect = c("direct"))
#{ yoe } because YoE is a mediator
adjustmentSets(dag1.1,exposure = "yoe",outcome = "score",effect = c("direct"))
#{ age } because age is a confounder

#-------------------------
"AGE > YOE
First look a dependency between yoe and age. 
Does an increase in age relates to an increase in yoe?
Does this happen across different categories:
gender, profession, country?

Results:
m_age_yoe <- a + ba*ages (for every one age year, there is 0.27 yoe)
m_age_yoe.gender 
"

#Age > Yoe, Does an increase in age relates to an increase in yoe? YES
m_age_yoe <- quap(
  alist(
    yoe ~ dnorm( mu , sigma ) ,
    mu <- a + ba*ages,
    ba ~ dnorm( 0 , 1 ) ,
    a ~ dnorm(0, 1),
    sigma ~ dexp(1)
  ), data = df
) 
precis(m_age_yoe)
  # mean   sd  5.5% 94.5%
  # ba    0.27 0.02  0.24  0.30
  # a     0.00 0.02 -0.03  0.03
  # sigma 0.96 0.02  0.94  0.99

"The slope of 0.27 explain yoe by ages has non-zero value in the credible interval. 
To have a sense of how strong this is, the Kendall correlation was 0.21 (z = 12.956, p<0.05),
which is a weak correlation strenght(scale from 0.1 to 0.3)." 

#Generalization across categories

 
"-------
GENDER - Is age related to yoe across genders? Yes, slightly stronger for males (0.28) 
than females (0.25). However, they are not distinguishable as the CI's overlap"
m_age_yoe.gender <- quap(
  alist(
    yoe ~ dnorm( mu , sigma ) ,
    mu <- a + ba[gender_id]*ages,
    ba[gender_id] ~ dnorm( 0 , 1 ) ,
    a ~ dnorm(0, 1),
    sigma ~ dexp(1)
  ), data = df
) 
precis(m_age_yoe.gender, depth = 2)
#        mean   sd  5.5% 94.5%
# ba[1]  0.25 0.05  0.17  0.34
# ba[2]  0.28 0.02  0.24  0.32
# ba[3]  0.24 0.45 -0.47  0.96
# ba[4] -0.08 0.18 -0.36  0.21
# a      0.00 0.02 -0.03  0.03
# sigma  0.96 0.02  0.94  0.99

"---------
PROFESSION - Is age related to yoe across genders? Yes, it the strongest by professionals (1.74),
Hobbyists (0.59), then undergrads (0.37), graduates (0.27), and others (0.07).
While for professionals and all others categories the CI do not overlap, the CI overlaps among the
the not-professional developer categories. Hence, we could only distinguish between these two
groups of profession.
"
m_age_yoe.profession <- quap(
  alist(
    yoe ~ dnorm( mu , sigma ) ,
    mu <- a + ba[profession_id]*ages,
    ba[profession_id] ~ dnorm( 0 , 1 ) ,
    a ~ dnorm(0, 1),
    sigma ~ dexp(1)
  ), data = df
) 
precis(m_age_yoe.profession, depth = 2)
#        mean   sd  5.5% 94.5%
# ba[1]  1.74 0.08  1.61  1.87
# ba[2]  0.59 0.05  0.51  0.68
# ba[3]  0.27 0.11  0.10  0.44
# ba[4]  0.37 0.06  0.27  0.47
# ba[5]  0.07 0.02  0.03  0.10
# a     -0.03 0.02 -0.06  0.00
# sigma  0.87 0.01  0.85  0.90


"---------
COUNTRY - Is age related to yoe across countries? Except for India, the coefficients for US and 
the third group of countries are respectively 0.7 and 0.81 and their CI do not cross zero.
However, they overlap. Hence, we could only distinguish between these two groups of countries.
"
m_age_yoe.country <- quap(
  alist(
    yoe ~ dnorm( mu , sigma ) ,
    mu <- a + ba[country_id]*ages,
    ba[country_id] ~ dnorm( 0 , 1 ) ,
    a ~ dnorm(0, 1),
    sigma ~ dexp(1)
  ), data = df
) 
precis(m_age_yoe.country, depth = 2)
#       mean   sd  5.5% 94.5%
# ba[1] 0.70 0.03  0.65  0.76
# ba[2] 0.02 0.03 -0.02  0.06
# ba[3] 0.81 0.22  0.45  1.16
# a     0.00 0.02 -0.04  0.03
# sigma 0.90 0.01  0.88  0.93


#-------------------------------------------------------------

"Remove people who did take the test"
df <- df[complete.cases(df[,"qualification_score"]),] #left with 1420
"Scale score and rename"
df$score <- df$qualification_score #scale(df$qualification_score)
table(df$score)
#Score         0   1   2   3   4   5 
#Participants 240 402 280 157 158 183

"Remove people who did no qualify to the test (score<2)"
df_qualified <- df[df$score>=3,]
table(df_qualified$score)

m1.0 <- quap(
  alist(
    score ~ dnorm( mu , sigma ) ,
    mu <- a + by*yoe,
    by ~ dnorm( 0 , 1 ) ,
    a ~ dnorm(0, 1),
    sigma ~ dexp(1)
  ), data = df_qualified
) 
precis(m1.0)
#       mean   sd 5.5% 94.5%
# by    0.06 0.03 0.02  0.11
# a     4.02 0.04 3.95  4.08
# sigma 0.82 0.03 0.78  0.86

#All who took the test
m1.1 <- quap(
  alist(
    score ~ dnorm( mu , sigma ) ,
    mu <- a + by*yoe,
    by ~ dnorm( 0 , 1 ) ,
    a ~ dnorm(0, 1),
    sigma ~ dexp(1)
  ), data = df
) 
precis(m1.1)

#Considering all who took the test
#       mean   sd 5.5% 94.5%
# by    0.46 0.04 0.40  0.52
# a     2.05 0.04 2.00  2.14
# sigma 1.55 0.03 1.50  1.60
"Model m1.0 tells that for each year of programming experience there is an increase in
0.06 in score, whereas in m1.1 there is a gain of almost half a score point (0.46).
Assuming nothing changes, except yoe, someone who got zero score, would need 6 yoe to qualify (3/0.46)"

#--------
"Since the people have different ages, which means that their Yoe might have been gained
at different moments in their lives, we looked if age has an effect on score."


#Total effect of Age on Score
m1.2 <- quap(
  alist(
    score ~ dnorm( mu , sigma ) ,
    mu <- a+ ba*ages,
    ba ~ dnorm( 0 , 1 ) ,
    a ~ dnorm(0, 1 ),
    sigma ~ dexp(1)
  ), data = df
) 
precis(m1.2)
#       mean   sd  5.5% 94.5%
# ba    -0.06 0.03 -0.11  0.00
# a      2.45 0.03  2.40  2.50
# sigma  0.72 0.02  0.68  0.76

"Age has a negative effect, but it is uncertain as it crosses zero in in the 89%
credible interval. Since age could be confounder of the effect of Yoe on score,
we looked at the correlation between Age and Yoe."


rethinking::compare(m1.1,m1.2, func=PSIS) 
#PSIS = Pareto-smoothed importance sampling
#        PSIS    SE dPSIS   dSE pPSIS weight
# m1.1 5284.1 42.52   0.0    NA   2.6      1
# m1.2 5425.2 38.64 141.1 20.77   2.5      0

rethinking::compare(m1.1,m1.2, func=WAIC)
#WAIC = Widely Applicable Information Criteria
#        WAIC    SE dWAIC   dSE pWAIC weight
# m1.1 5284.0 42.59     0    NA   2.6      1
# m1.2 5425.1 38.61   141 20.79   2.5      0

#Conditioning both on Age and YoE
m1.4.1 <- quap(
  alist(
    score ~ dnorm( mu , sigma ) ,
    mu <- a + ba*ages + by*yoe,
    by ~ dnorm( 0 , 1 ) ,
    ba ~ dnorm( 0 , 1 ) ,
    a ~ dnorm( 0, 1 ),
    sigma ~ dexp(1)
  ), data = df
) 
precis(m1.4.1)

#        mean   sd  5.5% 94.5%
# by     0.64 0.05  0.56  0.71
# ba    -0.46 0.08 -0.58 -0.33
# a      1.95 0.04  1.88  2.02
# sigma  1.48 0.03  1.43  1.53


#-----------------
"TEST DURATION"
"Outliers in DURATION"
"Code comprehension studies show that a programmer takes from 12 to 24 seconds is also the 
average minimum time to read one line of code."

"The lower cut to the minimum time to read all 5 questions and corresponding lines of code
in the qualification test. 
 Since the test has 5 questions, each question 
requires the inspection of one line of code, that would require the programmer from 60s to 120s.
We chose 60s (1 min) as the minimum time-effort one need to read and answer all 5 questions"

df <- df[df$testDuration_minutes<=12 & df$testDuration_minutes>=1 ,]
boxplot(df$testDuration_minutes)
summary(df$testDuration_minutes)
#   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
# 1.000   3.329   5.372   7.267   9.080  41.703


#Conditioning both on Age and YoE and testDuration
m1.4.2 <- quap(
  alist(
    score ~ dnorm( mu , sigma ) ,
    mu <- a + ba*ages + by*yoe + bd*testDuration_minutes,
    by ~ dnorm( 0 , 1 ) ,
    ba ~ dnorm( 0 , 1 ) ,
    bd <- dnorm( 0 , 1 ) ,
    a ~ dnorm( 0, 1 ),
    sigma ~ dexp(1)
  ), data = df
) 
precis(m1.4.2)

#
#        mean   sd  5.5% 94.5%
# by     0.60 0.05  0.53  0.67
# ba    -0.51 0.08 -0.63 -0.39
# bd     0.15 0.02  0.12  0.18
# a      1.25 0.09  1.12  1.39
# sigma  1.43 0.03  1.38  1.48

"All coefficients CI do not cross zero. 
Particularly about duration coefficient, all other variables fixed, for every minute the
person gains 0.15 points. So on average, to increase one point it would be necessary to
spend 6.67 minutes more. 

Note however that we would expect that duration (as well as other variables) are 
not linear with score increase...
"

"Prior Simulation for m1.4 and m1.5.1
 Value with prior variance= 1. Tried a range of values. 
 Stricter priors with smaller than one values 0.5, 0.2, 0.1
 Flatter priors with larger than one values 1, 5, 7, 9 
 Coefficients did not change with values larger than one. 
 Approximation did not converge with values larger than 10. 
"
#Value with priors variance = 1.0
#        mean   sd  5.5% 94.5%
# by     0.57 0.04  0.51  0.64
# ba    -0.39 0.07 -0.51 -0.27
# a      2.04 0.04  1.97  2.10
# sigma  1.54 0.03  1.49  1.58

"After deconfounding, we can see that the effects of yoe and 
age got clearer. The effect of yoe got stronger (by in m1.1 
versus m1.4). The effect of age got stronger and its credible 
interval outside zero (m1.1 versus m1.4)"

rethinking::compare(m1.1,m1.2,m1.4, func=PSIS) 
#       PSIS    SE dPSIS   dSE pPSIS weight
# m1.4 5330.4 42.72   0.0    NA   3.5      1 
# m1.1 5355.4 42.52  25.0  9.42   2.4      0
# m1.2 5505.1 38.44 174.8 24.23   2.5      0
rethinking::compare(m1.1,m1.2,m1.4, func=WAIC) 
#        WAIC    SE dWAIC   dSE pWAIC weight
# m1.4 5330.2 42.70   0.0    NA   3.4      1
# m1.1 5355.6 42.35  25.4  9.35   2.5      0
# m1.2 5505.2 38.49 175.0 24.27   2.5      0


#-----------------------------------------------------------
"INTERACTIONS 
- Does age also has an influence on the strenght of the effect of yoe on score? 
- i.e., being of an older or younger age makes a same level of yoe count more or less towards the score?
"
m1.5.1 <- quap(
  alist(
    score ~ dnorm( mu , sigma ) ,
    mu <- a + bya*yoe*ages +ba*ages +by*yoe,
    bya ~ dnorm( 0 , 1 ) ,
    ba ~ dnorm( 0 , 1 ) ,
    by ~ dnorm( 0 , 1 ) ,
    a ~ dnorm( 0, 1 ),
    sigma ~ dexp(1)
  ), data = df
) 
precis(m1.5.1)

m1.5.2 <- quap(
  alist(
    score ~ dnorm( mu , sigma ) ,
    mu <- a + bya*yoe*ages +ba*ages,
    bya ~ dnorm( 0 , 1.0 ) ,
    ba ~ dnorm( 0 , 1.0 ) ,
    a ~ dnorm( 0, 1.0 ),
    sigma ~ dexp(1)
  ), data = df
) 

precis(m1.5.2)


m1.5.3 <- quap(
  alist(
    score ~ dnorm( mu , sigma ) ,
    mu <- a + bya*yoe*ages,
    bya ~ dnorm( 0 , 1.0 ) ,
    a ~ dnorm(0, 1.0 ),
    sigma ~ dexp(1)
  ), data = df
) 

precis(m1.5.3)

m1.5.4 <- quap(
  alist(
    score ~ dnorm( mu , sigma ) ,
    mu <- a + bya*yoe*ages + by*yoe,
    bya ~ dnorm( 0 , 1.0 ) ,
    by ~ dnorm( 0 , 1.0 ) ,
    a ~ dnorm(0, 1.0 ),
    sigma ~ dexp(1)
  ), data = df
)


"About interaction YoE and Age
Interaction is positive only when a term for yoe is not present (m.1.5.2, bya=0.05 [0.02,0.08] and
m1.5.3 bya==0.03 [0.02,0.08]. 
However, when the slope for yoe (by) is present, the interaction term can present zero value 
in their credible intervals (m1.5.1, bya=-0.03 [], m1.5.4, bya=-0.04 [-0.07,0.00]). 
Meanwhile in these models m1.5.1 and m1.5.4, by has positive values for all the
credible intervals.

These models do not show that participants' age influence the effect of yoe on score, i.e.,
we could not see any moderation effect of age.
"

#---------------------
"OVERFITTING 
- How do models compare in terms of overfitting?
Models with age, yoe,and interaction between yoe and age performed better both in terms 
of parameters being  within credible intervals as well as presenting lower overfitting 
measures (PSIC and WAIC, which agreed with other)."

rethinking::compare(m1.5.1, m1.5.2, m1.5.3, m1.5.4, m1.4, func=PSIS)
#          PSIS    SE dPSIS   dSE pPSIS weight
# m1.5.1 5321.0 43.37   0.0    NA   4.2   0.99
# m1.4   5330.2 42.78   9.3  5.13   3.4   0.01
# m1.5.4 5343.4 43.00  22.5  8.85   3.1   0.00
# m1.5.3 5470.2 39.65 149.3 23.31   2.6   0.00
# m1.5.2 5470.9 39.57 150.0 23.29   3.4   0.00
rethinking::compare(m1.5.1, m1.5.2, m1.5.3, m1.5.4, m1.4, func=WAIC)
#          WAIC    SE dWAIC   dSE pWAIC weight
# m1.5.1 5320.8 43.40   0.0    NA   4.1   0.99
# m1.4   5330.3 42.81   9.6  5.21   3.4   0.01
# m1.5.4 5343.6 43.02  22.8  8.77   3.2   0.00
# m1.5.3 5470.0 39.55 149.2 23.40   2.5   0.00
# m1.5.2 5470.7 39.61 150.0 23.41   3.3   0.00

#------------------------------------

#Plotting models m1.4 and m1.5.1
"Plot the Posterior with corresponding variance (shaded region)"

#Generate simulated input data of yoe increment by one year
Yoe_seq <- seq( from=min(df$yoe) , to=max(df$yoe) , by=1) 
Ages_quantiles <- quantile(df$ages)
Ages_1stQ <- Ages_quantiles[1]
Ages_3rdQ <- Ages_quantiles[3]
Ages_median <- median(df$ages) 

ages_set <- Ages_median

#sample from the posterior distribution, and then compute
#for each case in the data and sample from the posterior distribution.
mu <- link(m1.4, data = data.frame(yoe=Yoe_seq,ages=ages_set))
#Compute vectors of means
mu.mean = apply(mu,2,mean)
mu.HPDI = apply(mu,2,HPDI, prob=0.89) #mean with highest posterior density interval

#Simulates score by extracting from the posterior, but now also
#considers the variance
sim1.4 <- sim(m1.4, data=list(yoe=Yoe_seq, ages=ages_set)) 
score.PI = apply(sim1.4,2, PI, prob=0.89) #mean with the percentile intervals

plot(score ~ yoe, df,col=col.alpha(rangi2,0.5)) #plot raw data
title(paste("M1.4 posterior score ","yoe and 1stQ, 3rdQ, Median ages"))

#plot the Map line and interval more visible
lines(Yoe_seq,mu.mean)

#plot the shaded region with 89% HPDI
shade(mu.HPDI,Yoe_seq)

#plot the shaded region with 89% PI
shade(score.PI,Yoe_seq)

"Lines are mostly parallel, changing only a little bit the intercept.
Age_1stQ being higher, Median in the middle, and Age_3rdQ lower."

#Plotting models m1.4 and m1.5.1
"Plot the Posterior with corresponding variance (shaded region)"

#Generate simulated input data of yoe increment by one year
ages_seq <- seq( from=min(df$ages) , to=max(df$ages) , by=1) 
yoe_quantiles <- quantile(df$yoe)
yoe_1stQ <- yoe_quantiles[1]
yoe_3rdQ <- yoe_quantiles[3]
yoe_median <- median(df$yoe) 

yoe_fixed <- yoe_1stQ

#sample from the posterior distribution, and then compute
#for each case in the data and sample from the posterior distribution.
mu <- link(m1.4, data = data.frame(ages=ages_seq,yoe=yoe_fixed))
#Compute vectors of means
mu.mean = apply(mu,2,mean)
mu.HPDI = apply(mu,2,HPDI, prob=0.89) #mean with highest posterior density interval

#Simulates score by extracting from the posterior, but now also
#considers the variance
sim1.4 <- sim(m1.4, data=list(ages=ages_seq, yoe=yoe_fixed)) 
score.PI = apply(sim1.4,2, PI, prob=0.89) #mean with the percentile intervals

plot(score ~ ages, df,col=col.alpha(rangi2,0.5)) #plot raw data
title(paste("M1.4 posterior score ","ages and 1stQ, 3rdQ, Median yoe"))

#plot the Map line and interval more visible
lines(ages_seq,mu.mean)

#plot the shaded region with 89% HPDI
shade(mu.HPDI,ages_seq)

#plot the shaded region with 89% PI
shade(score.PI,ages_seq)

"Lines are parallel going doin. The change was only a little bit the intercept.
yoe_1stQ being lower than Median and yoe_3rdQ, which
overlap, because median and 3rd quartile of yoe are almost the same."



#-------------------------------------
"Generalization. Do these models generalize to subgroups of participants, or 
in other words, are there other known variables that could also be confounders
of the effect of yoe and age on score? Next we look at gender and country"


#GENDER
#Conditioning both on Age and YoE and on Gender (indicador variable)
m1.6.1 <- quap(
  alist(
    score ~ dnorm( mu , sigma ) ,
    mu <- a[gender_id] + ba[gender_id]*ages + by[gender_id]*yoe,
    by[gender_id] ~ dnorm( 0 , 1 ) ,
    ba[gender_id] ~ dnorm( 0 , 1 ) ,
    a[gender_id] ~ dnorm(0, 1),
    sigma ~ dexp(1)
  ), data = df
) 
precis(m1.6.1,depth=2)

#Model with interaction between yoe and ages
m1.6.2 <- quap(
  alist(
    score ~ dnorm( mu , sigma ) ,
    mu <- a[gender_id] + ba[gender_id]*ages + by[gender_id]*yoe+bya[gender_id]*yoe*ages,
    by[gender_id] ~ dnorm( 0 , 1 ) ,
    ba[gender_id] ~ dnorm( 0 , 1 ) ,
    bya[gender_id] ~ dnorm( 0 , 1 ) ,
    a[gender_id] ~ dnorm(0, 1),
    sigma ~ dexp(1)
  ), data = df
) 
precis(m1.6.2,depth=2)

labels1 <- paste( "a[" , 1:3 , "]:" , levels(df$gender) , sep="" )
labels2 <- paste( "by[" , 1:3  , "]:" , levels(df$gender) , sep="" )
labels3 <- paste( "ba[" , 1:3  , "]:" , levels(df$gender) , sep="" )
labels4 <- paste( "bya[" , 1:3  , "]:" , levels(df$gender) , sep="" )


precis_plot( precis( m1.6.1 , depth=2 , pars=c("by","ba","bya","a")) , 
             labels=c(labels2,labels3,labels1),xlab="qualification score" )
title("Model1.6 conditioned on age, yoe, and gender")

"Model 1.6.1 and Model 1.6.2
Regarding male and female gender groups, the credible interval for 
coefficients by, ba, a do cross zero. Moreover, the sign of these coefficients
is the same as seen in the models for the whole participants (m1.4 and m1.5.1).
In this sense, we interpret that the model generalizes within male and female gender.

Concerning the interaction term coefficient bya, its credible intervals crosses zero
for all genders, but Male. Hence, we can only suggest that the interaction model
generalizes only for male participants.

Regarding the groups Other and Prefer_not_tell, the coefficients for by and ba
cross the zero for m1.6.1 and m1.6.2. The intercepts do not cross, but 
they overlap their credible interval for these two groups.
"

"
Regarding effect of gender on score, we can only analyze the effect of Male and Female,
because the CI of by, ba, and a do not cross zero. Does being male or female has distinct 
effect on the score? For by and ba we cannot tell because the CI for these coefficient
overlap. However, the intercepts 'a' for Male and Female do not overlap. Male intercept
has a is higher intercept. This means that Males start with a higher score on average than
the Female participants. Nonetheless this head start is of only 0.3 points of score in both
models m1.6.1 and m1.6.2, which is only 0.1 point larger than the size of the credible
interval for these intercept coefficients. "

"OVERFITTING BY GENDER. Model with interactions shows lower risk of overfitting"
rethinking::compare(m1.6.2,m1.6.1, func=WAIC)
#          WAIC    SE dWAIC  dSE pWAIC weight
# m1.6.2 5311.4 43.93   0.0   NA   9.6   0.99
# m1.6.1 5320.2 43.40   8.9 5.26   8.2   0.01
rethinking::compare(m1.6.2,m1.6.1, func=PSIS)
#          PSIS    SE dPSIS  dSE pPSIS weight
# m1.6.2 5312.2 44.01   0.0   NA  10.1   0.99
# m1.6.1 5320.8 43.40   8.5 5.25   8.4   0.01


#-----------
#COUNTRY
#Conditioning both on Age and YoE and on Country (indicador variable)
m1.7.1 <- quap(
  alist(
    score ~ dnorm( mu , sigma ) ,
    mu <- a[country_id] + ba[country_id]*ages + by[country_id]*yoe,
    by[country_id] ~ dnorm( 0 , 1 ) ,
    ba[country_id] ~ dnorm( 0 , 1 ) ,
    a[country_id] ~ dnorm(0, 1),
    sigma ~ dexp(1)
  ), data = df
) 
precis(m1.7.1,depth=2)

m1.7.2 <- quap(
  alist(
    score ~ dnorm( mu , sigma ) ,
    mu <- a[country_id] + ba[country_id]*ages + by[country_id]*yoe + bya[country_id]*yoe*ages,
    by[country_id] ~ dnorm( 0 , 1 ) ,
    ba[country_id] ~ dnorm( 0 , 1 ) ,
    bya[country_id] ~ dnorm( 0 , 1 ) ,
    a[country_id] ~ dnorm(0, 1),
    sigma ~ dexp(1)
  ), data = df
) 
precis(m1.7.2,depth=2)


labels1 <- paste( "a[" , 1:3 , "]:" , levels(df$country_labels) , sep="" )
labels2 <- paste( "by[" , 1:3  , "]:" , levels(df$country_labels) , sep="" )
labels3 <- paste( "ba[" , 1:3  , "]:" , levels(df$country_labels) , sep="" )
labels4 <- paste( "bya[" , 1:3  , "]:" , levels(df$country_labels) , sep="" )


precis_plot( precis( m1.7.2 , depth=2 , pars=c("ba","by","bya","a")) , 
             labels=c(labels2,labels3,labels4,labels1),xlab="qualification score" )
title("Model1.7 conditioned on age, yoe, and country")

"For models 1.7.1 and 1.7.2
the CI for by does not cross zero only for US and Other country groups.
the CI for ba and bya do not cross zero only for US

Even though the CI of the intercepts 'a' for all countries do not cross zero, 
their CIs overlap. Hence, we cannot say depending on country of origin the person 
would have a distinct fixed initial effect on score.
"

"OVERFITTING BY COUNTRY Model with interactions shows lower risk of overfitting"
rethinking::compare(m1.7.2,m1.7.1, func=WAIC)
#          WAIC    SE dWAIC  dSE pWAIC weight
# m1.7.2 5320.2 43.75   0.0   NA  11.3   0.98
# m1.7.1 5328.3 43.26   8.1 5.98   9.1   0.02
rethinking::compare(m1.7.2,m1.7.1, func=PSIS)
#          PSIS    SE dPSIS  dSE pPSIS weight
# m1.7.2 5320.2 43.90   0.0   NA  11.3   0.98
# m1.7.1 5328.3 43.29   8.1 5.83   9.1   0.02

#-----------
#PROFESSION
#Conditioning both on Age and YoE and on Profession (indicador variable)
m1.8.1 <- quap(
  alist(
    score ~ dnorm( mu , sigma ) ,
    mu <- a[profession_id] + ba[profession_id]*ages + by[profession_id]*yoe,
    by[profession_id] ~ dnorm( 0 , 1 ) ,
    ba[profession_id] ~ dnorm( 0 , 1 ) ,
    a[profession_id] ~ dnorm(0, 1),
    sigma ~ dexp(1)
  ), data = df
) 
precis(m1.8.1,depth=2)

m1.8.2 <- quap(
  alist(
    score ~ dnorm( mu , sigma ) ,
    mu <- a[profession_id] + ba[profession_id]*ages + by[profession_id]*yoe + bya[profession_id]*yoe*ages,
    by[profession_id] ~ dnorm( 0 , 1 ) ,
    ba[profession_id] ~ dnorm( 0 , 1 ) ,
    bya[profession_id] ~ dnorm( 0 , 1 ) ,
    a[profession_id] ~ dnorm(0, 1),
    sigma ~ dexp(1)
  ), data = df
) 
precis(m1.8.2,depth=2)


labels1 <- paste( "a[" , 1:5 , "]:" , levels(df$profession) , sep="" )
labels2 <- paste( "by[" , 1:5  , "]:" , levels(df$profession) , sep="" )
labels3 <- paste( "ba[" , 1:5  , "]:" , levels(df$profession) , sep="" )
labels4 <- paste( "bya[" , 1:5  , "]:" , levels(df$profession) , sep="" )


precis_plot( precis( m1.8.1 , depth=2 , pars=c("ba","by","a")) , 
             labels=c(labels2,labels3,labels1),xlab="qualification score" )
title("Model1.8.1 conditioned on age, yoe, and profession")


precis_plot( precis( m1.8.2 , depth=2 , pars=c("ba","by","bya","a")) , 
             labels=c(labels2,labels3,labels4,labels1),xlab="qualification score" )
title("Model1.8.2 interaction model conditioned on age, yoe, and profession")

"For model 1.8.1 and 1.8.2 the results generalize for all professions except Graduate Students (by crosses zero)
and Professionals ba crosses zero. These means that age is not a factor for professionals, whereas
years of experience is not a factor for graduates.

Concerning the interaction terms in 1.8.2, the coefficients for Graduates and Others cross zero. 
For all other professions the credible interval for the interaction coefficient is on a negative side.

Note that for all the other coeficients and professions that do not cross zero, their variance 
overlaps, so we cannot say that age or yoe has a strong effect for certain professions.

Regarding intercepts, except for Professional Developer, all other
overlap. Hence profession has a distinct effect on score only if the
person is either a professional developer or nor. 

To compute the magnitude of the effect, we approximated a new
model. 1.8.3 that considers only these two groups professionals or not.

"
#Creates new identifiers for professsional (1) or non-professional (2)
df$is_professional_id <- sapply(df$profession_id,function(x){ ifelse(x==1,1,2)})

m1.8.3 <- quap(
  alist(
    score ~ dnorm( mu , sigma ) ,
    mu <- a[is_professional_id] + ba[is_professional_id]*ages + by[is_professional_id]*yoe,
    by[is_professional_id] ~ dnorm( 0 , 1 ) ,
    ba[is_professional_id] ~ dnorm( 0 , 1 ) ,
    a[is_professional_id] ~ dnorm(0, 1),
    sigma ~ dexp(1)
  ), data = df
) 
precis(m1.8.3,depth=2)

m1.8.4 <- quap(
  alist(
    score ~ dnorm( mu , sigma ) ,
    mu <- a[is_professional_id] + ba[is_professional_id]*ages + by[is_professional_id]*yoe +bya[is_professional_id]*yoe*ages,
    by[is_professional_id] ~ dnorm( 0 , 1 ) ,
    ba[is_professional_id] ~ dnorm( 0 , 1 ) ,
    bya[is_professional_id] ~ dnorm( 0 , 1 ) ,
    a[is_professional_id] ~ dnorm(0, 1),
    sigma ~ dexp(1)
  ), data = df
) 
precis(m1.8.4,depth=2)

"Looking at the intercepts for m1.8.3 and m1.8.4, their CI do not overlap. 
The difference between the intercepts is about half point (0.5 in m1.8.3 and 0.44 in m1.84)."


"OVERFITTING BY profession Model with interactions shows lower risk of overfitting"
rethinking::compare(m1.8.2,m1.8.1, func=WAIC)
#          WAIC    SE dWAIC   dSE pWAIC weight
# m1.8.2 5234.0 44.89   0.0    NA  18.1      1
# m1.8.1 5257.5 44.44  23.5 10.17  15.3      0
rethinking::compare(m1.8.2,m1.8.1, func=PSIS)
#          PSIS    SE dPSIS   dSE pPSIS weight
# m1.8.2 5234.0 44.99   0.0    NA  18.3      1
# m1.8.1 5257.1 44.25  23.1 10.13  15.1      0
