library(shiny)

# Define UI
ui <- fluidPage(
  titlePanel("SHAP & Training Data Viewer"),
  tabsetPanel(
    tabPanel("shap plot summary",
             sidebarLayout(
               sidebarPanel(
                 selectInput("shap_plot_choice", "Choose a SHAP plot:",
                             choices = c("Boxplot After/before filtering",
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
                   actionButton("btn_rna", "RNA-expression", class = "circle-btn"),
                   actionButton("btn_gc", "gc-content", class = "circle-btn")
                 )
               ),
               mainPanel(
                 uiOutput("training_image")
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
  
  # Render RDS plots in UI
  output$shap_rds_output <- renderUI({
    req(shap_rds_plots())
    
    plot_output_list <- lapply(seq_along(shap_rds_plots()), function(i) {
      plotname <- paste0("rdsplot", i)
      plotOutput(plotname)
    })
    
    do.call(tagList, plot_output_list)
  })
  
  # Render each plot
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
  
  # ---- Training Images Logic (remains unchanged except styling) ----
  get_training_plot_path <- function(param_name) {
    paste0("www/training_", param_name, ".png")
  }
  
  training_choice <- reactiveVal(NULL)
  observeEvent(input$btn_lfc, { training_choice("lfc") })
  observeEvent(input$btn_rna, { training_choice("rna_expression") })
  observeEvent(input$btn_gc, { training_choice("gc_content") })
  
  output$training_image <- renderUI({
    req(training_choice())
    img_src <- get_training_plot_path(training_choice())
    tags$img(src = img_src, width = "600px")
  })
}

# Run the app
shinyApp(ui, server)
