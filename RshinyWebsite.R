library(shiny)

# Define UI
ui <- fluidPage(
  titlePanel("SHAP & Training Data Viewer"),
  tabsetPanel(
    tabPanel("Model",
             sidebarLayout(
               sidebarPanel(
                 selectInput("shap_plot_choice", "Choose a plot:",
                             choices = c("Boxplot of Data after/before filtering",
                                         "Shap",
                                         "Model prediction"))
               ),
               mainPanel(
                 uiOutput("shap_rds_output")
               )
             )
    ),
    
    tabPanel("Training data",
             sidebarLayout(
               sidebarPanel(
                 tags$style(HTML("
                    .circle-btn {
                      width: 70px; height: 70px; border-radius: 35px;
                      border: 2px solid #337ab7;
                      color: #337ab7; background: white;
                      font-weight: bold; margin: 20px;
                      text-align: center; line-height: 65px;
                      cursor: pointer;
                      display: inline-block;
                      font-size: 10px;
                    }
                    .circle-btn:hover {
                      background-color: #337ab7;
                      color: white;
                    }
                  ")),
                 div(
                   actionButton("btn_lfc", "LFC", class = "circle-btn"),
                   actionButton("btn_exons", "Exons", class = "circle-btn"),
                   actionButton("btn_rna", "RNA-expression", class = "circle-btn"),
                   actionButton("btn_gc", "gc-content", class = "circle-btn")
                 )
               ),
               mainPanel(
                 uiOutput("training_rds_output")
               )
             )
    )
  )
)

# Define server logic
server <- function(input, output, session) {
  
  # Reactive to return a list of ggplot objects based on dropdown
  shap_rds_plots <- reactive({
    switch(input$shap_plot_choice,
           "Boxplot After/before filtering" = list(
             readRDS("www/boxplot_af"),
             readRDS("www/boxplot_pf")
           ),
           "Shap" = list(
             readRDS("www/shap_final")
           ),
           "Model prediction" = list(
             readRDS("www/predicted_vs_actual"),
             readRDS("www/predicted_vs_residuals")
           )
    )
  })
  
  # Render RDS plots in shap tab UI
  output$shap_rds_output <- renderUI({
    req(shap_rds_plots())
    
    plot_output_list <- lapply(seq_along(shap_rds_plots()), function(i) {
      plotname <- paste0("rdsplot", i)
      plotOutput(plotname)
    })
    
    do.call(tagList, plot_output_list)
  })
  
  # Render each plot in shap tab
  observe({
    plots <- shap_rds_plots()
    for (i in seq_along(plots)) {
      local({
        ii <- i
        output[[paste0("rdsplot", ii)]] <- renderPlot({
          plots[[ii]]
        })
      })
    }
  })
  
  # --- Training Data tab: reactive to hold list of plots based on button clicked ---
  training_rds_plots <- reactiveVal(NULL)
  
  observeEvent(input$btn_lfc, {
    training_rds_plots(list(
      readRDS("www/dist_lfc_af"),
      readRDS("www/dist_lfc_pf")
    ))
  })
  observeEvent(input$btn_exons, {
    training_rds_plots(list(
      readRDS("www/exons_plot")
    ))
  })
  observeEvent(input$btn_rna, {
    training_rds_plots(list(
      readRDS("www/rna_expression_histogram")
    ))
  })
  observeEvent(input$btn_gc, {
    training_rds_plots(list(
      readRDS("www/gc_content_histogram")
    ))
  })
  
  # Render training plots UI
  output$training_rds_output <- renderUI({
    req(training_rds_plots())
    
    plot_output_list <- lapply(seq_along(training_rds_plots()), function(i) {
      plotname <- paste0("trainingplot", i)
      plotOutput(plotname)
    })
    
    do.call(tagList, plot_output_list)
  })
  
  # Render each training plot
  observe({
    plots <- training_rds_plots()
    req(plots)
    for (i in seq_along(plots)) {
      local({
        ii <- i
        output[[paste0("trainingplot", ii)]] <- renderPlot({
          plots[[ii]]
        })
      })
    }
  })
}

shinyApp(ui, server)

