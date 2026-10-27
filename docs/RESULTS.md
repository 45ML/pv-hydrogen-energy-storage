# Results and limits of the evidence

The authoritative numerical record is `results/report_outputs_20261024_052034_911/run_summary.csv`, with individual signal CSVs and MAT outputs beside it. Hydrogen slopes are fitted over 60–600 seconds, excluding startup.

The electrolysis and fuel-cell slopes agree with the command-based Faraday calculation using 10 cells, two electrons per hydrogen molecule, molar mass 2.01588 g/mol and Faraday constant 96485 C/mol. OFF maintains constant mass. None of these short runs exceeded the configured 200–1000 g tank range.

The fuel-cell current reaches approximately 297.816 A at 2 seconds before settling to 200 A at 3 seconds. The tank fuel-cell flow is based on commanded current, so this startup excursion should not be interpreted as a fully coupled transient hydrogen balance. The additional current plot is derived from logged CSV samples without smoothing.

Known limits:

- Added PV instrumentation failed. PV plots show calculated component power, not measured delivered power.
- A 500 V nominal bus parameter does not establish measured voltage regulation.
- Tank-limit stop blocks are commented out; post-run checks do not provide active protection.
- Grid support and consumer demand remain active.
- No motor, speed controller, PWM drive study, completed 24-hour dispatch, optimal-control comparison, round-trip efficiency, cost analysis or lifecycle emissions analysis is demonstrated.

Future work: repair PV instrumentation, validate electrical energy balance, enable tank protection, implement supervisory dispatch, then connect a DC motor and design speed control with appropriate converter and solver settings.
