library(dplyr)

# Load data --------------------------------------------------------------------
load('.Rdata')

# Defaults  --------------------------------------------------------------------
SPECIES <- unique(DATA$Species)
CC <- unique(DATA$Culture_collection)
ST <- unique(DATA$ST)
SL <- unique(DATA$Sublineage)
CG <- unique(DATA$`Clonal Group`)
KL <- unique(DATA$K_locus)
OL <- unique(DATA$O_locus)
VIR <- unique(DATA$virulence_score)
AMR <- unique(DATA$resistance_score)

# Helper functions -------------------------------------------------------------
summary_colname <- function(x) {
  x <- gsub('_', ' ', x)
  dplyr::case_when(
    .default=paste0(x, 's'),
    endsWith(x, 'us') ~ paste0(substr(x, 1, nchar(x)-2), 'i'),
    endsWith(x, 's') ~ x,
  )
}

# Cosmetic globals -------------------------------------------------------------
## CSS Loader Spinner Formatting: https://projects.lukehaas.me/css-loaders/
SPINNER_TYPE = 8
SPINNER_COLOR = "#e62e84ff"
SPINNER_SIZE = 2