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

# +
#infodom.cin Sub-domain split and their coordinates
#sub-domain num depends on grid size and overall domain length
#num of cells per block needs to be less than 100
#user input for grid size, overall domain size for x,y,z
grid_size_x = float(input("What is the grid size for x?"))
grid_size_y = float(input("What is the grid size for y?"))
grid_size_z = float(input("What is the grid size for z?"))

domain_length = float(input("How long is your domain in meters?"))
domain_width = float(input("How wide is your domain in meters?"))
domain_height = float(input("How high is your domain in meters?"))

#user input for sub-domain, TO DO: ask about this, if it's user input or pre-determined
sub_domain_i = int(input("How many sub-domains do you want in the x direction?"))
sub_domain_j = int(input("How many sub-domains do you want in the y direction?"))
sub_domain_k = int(input("How many sub-domains do you want in the z direction?"))

#ghost cells, TO DO: also ask about this
ghost_cells = int(input("How many ghost cells would you like to create?"))

print("Calculating...")
#calculation for number of cells for whole domain
cell_num_x = domain_length/grid_size_x
cell_num_y = domain_width/grid_size_y
cell_num_z = domain_height/grid_size_z

#calculation for cells per block
#TODO try catch less than 100 cells per block
cells_per_block_x = cell_num_x/sub_domain_i
cells_per_block_y = cell_num_y/sub_domain_j
cells_per_block_z = cell_num_z/sub_domain_k

#cells per block with ghost cells
cells_with_ghost_x = cells_per_block_x+ghost_cells
cells_with_ghost_y = cells_per_block_y+ghost_cells
cells_with_ghost_z = cells_per_block_z+ghost_cells

#create df with 6 columns and 4 rows from infodom.cin example
infodom_initial_df = pd.DataFrame({'Grid Size': [grid_size_x,grid_size_y,grid_size_z,np.nan],
                                   'Overall Domain Size': [domain_length,domain_width,domain_height,np.nan],
                                   'Number of Cells for Whole Domain': [cell_num_x,cell_num_y,cell_num_z,cell_num_x*cell_num_y*cell_num_z],
                                   'Sub-domains': [sub_domain_i,sub_domain_j,sub_domain_k,sub_domain_i*sub_domain_j*sub_domain_k],
                                   'Cells per Block': [cells_per_block_x,cells_per_block_y,cells_per_block_z,cells_per_block_x*cells_per_block_y*cells_per_block_z],
                                   'Cells per Block with Ghost Cells': [cells_with_ghost_x,cells_with_ghost_y,cells_with_ghost_z,cells_with_ghost_x*cells_with_ghost_y*cells_with_ghost_z]})

# +
#generating input for the infodom.cin file
#specify coordinates of each block
#individual block dimension calculation
block_dimension_x = domain_length/sub_domain_i
block_dimension_y = domain_width/sub_domain_j
block_dimension_z = domain_height/sub_domain_k

#get total block num
total_block_num = sub_domain_i*sub_domain_j*sub_domain_k

#new df
#column 1 is a list iterating total_block_num times
domain = list(range(total_block_num))
rdiv = [1]*total_block_num

# -

def get_coords(sub_domain,block_dimension):
    #x1 and x2 for now, y1 and y2, z1 and z2
    #loop sub_domain times
    #counter x1 from 0
    counter = 0
    v1 = []
    v2 = []
    for i in range(sub_domain):
        v1.append(counter)
        counter = counter+block_dimension
        v2.append(counter)

    return v1,v2


x1,x2 = get_coords(sub_domain_i,block_dimension_x)
y1,y2 = get_coords(sub_domain_j,block_dimension_y)
z1,z2 = get_coords(sub_domain_k,block_dimension_z)

# +
#make x1,x2 lists repeat by sub_domain_j*sub_domain_k
x1_repeated = x1*sub_domain_j*sub_domain_k
x2_repeated = x2*sub_domain_j*sub_domain_k

y1_coords = []
y2_coords = []
z1_coords = []
z2_coords = []

#set counter for y coordinates,set variable for final coordinate in x2
ypos_counter = 0
last_x = x2[-1]

#loop through x coordinates, append y coordinates according to x position
for x in range(len(x1_repeated)):
    y1_coords.append(y1[ypos_counter])
    y2_coords.append(y2[ypos_counter])
    if ((x2_repeated[x] == last_x) & (ypos_counter !=len(y1)-1)):
        ypos_counter+=1
    elif ((x2_repeated[x] == last_x) & (ypos_counter==len(y1)-1)):
        ypos_counter=0

#define counter variables for x and z
zpos_counter = 0
counter = 0

#loop through x1_repeated and append z coordinates according to x value
while (counter < len(x1_repeated)):
    z1_coords.append(z1[zpos_counter])
    z2_coords.append(z2[zpos_counter])
    counter+=1
    if (counter == len(x1_repeated)/2):
        zpos_counter+=1
    if (zpos_counter > len(z1)):
        break

# +
#column 2 is a default of 1, need to ask about this
infodom_coord_df = pd.DataFrame({'Domain':domain,'rdiv':rdiv,'x1':x1_repeated,'x2':x2_repeated,
                                'y1':y1_coords,'y2':y2_coords,'z1':z1_coords,'z2':z2_coords})

print("Finished coordinate calculation.")
infodom_coord_df.head(20)


# -

def create_infodom():
    
    #Update user on status of application
    print('Writing file...')
    # Hard-code the length of the equal signs line to 49
    equals_line = "=" * 49

    header = f"{num_domains} number of domains\n"
    footer = f"{sub_domain_i} number of divisions in i\n{sub_domain_j} number of divisions in j\n{sub_domain_k} number of divisions in k\n"

    # Writing to the .cin file
    try:
        with open('infodom_test.cin', "w") as f:
            
            # Write the header
            f.write(header)
            f.write(equals_line + "\n")
            # Write the DataFrame as a space-separated format with no column or row names, with centered rows
            for index, row in infodom_coord_df.iterrows():
                f.write(f"{row['Domain']}  "
                        f"{row['rdiv']}  "
                        f"{row['x1']:.1f}  "
                        f"{row['x2']:.1f}  "
                        f"{row['y1']:.1f}  "
                        f"{row['y2']:.1f}  "
                        f"{row['z1']:.1f}  "
                        f"{row['z2']:.1f}\n")
            # Add the line of equals signs at the end of the file
            f.write(equals_line + "\n")
            f.write(footer)
    
        # If the file is written successfully, print a success message
        print(f"File '{'infodom_test.cin'}' created successfully!")
    
    except Exception as e:
        # Handle any errors that occur during file creation
        print(f"An error occurred while creating the file: {e}")
        
    return 


create_infodom()


#ask for user input: How many sub-domains do you want to create?
def create_mdmap_file_with_columns():
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
create_mdmap_file_with_columns()

center_file('mdmap_test.cin')
center_file('infodom_test.cin')



# +
#control.cin

# +
#optional other files
#geom.cin
#LPT.cin
#rough_bed.cin
