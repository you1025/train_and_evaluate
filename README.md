# train_and_evaluate

## 使い方

### Accuracy で評価

```R
library(tidyverse)
library(tidymodels)

# クロスバリデーション用の分割を定義
df.cv <- rsample::vfold_cv(
  iris,
  v = 5,
  strata = "Species"
)

# 前処理レシピの定義
recipe <- recipes::recipe(Species ~ ., iris) %>%
  recipes::step_rm(Sepal.Width) %>%
  recipes::step_log(Sepal.Length) %>%
  recipes::step_center(all_predictors()) %>%
  recipes::step_scale(all_predictors())

# モデルの定義
model <- parsnip::rand_forest(
  mode = "classification",
  mtry = parsnip::varying(),
  min_n = parsnip::varying(),
  trees = parsnip::varying()
) %>%
  parsnip::set_engine(engine = "ranger", num.threads = 4)

# グリッドサーチ用の組み合わせパターンを定義
df.grid.params <- dials::grid_regular(
  dials::mtry  %>% dials::range_set(c(2, 3)),
  dials::min_n %>% dials::range_set(c(4, 6)),
  dials::trees %>% dials::range_set(c(500, 1000)),
  levels = 2
)

# ハイパーパラメータのセット
merge(df.grid.params, model) %>%

  # 学習＆評価
  train_and_evaluate(df.cv, recipe) %>%

  # 評価スコアでソート(昇順)
  dplyr::arrange(desc(test_accuracy))
```

| mtry| min_n| trees| train_accuracy| test_accuracy|
|----:|-----:|-----:|--------------:|-------------:|
|    2|     4|   500|      0.9916667|          0.96|
|    3|     4|   500|      0.9883333|          0.96|
|    2|     6|   500|      0.9833333|          0.96|
|    3|     6|   500|      0.9816667|          0.96|
|    2|     4|  1000|      0.9900000|          0.96|
|    3|     4|  1000|      0.9916667|          0.96|
|    2|     6|  1000|      0.9850000|          0.96|
|    3|     6|  1000|      0.9850000|          0.96|


### その他の指標で評価

```R
# 評価指標の一覧を定義
metrics <- yardstick::metric_set(
  yardstick::accuracy,
  yardstick::precision,
  yardstick::recall,
  yardstick::f_meas
)

# ハイパーパラメータのセット
merge(df.grid.params, model) %>%

  # 事前に定義した metrics の一覧でモデルを評価
  train_and_evaluate(df.cv, recipe, metrics) %>%

  # 評価スコアでソート(昇順)
  dplyr::arrange(desc(test_f_meas))
```

| mtry| min_n| trees| train_accuracy| train_f_meas| train_precision| train_recall| test_accuracy| test_f_meas| test_precision| test_recall|
|----:|-----:|-----:|--------------:|------------:|---------------:|------------:|-------------:|-----------:|--------------:|-----------:|
|    2|     4|   500|      0.9933333|    0.9933323|       0.9934959|    0.9933333|          0.96|   0.9597985|      0.9632997|        0.96|
|    3|     4|   500|      0.9900000|    0.9899974|       0.9902400|    0.9900000|          0.96|   0.9597985|      0.9632997|        0.96|
|    2|     6|   500|      0.9850000|    0.9849950|       0.9853560|    0.9850000|          0.96|   0.9597985|      0.9632997|        0.96|
|    3|     6|   500|      0.9816667|    0.9816628|       0.9819432|    0.9816667|          0.96|   0.9597985|      0.9632997|        0.96|
|    2|     4|  1000|      0.9900000|    0.9899974|       0.9902400|    0.9900000|          0.96|   0.9597985|      0.9632997|        0.96|
|    3|     4|  1000|      0.9900000|    0.9899974|       0.9902400|    0.9900000|          0.96|   0.9597985|      0.9632997|        0.96|
|    2|     6|  1000|      0.9866667|    0.9866604|       0.9871429|    0.9866667|          0.96|   0.9597985|      0.9632997|        0.96|
|    3|     6|  1000|      0.9833333|    0.9833281|       0.9837300|    0.9833333|          0.96|   0.9597985|      0.9632997|        0.96|
