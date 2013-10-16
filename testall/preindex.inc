<!DOCTYPE html>
<!--[if lt IE 7 ]><html class="ie ie6" lang="en"> <![endif]-->
<!--[if IE 7 ]><html class="ie ie7" lang="en"> <![endif]-->
<!--[if IE 8 ]><html class="ie ie8" lang="en"> <![endif]-->
<!--[if (gte IE 9)|!(IE)]><!--><html lang="en"> <!--<![endif]-->
<head>

  <!-- Basic Page Needs -->
  <meta charset="utf-8">
  <title>Package Evaluator Results</title>

  <!-- Mobile Specific Metas -->
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">

  <!-- CSS -->
  <link rel="stylesheet" href="http://www.iaindunning.com/css/base.css">
  <link rel="stylesheet" href="http://www.iaindunning.com/css/skeleton.css">
  <link rel="stylesheet" href="http://www.iaindunning.com/css/layout.css">

  <!--[if lt IE 9]>
    <script src="http://html5shim.googlecode.com/svn/trunk/html5.js"></script>
  <![endif]-->

  <style>
  table, th, td
  {
    border: 1px solid black;
    text-align: center;
    padding: 5px;
  }
  .grn {
    background-color: #CCFFCC;
  }
  .red {
    background-color: #FFCCCC;
  }
  </style>

</head>
<body>
  <div class="container">
    <div class="sixteen columns">
      <h1 class="remove-bottom" style="margin-top: 40px;">PackageEvaluator Results</h1>
      <hr />
    </div>
    <div class="sixteen columns">
      <h2>List of tests run</h2>
      <h3>Package</h3>
      <ul>
      <li>Check for the existence of a REQUIRE file in the root of the package.</li>
      <li>Check that the REQUIRE file specifies a Julia version.</li>
      <li>Check that a LICENSE file exists in the root of the package.</li>
      <li>Determine the license type.</li>
      <li>Checks that the package has tests that can be launched from a single file (e.g. test/runtests.jl)</li>
      <li>Checks that the recommend test/runtests.jl file exists.</li>
      <li>Checks that the tests pass, if they exist.</li>
      <li>Checks that the tests pass without warnings (coming soon).</li>
      <li>Checks for TravisCI support.</li>
      </ul>
      <h3>Metadata</h3>
      <ul>
      <li>Checks for the existence of a url file.</li>
      <li>Checks for the existence of a DESCRIPTION.md file.</li>
      <li>Checks for the existence of a requires file for every version, and all must specify a Julia version.</li>
      </ul>
      
      <h2>Summary Table</h2>
      <p>Click package name for more detailed breakdown.</p>
