# IIP2020
Interactive Intelligent Products

##Midterm project - Self-checkout gesture based interface for supermarkets

[![Project demonstration on YouTube](https://img.youtube.com/vi/2WeqEVaqhww/0.jpg)](https://www.youtube.com/watch?v=2WeqEVaqhww)

###Progress

1. Data acquisition, collection of training data
We use three ultrasonic sensors. With these we can measure distance. We set a minimum and maximum distance to filter out unwanted movements. The sampleRate gets calculated based on the maximum distance, due to the speed of sound. 

In Processing, we collect the data using the "DataCollection" sketch. In this we set a segmentation threshold and a window size. The incoming data is turned into a separate differential signal. If the intensity of this signal meets the segmentation threshold it will start recording data for the selected label ("A", "B" or "C"). 

2. Model training
The model is trained with a linear support vector classifier (LSVC) with an initial C parameter of 64. It has a in-sample CV accuracy of 100%. 

3. Model optimisation
To increase performance of our model we need to:
Perform grid-search to see if we can lower C, which could on its turn reduce the change for overfitting and reduce the amount of out-of-sample errors. 
Use another classifier, such as k-nearest neighbours classifiers or kernel support vector classifier. 

4. Evaluation
To allow for better evaluation than anecdotal evidence, we should use the train-test split method. Then we can get a more accurate reading (CV accuracy) of how well our model performs. 

Future points of action:
- Use train-test split method to evaluate model
- Do grid search to allow for parameter optimisation
- Try out other classifiers such as KNN
- Better sensor setup (closer to each other)
- Better sensor choice, ultrasonic sensors are slow and with low precision (because of the long range)
- Better filtering of data. The segmentation gets triggered when one walks past the sensors. Large spikes because a hand moves in and out of range. The second one should be done on the Processing side, to still allow for activation because of these sudden changes. 
- More useful feature extraction (direction of movement is hard to tell by extracting only the mean and standard deviation). Maybe do a linear regression on the time-series and store it as a feature (angle of data)

All of these measures should allow for a more generalisable model. Right now it can be used correctly by performing a specific motion, but it would be ideal that it could detect a hand moving in different ways (fast, slow, independent on positioning). 