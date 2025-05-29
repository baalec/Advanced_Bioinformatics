# app.R

library(shiny)
library(xgboost)

# 0) Ensure your custom package is installed
if (!requireNamespace("yourCustomPkg", quietly = TRUE)) {
  stop(
    "Please install yourCustomPkg first, e.g.\n",
    "  devtools::install_github('yourusername/yourCustomPkg')"
  )
}
library(yourCustomPkg)  # provides one_hot_encode(seq)

# 1) Load pre-trained model once at startup
#    (adjust path to wherever you saved it with xgb.save)
model_path <- "model/xgb_lfc_model.bin"
if (!file.exists(model_path)) {
  stop("Model file not found at: ", model_path)
}
xgb_model <- xgb.load(model_path)

ui <- fluidPage(
  titlePanel("sgRNA LFC Predictor"),
  
  sidebarLayout(
    sidebarPanel(
      textInput(
        "sgseq",
        "Enter 20-bp sgRNA sequence:",
        placeholder = "e.g. GAGTCCGAGCAGAAGAAGA"
      ),
      numericInput(
        "exon",
        "Exon number:",
        value = 1, min = 1, step = 1
      ),
      actionButton("go", "Predict LFC")
    ),
    
    mainPanel(
      verbatimTextOutput("check"),  # debug/validation messages
      verbatimTextOutput("pred")    # shows predicted LFC
    )
  )
)

server <- function(input, output, session) {
  
  observeEvent(input$go, {
    seq <- toupper(trimws(input$sgseq))
    
    # Validate sequence length
    if (nchar(seq) != 20 || grepl("[^ACGT]", seq)) {
      output$check <- renderText({
        "Error: please enter a 20-bp sequence containing only A, C, G, T."
      })
      output$pred <- renderText(NULL)
      return()
    }
    output$check <- renderText("Sequence looks good. Encoding...")
    
    # 2) One-hot encode using your package function
    #    Assumes one_hot_encode() returns a numeric vector or matrix
    ohe <- yourCustomPkg::one_hot_encode(seq)
    # If your function returns a vector of length 80 (4 × 20), great.
    # Otherwise adjust accordingly.
    
    # 3) Prepare model input: combine one-hot + exon
    #    Here we assume the model was trained on a feature vector
    #    like: [ohe_features, exon_number]
    data_mat <- matrix(c(ohe, input$exon), nrow = 1)
    dtest    <- xgb.DMatrix(data_mat)
    
    # 4) Predict LFC
    lfc_pred <- predict(xgb_model, dtest)
    
    # 5) Show result
    output$pred <- renderText({
      paste0("Predicted LFC: ", round(lfc_pred, 3))
    })
  })
}

shinyApp(ui, server)
