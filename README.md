PackageEvaluator.jl
===================

A tool to evaluate the quality of a Julia pacakge.

Tied into the work on [Julep 2](https://gist.github.com/IainNZ/6086173) on improving the quality of the Julia package ecosystem.

Example of current output:

---

# Package Analysis Results

## REQUIRE file
- Requirement: packages must have a REQUIRE file
 - ✓ Passed (+1.0)
- Requirement: REQUIRE file specifies a Julia version
 - ✗ Failed!

## Licensing
- Recommendation: Packages should have a license
 - ✓ Passed (+1.0)
  - Detected license in JuMP.jl/LICENSE.md: 0.0

---

## Summary
 - Total score: 2.0
 - One or more requirements failed - please fix and try again.

