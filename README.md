PackageEvaluator.jl
===================

A tool to evaluate the quality of a Julia pacakge.

Tied into the work on [Julep 2](https://gist.github.com/IainNZ/6086173) on improving the quality of the Julia package ecosystem.

Example of current output:

---

```
# Package Analysis Results

## Package Itself

### REQUIRE file
- Requirement: packages must have a REQUIRE file
 - ✓ Passed (+20.0)
- Requirement: REQUIRE file specifies a Julia version
 - ✓ Passed (+20.0)

### Licensing
- Recommendation: Packages should have a license
 - ✓ Passed (+10.0)
 - License detected in ./LICENSE: MIT

### Testing
- Recommendation: Packages should have a test/runtests.jl file
 - ✓ Passed (+20.0)
- Recommendation: Packages should have TravisCI support
 - ✗ Failed!

## Package METADATA Entry

### url file
- Requirement: Packages must have a url file
 - ✓ Passed (+20.0)

### DESCRIPTION.md file
- Requirement: Packages must have a DESCRIPTION.md file
 - ✓ Passed (+20.0)

### requires files
- Requirement: Each package version requires file must specify a Julia version
 - ✗ Failed!
- Failed versions:
 - 0.0.1

---

## Summary
 - Total score: 110.0 out of 140.0
```
