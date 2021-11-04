# Project: "Magic: The Gathering"
# Picchia - Petroni - Redaelli
# Task 1: Data Collection

# Import libraries
import requests
import json
import random

# Sample GET request
response = requests.get("https://api.magicthegathering.io/v1/cards")
print(response.headers["link"]) # Identify the total number of API pages available: 623 (to date)
# By using the PyCharm Debugger, it is possible to inspect the structure of the response.text object

# Initialize a dictionary having the same structure of the response.text data
dataset = {"cards":[]}

# Make a GET request to all the API pages and store the retrieved data
for number in range(1, 5):
    response = requests.get("https://api.magicthegathering.io/v1/cards?page={}".format(number)) # GET request
    page = json.loads(response.text) # Extract the text from the response
    #print(response.headers["ratelimit-remaining"]) # Print the proportion of API request per hour remaining (out of 1000)
    dataset["cards"] += page["cards"] # Store the retrieved data
    print("Page number: {}".format(number)) # Keep track of the progess

# Check the total number of observations
nobs = len(dataset["cards"])
print("Number of observations: {}".format(nobs))

# Initialize a new dictionary
final_dataset = {"cards":[]}

# Select 10K observation at random, without replacement
# Avoid including cards for which "multiverseid" is NULL
# (special editions of the same card, recorded as different observations)

datasetsize = 0

while datasetsize<100:
    index = random.randint(0, nobs-1) # Select a random observation
    if "multiverseid" in dataset["cards"][index]: # If "multiverseid" is NOT NULL
        print(dataset["cards"][index])
        final_dataset["cards"] += dataset["cards"][index]  # Add the observation
        datasetsize+=1
        print("Observation number: {}".format(datasetsize))  # Keep track of the progess

# Save the dataset in a .json file. Indent parameter set to 4 to prettify visualization
with open("mtg_dataset.json", "w") as myfile:
    json.dump(final_dataset, myfile, indent=4)

# Load .json file
with open("mtg_dataset.json", "r") as myfile:
    mtg_dataset = json.load(myfile)

# Check the final number of observations
print("Number of observations: {}".format(len(mtg_dataset["cards"])))