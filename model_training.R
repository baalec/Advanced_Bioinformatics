library(xgboost)
library(DBI)
library(dplyr)
library(RSQLite)
library(ggplot2)
library(SHAPforxgboost)

# Connect to database
mydb <- dbConnect(RSQLite::SQLite(), "my-db.sqlite")

# Get data for model traning
model_data <- dbGetQuery(mydb, "SELECT * FROM model_data")

# Splitting the data
set.seed(42)
# Set asid 20% for test, for train 60% and validation 20%
train_val <- model_data %>% dplyr::sample_frac(0.8)
train_set <- train_val %>% dplyr::sample_frac(0.75)
val_set <- dplyr::anti_join(train_val, train_set)
test_set <- dplyr::anti_join(model_data,train_val)

# Confirm splitting is correct
n_total <- nrow(model_data)
cat("Train: ", nrow(train_set)/n_total, "\n")
cat("Validation: ", nrow(val_set)/n_total, "\n")
cat("Test: ", nrow(test_set)/n_total, "\n")

# Split into x and y sets
x_train <- as.matrix(train_set %>% select(-"Index",-"LFC"))
y_train <- train_set$LFC
x_val <- as.matrix(val_set %>% select(-"Index", -"LFC"))
y_val <- val_set$LFC
x_test <- as.matrix(test_set %>% select(-"Index",-"LFC"))
y_test <- test_set$LFC

# Convert to DMatrix
dtrain <- xgb.DMatrix(data = x_train, label = y_train)
dval <- xgb.DMatrix(data = x_val, label = y_val)

# Create watchlist for training + validation
watchlist <- list(train = dtrain, eval = dval)

params <- list(
  eta = 0.1,
  max_depth = 4,
  gamma = 1,
  objective = "reg:squarederror",
  eval_metric = "rmse"
)

model <- xgb.train(
  params = params,
  data = dtrain,
  nrounds = 1000,
  early_stopping_rounds = 10,
  watchlist = watchlist,
  nthread = 4,
  verbose = 1
)

eval_log <- model$evaluation_log

plot(eval_log$iter, eval_log$train_rmse, type = "l", col = "blue",
     ylim = range(c(eval_log$train_rmse, eval_log$eval_rmse)),
     ylab = "RMSE", xlab = "Boosting Round", main = "Training vs Validation RMSE")
lines(eval_log$iter, eval_log$eval_rmse, col = "red")
legend("topright", legend = c("Train", "Validation"), col = c("blue", "red"), lty = 1)

cat("Best iteration:", model$best_iteration, "\n")

# Get feature importance matrix
importance_matrix <- xgb.importance(model = model)

# View importance
print(importance_matrix)

# Plot importance
xgb.plot.importance(importance_matrix)
