# Reproducing the recorded experiments

Run `run_report_simulations` from the `simulation` directory in MATLAB. Do not run directly inside a ZIP. Requirements: MATLAB R2025b, Simulink, Simscape, Simscape Electrical and Stateflow. Earlier releases have not been verified.

The model uses a 1-second local solver step and averaged energy-system components. Each of the five cases runs for 600 seconds from 700 g tank mass. Current reference selects electrolysis when positive, fuel-cell mode when negative and OFF at zero. Normalized irradiance 1.0 represents 1000 W/m²; 0.5 represents 500 W/m².

The runner attempts extra PV measurement instrumentation. In the archived run this produced `Invalid line specifier` in `addPVMeasurements`. The runner rolled back the sensor edits, reloaded the baseline and completed all five cases. The error is preserved in `PV_INSTRUMENTATION_ERROR.txt`. A repeat may show this same warning. No successful PV delivery or bus-voltage measurement is claimed.

Inspect `RESULT_STATUS.txt`, `run_summary.csv` and `run_log.txt` after running. CSV columns are `Time_s` and `Value`; units appear in the filenames. FIG files can be opened in MATLAB, and MAT files preserve SimulationOutput objects. Verify against the archived summary rather than expecting bit-identical output across releases.

The historical README and code comments inside `simulation/` describe the kit when it was first prepared, before execution on the student's computer. This repository's README and archived evidence describe the subsequent completed run. No MATLAB execution was performed by the assistant.
