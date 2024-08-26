
# NASA-Openscapes JupyterHub Usage Report

This directory contains a [quarto document](aws-usage-report.qmd) that generates
a report of the usage and costs of AWS resources in the NASA-Openscapes [JupyterHub](https://openscapes.2i2c.cloud/hub/).

The report is generated automatically on the first day of every month using a GitHub Actions [workflow](../.github/workflows/create-pdf-report.yml), summarizing usage for the preceding month. The report can also be created on demand by triggering the workflow manually, by visiting the ["Render and Save PDF" workflow page](https://github.com/NASA-Openscapes/2i2cAccessPolicies/actions/workflows/create-pdf-report.yml), and clicking the "Run Workflow" button in the upper right corner.

Reports are stored in the [reports](reports/) directory.