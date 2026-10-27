GROUP 25 - MATLAB / SIMULINK REPORT EXPORT KIT

HOW TO RUN
1. Extract this entire ZIP to a new folder on your computer.
2. Open MATLAB R2025b. Set Current Folder to Group25_Simulation_Kit,
   the folder containing run_report_simulations.m (not its src subfolder).
3. In the Command Window enter:

       run_report_simulations

4. Wait for the five simulation cases to finish. Each runs for 600 seconds
   of SIMULATED time. Actual computer time depends on model compilation.
5. The Command Window prints UPLOAD THIS FILE and the path to a ZIP named
   report_outputs_<date_and_time>.zip. Upload that ZIP to this conversation.
   It includes the graphs, diagrams, raw results, code and diagnostic log.
   It is also created when setup or a simulation fails, where possible.

If MATLAB says the function is not found, you are in the wrong folder.
If an error prevents ZIP creation, upload the report_outputs_* folder as a
ZIP, or paste the red error text. Do not substitute a previous run's graphs.

REQUIREMENTS AND EXECUTION STATUS
MATLAB R2025b, Simulink, Simscape, Simscape Electrical and Stateflow.
No Report Generator toolbox, Python installation or Microsoft Word is needed.
This runner was prepared and statically checked against your uploaded model.
It has NOT been executed here: the assistant's environment has no MATLAB.
Successful compilation and numerical results must be checked on your MATLAB.

WHAT IS INCLUDED
src/ contains your uploaded model, parameter classes, physical component
sources, input files, icons and original live-script explanation. Old caches
and backup model versions are omitted. The original project licence and
upstream README are included. Your uploaded microgrid.slx is unchanged.

The runner creates microgrid_report_run.slx in a new timestamped output
folder. It adds data logging and attempts to add ideal measurement sensors
to that model copy. It never saves over src/microgrid.slx. MATLAB's base
workspace receives the original project's initialization variables.

TESTS
Case       Current reference   Normalized irradiance   Duration
EL_100A       +100 A                  1.0               600 s
FC_200A       -200 A                  1.0               600 s
OFF              0 A                 1.0               600 s
PV_1000          0 A                 1.0               600 s
PV_500           0 A                 0.5               600 s

Every test starts with the model's initial tank mass of 700 g.
Normalized irradiance 1.0 represents 1000 W/m^2; 0.5 represents 500 W/m^2.
The supplied demand profile and grid connection remain active.
Local solver step: 1 s, matching your uploaded model. These are averaged
energy-system tests, not PWM or motor-current transient simulations.

ACTUAL MEASUREMENTS
Stored hydrogen mass (g), net hydrogen flow (g/s), signed reference (A),
calculated PV component power (W), and existing EL/FC stack measurements.
The added PV current sensor is in series with the converter's positive
output, positive from converter toward the DC bus. The voltage sensor is
connected across the converter's positive and negative output terminals.
Their product is delivered PV power (W). Voltage is grid-supported.
If this instrumentation fails to compile, the runner restores the saved
baseline model copy, writes PV_INSTRUMENTATION_ERROR.txt, and attempts the
original measurements. Figure 5.5 is then omitted, not approximated.

REPORT INSERTION MAP
Figure 3.1: overall explanatory architecture diagram to be composed during
            report assembly from the verified circuit and model scope.
Figure 3.2: diagrams/Fig_3_2_Main_model.png
Figure 3.3: diagrams/Fig_3_3_URFC_circuit.png
            with diagrams/Operation_mode_chart.png as a companion.
Figure 3.4: diagrams/Fig_3_4_PV_measurement_circuit.png
Figure 5.1: Fig_5_1_EL_hydrogen.png
Figure 5.2: Fig_5_2_FC_hydrogen.png
Figure 5.3: Fig_5_3_OFF_hydrogen.png
Figure 5.4: Fig_5_4_PV_irradiance_comparison.png
Figure 5.5: Fig_5_5_PV_delivery_and_bus_voltage.png, if sensors work.
Figure 5.6: NOT generated. The proposed 24-hour power-balance/dispatch test
            needs a separate integrated control and measurement setup.
Annexure B: code/ contains the initialization, physical sources and runner.
Tables 5.1/5.2: replace earlier approximate values with the logged CSV data.
Table 5.3: not populated; no optimal-controller comparison is performed.

OUTPUT CONTENTS
PNG: 300 dpi report images, generated from logged numerical data.
FIG: editable MATLAB graphs.
CSV: one file per scalar logged signal, with Time_s and Value columns.
     Signal names include their units (e.g. H2_mass_g.csv).
MAT: complete Simulink SimulationOutput objects for each successful run.
run_summary.csv: final time, initial/final mass, fitted mass slope after
     60 s, ideal command-based slope, tank-range check and error messages.
run_log.txt: MATLAB version, products, progress and diagnostic messages.
RESULT_STATUS.txt: completed-run count and scope of evidence, if setup succeeds.
diagrams/: exports of the actual Simulink subsystems and Stateflow chart.
code/: exact source files used for the run.

HOW TO INTERPRET THE CHECKS
Ideal command-based hydrogen slopes are +0.0104465979 g/s for +100 A,
-0.0208931958 g/s for -200 A and zero for OFF (2 electrons per molecule,
10 cells). These are theoretical checks, NOT substituted simulation data.
The fitted slopes and final masses are calculated only from actual logs.
Startup, actual current and solver settings may affect agreement.
The present tank-limit stop blocks are commented out. The runner reports
out-of-range mass after each run; it does not implement tank protection.
Reported signed stack power follows existing sensor orientation; it is
not automatically fuel-cell power delivered to the DC bus.

The model is grid-connected and has no motor-speed controller. Calculated
PV power is distinct from measured converter delivery. Hydrogen inventory
alone does not establish electrical efficiency or independent bus regulation.
No 24-hour dispatch, optimal-control comparison or motor-speed test is claimed.

After the output ZIP is uploaded, the report can be updated with the actual
graphs, circuit diagrams, code excerpts and checked result values. Pending
24-hour work can then be identified explicitly rather than filled with an
invented trace.

DOCUMENTATION USED
https://www.mathworks.com/help/simulink/slref/simulink.simulationinput.html
https://www.mathworks.com/help/simulink/slref/simulink.simulationinput.setblockparameter.html
https://www.mathworks.com/help/simulink/slref/signalproperties.html
https://www.mathworks.com/help/simulink/ug/print-from-the-matlab-command-line.html
https://www.mathworks.com/help/stateflow/ref/sfprint.html
https://www.mathworks.com/help/matlab/ref/exportgraphics.html
