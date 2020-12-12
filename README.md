# ECEM
Entropy-based crowd evacuation model

## Environment Dependency

Please download NetLogo simulation software with version 6.0.4 
from http://ccl.northwestern.edu/netlogo/ and follow its instructions
to install it. 

## Run the program
Please follow the below steps to run the program.
* step 1: open ECEM.nlogo by NetLogo or import the ECEM.code into NetLogo;
* step 2: click on the tab “Interface” at the top of NetLogo’s main window;
* step 3: (optional) check or modify the parameters in the six Input Boxes:
    * “**usp**”: the proportion of small social groups in total evacuation;
    * “**usd**”: the comfort distance for the small groups;
    * “**uws**”,”**uwe**”,”**uwa**”,”**uwc**”: weights of the velocity components;
* step 4: (optional) click the tab “code”, and edit initialization function to
re-assign the other parameters in the simulation, including the total number 
of evacuees, individual view distance and angle, etc.;
* step 5: for single evacuation simulation, 
    * press the “Setup” button, the command center will show 
    “observer:’Initialization completed!’”; then press the “Go” button
     to start simulation;
    * when all the agents escape from the exit, the simulation is finished;
     and the evacuation time and maximum instantaneous entropy of the crowd 
     during evacuation are displayed in the command center window;
    * the changes of population velocity and entropy can be observed from
    the plot diagrams on the right side;
    * right-click the plot and select “export” item to save the data 
    as a Excel file.
* step 6: for multiple evacuation simulation and the average result,
determine the number of simulation trials in the “num” Input box; 
then press the “Average” button. When all the simulations are complete, 
the command center outputs the average evacuation time and 
maximum entropy of the crowd.
