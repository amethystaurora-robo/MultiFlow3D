# ---
# jupyter:
#   jupytext:
#     text_representation:
#       extension: .py
#       format_name: light
#       format_version: '1.5'
#       jupytext_version: 1.15.2
#   kernelspec:
#     display_name: Python 3 (ipykernel)
#     language: python
#     name: python3
# ---

import pandas as pd
import numpy as np


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

    #Update user on status of application
    print('Creating file...')
    #create ID columns
    #make a list of incrementing numbers * number of processors
    total_processors_num = num_domains*num_processors
    domains_processors_ID_list = list(range(total_processors_num))
    #create an entry separated by a semi-colon
    # Split the list and join with semicolon
    ID_list = [
        " ".join(map(str, domains_processors_ID_list[i:i + num_processors]))
        for i in range(0, len(domains_processors_ID_list), num_processors)
    ]
    domain_processor_df = pd.DataFrame({'Sub-Domain ID': ID_list,
        'Num Processors': num_processor_list, 'Processor ID': ID_list})

    #Update user on status of application
    print('Writing file...')
    # Hard-code the length of the equal signs line to 49
    equals_line = "=" * 49

    header = f"{num_domains} number of domains\n{num_processors} number of processors\n{equals_line}\n"

    # Writing to the .cin file
    try:
        with open('mdmap_test.cin', "w") as f:
            # Write the header
            f.write(header)
        
            # Write the DataFrame as a space-separated format with no column or row names, with centered rows
            for index, row in domain_processor_df.iterrows():
                f.write(f"{str(row['Sub-Domain ID']).rjust(4)}  "
                        f"{str(row['Num Processors']).rjust(4)}  "
                        f"{str(row['Processor ID']).rjust(4)}\n")
            # Add the line of equals signs at the end of the file
            f.write(equals_line + "\n")
    
        # If the file is written successfully, print a success message
        print(f"File '{'mdmap_test.cin'}' created successfully!")
    
    except Exception as e:
        # Handle any errors that occur during file creation
        print(f"An error occurred while creating the file: {e}")
        
    return 


# Function to center the entire file after writing it, takes file_path as argument
def center_file(file_path):
    # Read the content of the file
    with open(file_path, 'r') as f:
        content = f.readlines()

    # Find the max length of any line
    max_width = max(len(line) for line in content)

    #Update user on status of application
    print("Centering content...")
    
    # Center align every line in the file content
    centered_content = [line.strip().center(max_width) + "\n" for line in content]

     # Write the centered content back to the file with try-except for error handling
    try:
        with open(file_path, 'w') as f:
            f.writelines(centered_content)
        print(f"File centered successfully. Your file {file_path} is now in your working directory.")
    except Exception as e:
        print(f"An error occurred while writing the file: {e}")
    


# Call the function to create the .cin file
create_cin_file_with_columns()

center_file('mdmap_test.cin')

# +
#infodom.cin
#control.cin

# +
#optional other files
#geom.cin
#LPT.cin
#rough_bed.cin
