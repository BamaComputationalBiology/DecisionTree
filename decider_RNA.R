library(randomForest)
library(ggplot2)

data <- read.csv(file="Celegans_candida.csv", header=TRUE) # load data file

data1 <- data[Origin!="No BLAST hit",1:10]

attach(data1)

ggplot(data1,aes(x=Ref_GC,y=Avg_fold,color=Origin)) + geom_point() + scale_y_log10() # visualize variable relationships

ggplot(data1,aes(x=Ref_GC,y=RNA_Avg_fold,color=Origin)) + geom_point() + scale_y_log10()

ggplot(data1,aes(x=RNA_Avg_fold,y=Avg_fold,color=Origin)) + geom_point() + scale_y_log10() + scale_x_log10()

ggplot(data1,aes(x=Avg_fold,y=RNA_Read_GC,color=Origin)) + geom_point() + scale_x_log10()

ggplot(data1,aes(x=Length,y=Avg_fold,color=Origin)) + geom_point() + scale_y_log10()

orig <- ifelse(Origin=="Candida","0","1") # mark observations by Origin

Train = sample(1:nrow(data1),0.33*nrow(data1)) # select training observations at random

data1.test <- data1[-Train,2:9] # select test observations

data1.train <- data1[Train,2:9] # select training observations

data.print <- data[c(2:9)] # print predictions for the entire dataset

orig.test <- orig[-Train] 

orig.train <- orig[Train]

set.seed(1) # set random seed

x <- cbind(data1.train,orig.train) # create labeled training dataset

tree.bag <- randomForest(orig.train~., x, mtry=2, importance=TRUE) # train the bagging tree

tree.pred <- predict(tree.bag,newdata=data1.test) # use the trained tree to predict origin for the test dataset

err <- mean(tree.pred != orig.test) # calculate error 

print(paste("Bagging test-error=",err)) # print error

importance(tree.bag) # print variable importances

varImpPlot(tree.bag) # plot variable importances

tree.print <- predict(tree.bag,newdata=data.print) # predict origin for the entire dataset

yz <- cbind(data,tree.print) # create a dataset with predicted origins

write.csv(yz,file="predictions.csv") # write the dataset with predicted origins to a file

