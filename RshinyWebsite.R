library(shiny)

# Define UI
ui <- fluidPage(
  titlePanel("SHAP & Training Data Viewer"),
  tabsetPanel(
    tabPanel("shap plot summary",
             sidebarLayout(
               sidebarPanel(
                 selectInput("shap_plot_choice", "Choose a SHAP plot:",
                             choices = c("plot1", "plot2", "plot3", "plot4"))
               ),
               mainPanel(
                 # Show image corresponding to the dropdown choice
                 uiOutput("shap_image")
               )
             )
    ),
    
    tabPanel("Training data",
             sidebarLayout(
               sidebarPanel(
                 # Circle-like action buttons (using CSS for style)
                 tags$style(HTML("
            .circle-btn {
              width: 70px; height: 70px; border-radius: 35px;
              border: 2px solid #337ab7;
              color: #337ab7; background: white;
              font-weight: bold; margin: 10px;
              text-align: center; line-height: 65px;
              cursor: pointer;
              display: inline-block;
            }
            .circle-btn:hover {
              background-color: #337ab7;
              color: white;
            }
          ")),
                 
                 # Buttons wrapped in div for layout
                 div(
                   actionButton("btn_lfc", "LFC", class = "circle-btn"),
                   actionButton("btn_rna", "RNA-expression", class = "circle-btn"),
                   actionButton("btn_gc", "gc-content", class = "circle-btn")
                 )
               ),
               mainPanel(
                 # Show image for chosen parameter
                 uiOutput("training_image")
               )
             )
    )
  )
)

# Define server logic
server <- function(input, output, session) {
  
  # Helper function to get image path for shap plots
  get_shap_plot_path <- function(plot_name) {
    # Replace this path with your real image folder path
    paste0("www/shap_", plot_name, ".png")
  }
  
  # Helper function to get image path for training data plots
  get_training_plot_path <- function(param_name) {
    paste0("www/training_", param_name, ".png")
  }
  
  # Render shap image based on dropdown choice
  output$shap_image <- renderUI({
    req(input$shap_plot_choice)
    
    img_src <- get_shap_plot_path(input$shap_plot_choice)
    
    tags$img(src = img_src, width = "600px")
  })
  
  # Reactive value to store the last clicked training parameter
  training_choice <- reactiveVal(NULL)
  
  # Update reactive when buttons clicked
  observeEvent(input$btn_lfc, { training_choice("lfc") })
  observeEvent(input$btn_rna, { training_choice("rna_expression") })
  observeEvent(input$btn_gc, { training_choice("gc_content") })
  
  # Render training image based on last clicked button
  output$training_image <- renderUI({
    req(training_choice())
    
    img_src <- get_training_plot_path(training_choice())
    
    tags$img(src = img_src, width = "600px")
  })
}

# Run the app
shinyApp(ui, server)
