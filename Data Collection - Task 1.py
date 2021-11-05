# Project: "Magic: The Gathering"
# Picchia - Petroni - Redaelli
# Task 1: Data Collection

# Import the required libraries
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
for number in range(1, 624):
    response = requests.get("https://api.magicthegathering.io/v1/cards?page={}".format(number)) # GET request
    page = json.loads(response.text) # Extract the text from the response
    #print(response.headers["ratelimit-remaining"]) # Print the proportion of API request per hour remaining (out of 1000)
    dataset["cards"] += page["cards"] # Store the retrieved data
    print("Page number: {}".format(number)) # Keep track of the progess

# Check the total number of retrieved observations
n_obs = len(dataset["cards"])
print("Number of retrieved observations: {}".format(n_obs))

# Initialize a new dictionary
final_dataset = {"cards":[]}

# Select 10K observations at random, without replacement
# Preliminary data cleaning:
# avoid including cards for which the "multiverseid" parameter is NULL (further info in the Documentation)

datasetsize = 0 # Keep track of the number of observations selected
obs_selected = set() # Initialize a set containing the indexes of the selected observations

random.seed(2021) # Set seed for reproducibility
while datasetsize<10000:
    index = random.randint(0, n_obs-1) # Select a random observation
    if index in obs_selected: continue # Ignore the observation if it was already selected
    if "multiverseid" in dataset["cards"][index]: # If "multiverseid" is NOT NULL
        myobs = dataset["cards"][index]
        final_dataset["cards"].append(myobs) # Add the observation to the final dataset
        obs_selected.add(index) #Add observation index to the set
        datasetsize+=1
        print("Observation number: {}".format(datasetsize))  # Keep track of the progess

# Save the dataset in a .json file. Indent parameter set to 4 to prettify visualization
with open("mtg_dataset.json", "w") as myfile:
    json.dump(final_dataset, myfile, indent=4)

# Load .json file
with open("mtg_dataset.json", "r") as myfile:
    mtg_dataset = json.load(myfile)

# Check the number of observations in the final dataset
print("Number of observations in the final dataset: {}".format(len(mtg_dataset["cards"])))