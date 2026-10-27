# Provenance and file interpretation

Upstream: https://github.com/michaelfsb/hydrogen-energy-storage

Reference commit: `41917034dadf1881c6f74708d2dfe52985ba601c`.

The upstream MIT license is retained in the root and simulation folder. The original README is retained as `simulation/UPSTREAM_README.md`. Do not remove Michael Barbosa's copyright notice from redistributed source.

`simulation/src/` is the student's uploaded model and associated sources packaged for repeat execution. The project adaptations include hydrogen mass-balance sign corrections, consistent two-electron hydrogen conversion and a 1-second local solver step. The runner adds case execution, logging, exports and diagnostic capture to a model copy.

`results/` preserves the uploaded run dated 24 October 2026, including the exact code snapshot, diagnostics, exported diagrams and saved model copy. Numerical output files have not been regenerated or fabricated. The report and synopsis are included as supplied/generated project documents. Unrelated report-format templates and intermediate troubleshooting screenshots are excluded; output graphs and actual subsystem exports are included.

`figures/architecture.png` is an explanatory diagram. Its future-drive branch is not an implemented motor circuit. `figures/stack_current.png` is a report figure plotted from the logged current CSVs.

`SHA256SUMS.txt` records the package file hashes. The archived report predates the SDG request; `SDG7.md` provides that requested addition separately.
