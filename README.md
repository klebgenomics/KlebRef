# Genomic Analysis of Public _Klebsiella_ Reference Strains
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.10419967.svg)](https://doi.org/10.5281/zenodo.10419967)

## Introduction
:microscope::scientist: The purpose of this resource is to provide a genomic context to _Klebsiella_ reference strains
commonly used in research to aid laboratory researchers in strain selection for particular experiments.

:earth_africa: All of these strains may be purchased from their respective culture collections and
all genomes are publicly available.

:computer: The results of this analysis can be accessed from the 
[Microreact](https://microreact.org/project/6paF6wq5kynJxzBWA4zrH7-public-klebsiella-reference-strains) project 
page or directly from this repository. This Markdown also contains the code used to perform and reproduce the analysis
for yourself!

**Public _Klebsiella_ genomes from the following culture collections are included:**
- [The National Collection of Type Cultures (NCTC)](https://www.culturecollections.org.uk/)
- [The American Type Culture Collection (ATCC)](https://www.atcc.org/)
- [Biological and Emerging Infections (BEI) Resources](https://www.beiresources.org/)

**Genomic analysis of the genomes includes**:
- :dna: [Kleborate](https://github.com/klebgenomics/Kleborate) for typing, AMR and virulence gene detection.
- :microbe: [Kaptive](https://github.com/klebgenomics/Kaptive) for K and O antigen prediction.
- :deciduous_tree: Phylogenetic analysis to infer the relationships between the strains.
- :bar_chart: Visualisation of the dataset with [Microreact](https://microreact.org/).

:tada: **All associated metadata has also been included!** :tada:

## Table of Contents
  - [Fetching the genomes](#fetching-the-genomes)
    - [NCTC and BEI genomes](#nctc-and-bei-genomes)
    - [ATCC genomes](#atcc-genomes)
  - [Genomic analysis](#genomic-analysis)
    - [Kleborate and Kaptive](#kleborate-and-kaptive)
    - [Phylogenetic analysis](#phylogenetic-analysis)
  - [Metadata fetching and processing](#metadata-fetching-and-processing)
    - [NCTC and BEI metadata](#nctc-and-bei-metadata)
    - [ATCC metadata](#atcc-metadata)
    - [Metadata processing](#metadata-processing)
  - [Microreact visualisation](#microreact-visualisation)

## Fetching the genomes
To fetch the genomes, you can either download each one manually :no_good: or use the
[NCBI Datasets](https://www.ncbi.nlm.nih.gov/datasets/docs/command-line-start/) and 
[ATCC Genome Portal](https://github.com/ATCC-Bioinformatics/genome_portal_api) APIs to fetch them in bulk :raised_hands:.

### NCTC and BEI genomes
First, I identified the assiciated BioProjects for both collections:
 - NCTC 3000 Sequencing project [1](1): [PRJEB6403](https://www.ncbi.nlm.nih.gov/bioproject/PRJEB6403).
 - BEI Resources [2](2): [PRJNA717739](https://www.ncbi.nlm.nih.gov/bioproject/PRJNA717739).

Then, I used the [NCBI Datasets API](https://www.ncbi.nlm.nih.gov/datasets/docs/command-line-start/) to download the 
genomes from both BioProjects.
```bash
datasets download genome accession PRJEB6403 PRJNA717739 --search Klebsiella --assembly-source GenBank
```

### ATCC genomes
To use the ATCC Genome Portal API, you will need to obtain an API key from the 
[ATCC Genome Portal](https://www.atcc.org/genome-portal).

Then, I used Python to search for and download all the _Klebsiella_ genomes from the ATCC collection.
```python
from genome_portal_api import *
API_KEY = "YOUR_API_KEY_HERE"  # Replace with your API key
download_catalogue(api_key=API_KEY, output="atcc_catalogue.pkl")  # Download ATCC catalogue
# Fuzzy search for Klebsiella strains in the ATCC catalogue
klebsiella_metadata = {x['product_id']: x for x in search_fuzzy(term="Klebsiella", catalogue_path="atcc_catalogue.pkl")}

# Identify non-Klebsiella strains
non_klebsiella_metadata = {k: v for k, v in klebsiella_metadata.items() if 'Klebsiella' not in v['taxon_name']}
for acc in non_klebsiella_metadata.keys():
    klebsiella_metadata.pop(acc)  # Remove non-Klebsiella strains from Klebsiella metadata

with open('atcc_assembly_urls.txt', 'wt') as f:  # Write the assembly URLs to a file
    for i in klebsiella_metadata.values():
        url = download_assembly(api_key=API_KEY, id=i['id'], download_link_only="True", download_assembly="False")
        f.write(f"{url}\n")
```

Now you can use `curl` to download all the genomes and parallelize with `xargs`.
```bash
xargs -P 8 -n 1 curl -O < atcc_assembly_urls.txt
```

## Genomic analysis
### Kleborate and Kaptive
Kleborate was run on all the genomes to detect AMR, virulence genes and to perform typing.
Details of how to use Kleborate can be found in the [wiki](https://github.com/klebgenomics/Kleborate/wiki). 
Kaptive is run internally by Kleborate, but this has to be switched on; you also
need to use addtional flags to output the K and O antigen predictions to separate files.

```bash
kleborate -a *.fna \  # Run Kleborate on all genomes
 --all \  # Run AMR, K and O antigen detection
 -o reference_klebs_kleborate.txt \  # Output file
 --kaptive_k_outfile reference_klebs_kaptive_k.txt \  # Output file for K antigen prediction
 --kaptive_o_outfile reference_klebs_kaptive_o.txt  # Output file for O antigen prediction
```

### Phylogenetic analysis
Now onto a quick and dirty phylogenetic inference using pairwise Jaccard distance estimates.
This method is less accurate than a proper recombination-free SNP-based phylogeny, 
but as we have genomes from multiple species, this is an appropriate method to use and follows the 
recommendation of [this paper](https://wellcomeopenresearch.org/articles/3-33).
```bash
mash sketch -p 8 -o genomes.msh -s 100000 -k 21 *.fna  # Create a mash sketch
mash dist genomes.msh genomes.msh -p 8 -t > genomes.dist  # Calculate pairwise distances
```
Then a neighbor-joining tree is calculated using the 
[BIONJ](https://academic.oup.com/mbe/article/14/7/685/1119804?login=false) algorithm, implemented in
the [ape](https://rdrr.io/cran/ape/man/bionj.html) R package and exported in Newick format after some cleaning.
```{r}
library(tidyverse)
library(ape)
tree <- readr::read_tsv("genomes.dist", show_col_types=FALSE) |>
    tibble::column_to_rownames('#query') |>
    base::as.matrix() |>
    ape::bionj()
# Edit tree tips to match genome names
tree$tip.label <- purrr::map_chr(tree$tip.label, ~fs::path_ext_remove(fs::path_file(.x)))
treeio::write.tree(tree, "tree.newick")
```

## Metadata fetching and processing
### NCTC and BEI metadata
I used the [NCBI Datasets API](https://www.ncbi.nlm.nih.gov/datasets/docs/command-line-start/) to download the metadata for all the genomes in the [NCTC 3000](https://www.ncbi.nlm.nih.gov/bioproject/PRJEB6403) and
[BEI](https://www.ncbi.nlm.nih.gov/bioproject/PRJNA717739) BioProjects.
```bash
datasets summary genome accession PRJEB6403 PRJNA717739 --search Klebsiella --as-json-lines --assembly-source GenBank | \
dataformat tsv genome > NCTC3000_BEI_metadata.tsv
```

### ATCC metadata
We can use the same metadata dictionary we created earlier to format the metadata for the ATCC genomes into a TSV file.

```python
def flatten_dict(parent_dict: dict):
    """Function to recursively flatten a nested dictionary"""
    flattened = {}  # Create an empty dictionary to store the flattened dictionary
    for k, v in parent_dict.items():
        if isinstance(v, dict):  # Recursively flatten dictionaries
            flattened.update(flatten_dict({f"{k}_{k2}": v2 for k2, v2 in v.items()}))
        elif isinstance(v, list):  # Join lists into comma separated strings
            flattened[k] = ','.join(str(i) for i in v)
        else:
            flattened[k] = v
    return flattened

import pandas as pd
data = {}  # Create an empty dictionary to store the flattened metadata
for acc, metadata in klebsiella_metadata.items():  # Iterate over the metadata we just downloaded
    metadata.pop('primary_assembly')  # Remove the primary assembly from the metadata
    data[acc] = flatten_dict(metadata)  # Flatten the metadata dictionary and add to the data dictionary

df = pd.DataFrame.from_dict(data, orient='index')  # Convert the data dictionary to a Pandas DataFrame
df.to_csv('atcc_metadata.tsv', sep='\t', index=False)  # Write the DataFrame to a TSV file
```

### Metadata processing
Now we can read in the Kleborate results and metadata and join them together to create a single TSV file after
a bit of cleaning. First we need to load the required libraries.
```{r}
library(tidyverse)
library(janitor)  # For remove_empty(), not strictly necessary
library(ggmap)  # For geocoding
```
Read and clean Kleborate results.
```{r}
kleborate <- readr::read_tsv("reference_klebs_kleborate.txt") |>
   # Drop Kleborate K/O results in favour of full Kaptive results
  dplyr::select(!tidyselect::matches("^(K|O)_(locus|type)")) |>
  # Rename strain to Assembly to match Kaptive data
  dplyr::rename('Assembly'=strain) |> 
  # Extract properly formatted NCBI/ATCC accessions to match metadata
  dplyr::mutate(
    current_accession = ifelse(
      startsWith(Assembly, "GC"), 
      stringr::str_extract(Assembly, "GC(A|F)_[0-9]+\\.[0-9]"),
      stringr::str_replace(stringr::str_remove(Assembly, ".*ATCC_"), '_', '-')
      )
    ) |> 
  # Join Kaptive K output
  dplyr::left_join(
    readr::read_tsv("reference_klebs_kaptive_k.txt"), by="Assembly"
  ) |> 
  # Join Kaptive O output
  dplyr::left_join(
    readr::read_tsv("reference_klebs_kaptive_o.txt"), by="Assembly", suffix = c(" K", " O")
  )
```
Read and clean NCTC and BEI metadata.
```{r}
ggmap::register_google(GOOGLE_API_KEY)  # Register Google Maps API key
nctc_bei_metadata <- readr::read_tsv(
  "NCTC3000_BEI_metadata.tsv",
  name_repair = ~stringr::str_to_lower(stringr::str_replace_all(.x, "\\s+", "_"))
  ) |> 
  dplyr::filter(current_accession %in% kleborate$current_accession) |> 
  janitor::remove_empty(c("rows", "cols")) |> 
  tidyr::pivot_wider(names_from = "assembly_biosample_attribute_name", 
                     values_from = "assembly_biosample_attribute_value") |> 
  dplyr::mutate(
    assembly_biosample_sample_identifiers_database = dplyr::coalesce(
      assembly_biosample_sample_identifiers_database,
       assembly_biosample_sample_identifiers_label
      )
    ) |> 
  dplyr::select(!"assembly_biosample_sample_identifiers_label") |>
  tidyr::pivot_wider(
    names_from = "assembly_biosample_sample_identifiers_database",
    values_from = "assembly_biosample_sample_identifiers_value"
    ) |> 
  (\(x) dplyr::bind_rows(  # Geocode the geo_loc_name column
    dplyr::filter(x, is.na(geo_loc_name)),
    ggmap::mutate_geocode(dplyr::filter(x, !is.na(geo_loc_name)), geo_loc_name)
  ))()
```
Read and clean ATCC metadata.
```{r}
atcc_metadata <- readr::read_tsv("atcc_metadata.tsv") |>
  janitor::remove_empty(c("rows", "cols")) |> 
  dplyr::select(!product_url) |> 
  dplyr::rename_with(~stringr::str_remove(.x, "attributes_atcc_metadata_")) |> 
  dplyr::rename(isolation_source = "isolation_new_web", current_accession = "catalog_number") |> 
  dplyr::mutate(strain = glue::glue("ATCC-{current_accession}"))
```
Join the metadata to Kleborate results and write out all the data to a single TSV file.
```{r}
kleborate |> 
  dplyr::inner_join(
    dplyr::bind_rows(nctc_bei_metadata, atcc_metadata), by="current_accession"
  ) |> 
  readr::write_tsv("all_data.tsv", na="")
```

## Microreact visualisation
The results of this analysis can be accessed from the 
[Microreact](https://microreact.org/project/6paF6wq5kynJxzBWA4zrH7-public-klebsiella-reference-strains) project
page or directly from this repository.
