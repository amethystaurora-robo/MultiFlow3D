#!/usr/bin/env python
# coding: utf-8

# In[3]:


import pandas as pd
import numpy as np


# In[ ]:


#mdmap.cin
#this file has 3 columns, the sub-domain ID num(s), the number of processors assigned to the sub-domain, and the processor ID num(s)


# In[12]:


#infodom.cin
#ask for user input: How many sub-domains do you want to create?
def create_cin_file_with_columns():
    # Collecting user input for the number of domains and processors
    while True:
        try:
            num_domains = int(input("How many sub-domains do you want to create? "))
            if num_domains <= 0:
                print("Please enter a number greater than 0.")
            else:
                break  # Exit loop if a valid number is entered
        except ValueError:
            print("Invalid input! Please enter a valid number.")
        
    while True:
        try:
            num_processors = int(input("How many processors do you want assigned to each domain? (The default is 1)"))
            if num_processors <= 0:
                print("Please enter a number greater than 0.")
            else:
                break  # Exit loop if a valid number is entered
        except ValueError:
            print("Invalid input! Please enter a valid number.")

    #create processor_num column for file
    num_processor_list = []
    current_processor_num = 0
    while current_processor_num < num_domains:
        num_processor_list.append(num_processors)
        current_processor_num+=1

    #create ID columns
    #make a list of incrementing numbers * number of processors
    total_processors_num = num_domains*num_processors
    domains_processors_ID_list = list(range(total_processors_num))
    #create an entry separated by a semi-colon
    # Split the list and join with semicolon
    ID_list = [
        ";".join(map(str, domains_processors_ID_list[i:i + num_processors]))
        for i in range(0, len(domains_processors_ID_list), num_processors)
    ]
    domain_processor_df = pd.DataFrame({'Sub-Domain ID': ID_list,
        'Num Processors': num_processor_list, 'Processor ID': ID_list})

    return domain_processor_df
#TODO: make this into a .cin file with the same format as the one on Git
#make this executable with


# In[13]:


# Call the function to create the .cin file
create_cin_file_with_columns()


# In[ ]:


#control.cin


# In[ ]:


#optional other files
#geom.cin
#LPT.cin
#rough_bed.cin

