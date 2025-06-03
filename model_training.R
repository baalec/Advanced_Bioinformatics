library(xgboost)
library(DBI)
library(dplyr)
library(tidyr)
library(RSQLite)
library(ggplot2)
library(SHAPforxgboost)

# Connect to database
mydb <- dbConnect(RSQLite::SQLite(), "my-db.sqlite")

# Get data for model training data
model_data <- dbGetQuery(mydb, "SELECT * FROM model_data")
# Get distrubtion of LFC
#dist_lfc_pf <-ggplot(data = model_data, mapping = aes(x = LFC)) +
                geom_histogram() +
                theme_minimal() +
                labs(title = "Distribution of LFC")
#print(dist_lfc_pf)

# geom_boxplot()# Filter out extreme LFC values
#model_data <- model_data[model_data$LFC < 2.5 & model_data$LFC > -2.5, ]
# Filter out data with NA, Exon_position > 10, RNAseq < 11
model_data <- na.omit(model_data)
# Take log of RNAseq to make it comparable in SHAP and remove those
# with 1 or less to only get active genes
model_data$RNAseq_expression <- log2(model_data$RNAseq_expression + 1)
model_data <- model_data[model_data$RNAseq_expression > 1, ]

# Make boxplots of exon_position, RNAseq_expression and gc_content
features_for_boxplot <- model_data %>% 
  select("Exon_position","RNAseq_expression", "gc_content") %>%
  pivot_longer(cols = everything(), names_to = "Feature", values_to = "Value")

boxplot_pf <- ggplot(data = features_for_boxplot, mapping = aes(x = "", y = Value)) +
  geom_boxplot() +
  theme_minimal() +
  facet_wrap(~ Feature, scales = "free_y") +
  labs(title = "Selected features pre filtering", x = "", y = "Value")
print(boxplot_pf)
saveRDS(boxplot_pf, "boxplot_pf")
# Filter out outliers
model_data <- model_data[model_data$Exon_position < 11,]
model_data <- model_data[model_data$gc_content >= 0.25 
                         & model_data$gc_content <= 0.8, ]

features_for_boxplot <- model_data %>% 
  select("Exon_position","RNAseq_expression", "gc_content") %>%
  pivot_longer(cols = everything(), names_to = "Feature", values_to = "Value")

boxplot_af <- ggplot(data = features_for_boxplot, mapping = aes(x = "", y = Value)) +
  geom_boxplot() +
  theme_minimal() +
  facet_wrap(~ Feature, scales = "free_y") +
  labs(title = "Selected Features after filtering", x = "", y = "Value")
print(boxplot_af)
saveRDS(boxplot_af, "boxplot_af")
# Only take negative LFC as these are "vital gene knockouts"
model_data <- model_data[model_data$LFC <= 0, ]
# Take abs of LFC to make it for interpretation
model_data$LFC <- abs(model_data$LFC)

# Splitting the data
set.seed(42)
# Set asid 20% for test, for train 60% and validation 20%
train_set <- model_data %>% dplyr::sample_frac(0.8)
test_set <- dplyr::anti_join(model_data,train_set)

# Confirm splitting is correct
n_total <- nrow(model_data)
cat("Train: ", nrow(train_set)/n_total, "\n")
cat("Test: ", nrow(test_set)/n_total, "\n")

# Split into x and y sets
x_train <- as.matrix(train_set %>% select(-"index",-"LFC"))
y_train <- train_set$LFC
x_test <- as.matrix(test_set %>% select(-"index",-"LFC"))
y_test <- test_set$LFC

# Convert to DMatrix as xgboost requires a DMmatrix
# It has to include data(features) and label(target)
dtrain <- xgb.DMatrix(data = x_train, label = y_train)

# Set hyperparameters for model
params <- list(
  eta = 0.1,
  max_depth = 4,
  gamma = 1,
  objective = "reg:squarederror",
  eval_metric = "rmse"
)

# Train model using dtrain and params with watchlist to catch overfitting early
# using early stopping
cv_results <- xgb.cv(
  params = params,
  data = dtrain,
  nrounds = 1000,
  nfold = 5,
  early_stopping_rounds = 10,
  verbose = 1,
  maximize = FALSE,
  metrics = "rmse",
  prediction = TRUE
)

best_nrounds <- cv_results$best_iteration
cat("Best number of boosting rounds from CV:", best_nrounds, "\n")

# FINAL MODEL
final_model <- xgb.train(params = params,
                         data = dtrain,
                         nrounds = best_nrounds,
                         verbose = 1)

# Create SHAP values and plot top 20 features
shap_values <- shap.values(xgb_model = final_model, X_train = x_train)
shap_long <- shap.prep(xgb_model = final_model, X_train = x_train, top_n = 25)
shap_final <- shap.plot.summary(data_long = shap_long)                         
print(shap_final)
saveRDS(shap_final, "shap_final")

# Predict on test set
preds <- predict(final_model, newdata = x_test)

# Evaluation of model
errors <- y_test - preds
model_rmse <- sqrt(mean(errors^2))
model_mae <- mean(abs(errors))

sst <- sum((y_test - mean(y_test))^2)
sse <- sum(errors^2)
model_r2 <- 1 - sse / sst

eval_df <- data.frame(model_rmse,model_mae,model_r2)

cat("Test RMSE:", model_rmse, "\n")
cat("Test MAE:", model_mae, "\n")
cat("Test R2:", model_r2, "\n")

# Predictions vs Actual
pred_df <- data.frame(
  Actual = y_test,
  Predicted = preds
)

predicted_vs_actual <-ggplot(pred_df, aes(x = Actual, y = Predicted)) +
  geom_point(alpha = 0.6, color = "steelblue") +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red") +
  theme_minimal() +
  labs(
    title = "Predicted vs Actual Values (Test Set)",
    x = "Actual LFC",
    y = "Predicted LFC"
  ) +
  coord_equal() +
  theme(plot.title = element_text(hjust = 0.5))
print(predicted_vs_actual)
saveRDS(predicted_vs_actual, "predicted_vs_actual")
# Residuals of predictions

residuals <- y_test - preds
resid_df <- data.frame(
  Predicted = preds,
  Residuals = residuals
)

predicted_vs_residuals <- ggplot(resid_df, aes(x = Predicted, y = Residuals)) +
  geom_point(alpha = 0.6, color = "darkorange") +
  geom_hline(yintercept = 0, linetype = "dashed") +
  theme_minimal() +
  labs(
    title = "Residuals vs Predicted Values",
    x = "Predicted LFC",
    y = "Residuals (Actual - Predicted)"
  ) +
  theme(plot.title = element_text(hjust = 0.5))
print(predicted_vs_residuals)
saveRDS(predicted_vs_residuals, "predicted_vs_residuals")

#summary(model_data)

save(final_model, params, best_nrounds, eval_df, file = "saved_vars.RData")

dbDisconnect(mydb)

#ggplot(model_data, aes(x = matched_exons, y = absLFC)) +
  #geom_jitter()
#anova(lm(absLFC~matched_exons,as.data.frame(model_data)))
#?lm
