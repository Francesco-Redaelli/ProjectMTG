# Project: "Magic: The Gathering"
# Picchia - Petroni - Redaelli
# Task 1: Data Collection

# Import libraries
import requests
import json
import pandas

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

# Save the dataset in a .json file. Indent parameter set to 4 to prettify visualization
with open("mtg_dataset.json", "w") as myfile:
    json.dump(dataset, myfile, indent=4)

# Load .json file
with open("mtg_dataset.json", "r") as myfile:
    mtg_dataset = json.load(myfile)

# Check the total number of observations
print("Number of observations: {}".format(len(mtg_dataset["cards"])))






