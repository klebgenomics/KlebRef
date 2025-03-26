library(shiny)
library(bslib)
library(shinyWidgets)
library(htmltools)
library(plotly)
library(leaflet)
# library(shinycssloaders)

theme <- bslib::bs_theme(
  bg="#FFF",
  fg="#000",
  primary="#f294c0ff",
  secondary="#e62e84ff",
  success="#009E73",
  base_font=sass::font_google("PT Sans"),
  heading_font=sass::font_google("Nunito")
)
create_logo_link <- function(id, src, url, width="100%", tooltip_text=NULL) {
  img_tag <- htmltools::img(src=src, width=width, style="vertical-align: middle;")  # Ensure vertical alignment
  link_tag <- shiny::actionLink(inputId=id, label=img_tag, onclick=sprintf("window.open('%s')", url))
  if (!is.null(tooltip_text)) {
    bslib::tooltip(link_tag, tooltip_text, placement='bottom')
  } else {
    link_tag
  }
}
klebref_logo <- create_logo_link(
  id="klebref_logo",
  src="klebref.png",
  url="https://github.com/klebgenomics/Public-Klebsiella-Reference-Strains",
  width="65%"
)
kaptive_logo <- create_logo_link(
  id="kaptive_logo",
  src="kaptive.png",
  url="https://kaptive.readthedocs.io",
  width="100px",
  tooltip_text='Read the docs'
)
kleborate_logo <- create_logo_link(
  id="kleborate_logo",
  src="kleborate.png",
  url="https://kleborate.readthedocs.io",
  width="100px",
  tooltip_text='Read the docs'
)
pathogenwatch_logo <- create_logo_link(
  id="pathogenwatch_logo",
  src="pwatch.svg",
  url="https://cgps.gitbook.io/pathogenwatch",
  width="140px",
  tooltip_text='Read the docs'
)
atcc_logo <- create_logo_link(
  id="atcc_logo",
  src="ATCC.png",
  url="https://www.atcc.org/quick-order",
  width="80%",
  tooltip_text='Order here!'
)
nctc_logo <- create_logo_link(
  id="nctc_logo",
  src="NCTC.jpeg",
  url="https://www.culturecollections.org.uk/nop/quickshop",
  width="120px",
  tooltip_text='Order here!'
)
bei_logo <- create_logo_link(
  id="bei_logo",
  src="BEI.png",
  url="https://www.beiresources.org/login.aspx?ReturnUrl=%2fMYBEI%2fQuickOrderForm.aspx",
  width="120px",
  tooltip_text='Order here!'
)
klebphacol_logo <- create_logo_link(
  id="klebphacol_logo",
  src="KlebPhaCol.png",
  url="https://strain.klebphacol.soton.ac.uk/#/",
  width="120px",
  tooltip_text='Order here!'
)
monash_logo <- create_logo_link(
  id='monash_logo',
  src="monash.svg",
  width="120px",
  url="https://www.monash.edu"
)
title <- htmltools::div(
  style="width: 100%;", # Ensure it takes the full width
  htmltools::div(
    style="display: flex; justify-content: space-between; align-items: center;",
    htmltools::div(
      style="flex: 0 0 auto;",  # Don't grow or shrink
      klebref_logo
    ),
    htmltools::div(
      shiny::actionButton(
        'download', 'Download strain table', icon=shiny::icon('download'), 
        width='225px',
      ),
      shiny::actionButton(
        'download_tree', 'Download tree', icon=shiny::icon('download'), 
        width='200px',
      )
    )
  )
)
footer <- htmltools::div(
  # style="width: 100%;", # Ensure it takes the full width
  htmltools::div(
    style="display: flex; justify-content: space-between; align-items: center;",
    htmltools::div(
      style="display: flex; align-items: center; flex-wrap: nowrap;",
      # htmltools::span("Powered by:", style="margin-left: 10px; font-weight: bold;"),
      htmltools::HTML(
        "<strong>Brought to you by the <a href=https://wyreslab.com> Wyres Lab</a> @</strong>"
      ),
      monash_logo
    ),
    htmltools::div(
      style="display: flex; align-items: center; flex-wrap: nowrap;",
      htmltools::span("Powered by:", style="margin-right: 10px; font-weight: bold;"),
      kaptive_logo, kleborate_logo, pathogenwatch_logo
    )
  )
)
sidebar <- bslib::sidebar(
  width=450,
  shinyWidgets::checkboxGroupButtons(
    inputId="cc_selector", selected=CC, choices=CC, justified=TRUE, size='sm',
    checkIcon=list(yes=shiny::icon("square-check"), no=shiny::icon("square")),
    label=htmltools::h4("Select culture collections")
  ),
  htmltools::div(
    style="display: flex; align-items: center; flex-wrap: nowrap;",
    atcc_logo, nctc_logo, bei_logo, klebphacol_logo
  ),
  htmltools::h4('Filter strains'),
  shinyWidgets::pickerInput(
    'species_selector', "Species:", multiple=TRUE,
    choices=SPECIES, selected=SPECIES,
    options=shinyWidgets::pickerOptions(actionsBox=TRUE, style="btn-primary")
  ),
  shinyWidgets::pickerInput(
    'sl_selector', "Sublineages:", multiple=TRUE, choices=SL, selected=SL,
    options=shinyWidgets::pickerOptions(actionsBox=TRUE, liveSearch=TRUE, style="btn-primary")
  ),
  shinyWidgets::pickerInput(
    'cg_selector', "Clonal groups:", multiple=TRUE, choices=CG, selected=CG,
    options=shinyWidgets::pickerOptions(actionsBox=TRUE, liveSearch=TRUE, style="btn-primary")
  ),
  shinyWidgets::pickerInput(
    'st_selector', "Sequence types:", multiple=TRUE, choices=ST, selected=ST,
    options=shinyWidgets::pickerOptions(actionsBox=TRUE, liveSearch=TRUE, style="btn-primary")
  ),
  shinyWidgets::pickerInput(
    'kl_selector', "K loci:", multiple=TRUE, choices=KL, selected=KL,
    options=shinyWidgets::pickerOptions(actionsBox=TRUE, liveSearch=TRUE, style="btn-primary")
  ),
  shinyWidgets::pickerInput(
    'ol_selector', "O loci:", multiple=TRUE, choices=OL, selected=OL,
    options=shinyWidgets::pickerOptions(actionsBox=TRUE, liveSearch=TRUE, style="btn-primary")
  ),
  shinyWidgets::pickerInput(
    'vir_selector', "Virulence:", multiple=TRUE, choices=VIR, selected=VIR,
    options=shinyWidgets::pickerOptions(style="btn-primary")
  ),
  shinyWidgets::pickerInput(
    'amr_selector', "Resistance:", multiple=TRUE, choices=AMR, selected=AMR,
    options=shinyWidgets::pickerOptions(style="btn-primary")
  ),
  shiny::actionButton(
    'reset_input', "Reset filters", icon=shiny::icon("arrows-rotate")
  )
)
intro <- shiny::fluidRow(
  htmltools::HTML(
    '<p>KlebRef is a resource to explore genomic information and 
    associated metadata of <em>Klebsiella</em> reference strains with
    publicly available genomes. If you found KlebRef useful in your research,
    please <a href=https://doi.org/10.5281/zenodo.10419967> cite</a>.</p>
    <p>The collapsible sidebar on the left can be used to filter strains based on
    culture collections and genotypes of interest; you can hit the "Reset filters"
    button to show all strains. Clicking on the culture collection logos will
    take you to their respective ordering portals and below is a summary of the
    strains you have selected.</p>'
  ),
  shiny::tableOutput('summary')
)
map <- shiny::column(
  6,
  shiny::h4('Geographic distribution'),
  leaflet::leafletOutput('map', height=550),
    # shinycssloaders::withSpinner(color=SPINNER_COLOR, type=SPINNER_TYPE, size=SPINNER_SIZE),
  htmltools::p(
    'This map shows the geographic source of each reference strain if available. 
    Hover over the points to see the strain name.'
  )
)
tree <- shiny::column(
  6,
  shiny::h4('Genetic relatedness'),
  shinyWidgets::pickerInput(
    'tree_col', selected='Species', label="Colour tips by:", inline=TRUE,
    options=shinyWidgets::pickerOptions(style='btn-primary'),
    choices=c(
      'Species', 'Sublineage', 'Clonal Group', 'ST', 'K_locus', 
      'O_locus', 'resistance_score', 'virulence_score', 'Isolation_source',
      'Culture_collection', 'Bioproject', 'BioSample', 'Host', 'Origin'
    ),
  ),
  plotly::plotlyOutput('tree'),
    # shinycssloaders::withSpinner(color=SPINNER_COLOR, type=SPINNER_TYPE, size=SPINNER_SIZE),
  htmltools::HTML(
    '<p>This tree shows the genetic relatonship of each reference strain
    based on Jaccard distance calculated by 
    <a href=https://mash.readthedocs.io/en/latest/> Mash</a>.
    Hover over the points to see the strain name and use the dropdown
    menu to colour tips by a desired variable.</p>'
  )
)
bslib::page_sidebar(
  theme=theme, sidebar=sidebar, title=title, window_title='KlebRef',
  shiny::fluidRow(intro), 
  shiny::fluidRow(tree, map),
  shiny::fluidRow(DT::dataTableOutput('tbl')),
  htmltools::hr(),
  footer
)
