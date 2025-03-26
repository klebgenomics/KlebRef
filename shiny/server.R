library(shiny)
library(bslib)
library(ggtree)
library(shinyWidgets)
library(purrr)
library(ape)
library(htmltools)
library(plotly)
library(leaflet)

function(input, output, session) {

  # Reactive expressions -------------------------------------------------------
  reset_input <- function() {
    shinyWidgets::updateCheckboxGroupButtons(
      session, "cc_selector", choices=CC, selected=CC)
    shinyWidgets::updatePickerInput(
      session, 'species_selector', choices=SPECIES, selected=SPECIES)
    shinyWidgets::updatePickerInput(
      session, 'sl_selector', choices=SL, selected=SL)
    shinyWidgets::updatePickerInput(
      session, 'cg_selector', choices=CG, selected=CG)
    shinyWidgets::updatePickerInput(
      session, 'st_selector', choices=ST, selected=ST)
    shinyWidgets::updatePickerInput(
      session, 'kl_selector', choices=KL, selected=KL)
    shinyWidgets::updatePickerInput(
      session, 'ol_selector', choices=OL, selected=OL)
    shinyWidgets::updatePickerInput(
      session, 'vir_selector', choices=VIR, selected=VIR)
    shinyWidgets::updatePickerInput(
      session, 'amr_selector', choices=AMR, selected=AMR)
  }
  shiny::observeEvent(input$reset_input, {
    shiny::showNotification('Resetting filters')
    reset_input()
  })

  # Reactive data --------------------------------------------------------------
  reactive_data <- shiny::reactive({
    d <- DATA |> 
      dplyr::filter(
        Culture_collection %in% input$cc_selector,
        Species %in% input$species_selector,
        Sublineage %in% input$sl_selector,
        `Clonal Group` %in% input$cg_selector,
        ST %in% input$st_selector,
        K_locus %in% input$kl_selector,
        O_locus %in% input$ol_selector,
        virulence_score %in% input$vir_selector,
        resistance_score %in% input$amr_selector
      )
    if(nrow(d) == 0){
      shiny::showNotification('No strains matching filter', type='warning')
    }
    return(d)
  })
  
  reactive_tree <- shiny::reactive({
    ape::drop.tip(TREE, TREE$tip.label[!TREE$tip.label %in% reactive_data()$Accession])
  })

  # Outputs --------------------------------------------------------------------
  output$tbl=DT::renderDT({reactive_data()}, rownames=FALSE)
  
  output$summary=shiny::renderTable({
    reactive_data() |> 
      dplyr::summarise(
        Strains=dplyr::n(),
        dplyr::across(
          c(Species, Sublineage, `Clonal Group`, ST, K_locus, O_locus,
            resistance_score, virulence_score), 
          dplyr::n_distinct, .names='{summary_colname(.col)}'
          )
      )
    }, rownames=FALSE)
  
  output$map <- leaflet::renderLeaflet({
    if(nrow(reactive_data()) > 0){
      d <- dplyr::filter(reactive_data(), !is.na(lat), !is.na(lon))
      if(nrow(d) > 0){
        return(
          leaflet::leaflet(d) |>
            leaflet::addProviderTiles(leaflet::providers$OpenStreetMap) |> 
            leaflet::addMarkers(
              ~lon, ~lat, popup=~Strain, label=~Strain,
              icon=~leaflet::icons(iconUrl="bacteria.png", 
                                   iconWidth=30, iconHeight=30)
            )
        )
      }
      shiny::showNotification(
        'No geographical information for selected strains', type='warning')
    }
    return(
      leaflet::leaflet() |>
        leaflet::addProviderTiles(leaflet::providers$OpenStreetMap)
    )
  })
  
  output$tree <- plotly::renderPlotly({
    if(nrow(reactive_data()) == 0){
      return(NULL)
    }
    tree <- reactive_tree() |> 
      ggtree::ggtree(ggplot2::aes(label=Strain, layout='fan')) %<+% 
      reactive_data() +
      ggplot2::geom_point(
        ggplot2::aes(fill=.data[[input$tree_col]]), data=ggtree::td_filter(isTip),
        shape=21, col='black', show.legend=FALSE, size=3, alpha=.8
      ) +
      ggplot2::theme(
        legend.title=ggplot2::element_text(colour='black', face="bold"),
        legend.text=ggplot2::element_text(colour='black', face="bold"),
        panel.background=ggplot2::element_rect(fill='transparent', color=NA),
        plot.background=ggplot2::element_rect(fill='transparent', color=NA),
        legend.background=ggplot2::element_rect(fill='transparent', color=NA),
        legend.box.background=ggplot2::element_rect(fill='transparent', color=NA),
        strip.background=ggplot2::element_blank(),
        strip.text=ggplot2::element_text(colour='black', face="bold"),
        panel.border=ggplot2::element_blank()
      )
    plotly::ggplotly(tree, tooltip=c('label', "fill")) |> 
      plotly::layout(showlegend=FALSE)
  })
  
  output$table_download <- shiny::downloadHandler(
    filename=function(){
      paste("klebref_", Sys.Date(), ".csv", sep="")
    },
    content=function(file){
      readr::write_csv(reactive_data(), file)
    }
  )
  output$tree_download <- shiny::downloadHandler(
    filename=function(){
      paste("klebref_", Sys.Date(), ".newick", sep="")
    },
    content=function(file){
      ape::write.tree(reactive_tree(), file)
    }
    
  )
}
