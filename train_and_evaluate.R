# パラメータ設定済みのモデルを訓練&評価
# CV 分割ごとの平均値を評価スコアとする
# df.model_with_param: パラメータ設定済みモデルの一覧(parsnip::model_spec のリスト)
# df.cv: クロスバリデーション用データ(rsample::vfold_cv)
# metrics: 評価指標(デフォルトは Accuracy)
train_and_evaluate <- function(df.model_with_param, df.cv, metrics = yardstick::accuracy) {
  library(tidyverse)
  library(tidymodels)

  df.scores <- df.model_with_param %>%

    # ハイパーパラメータの組み合わせごとにループ
    purrr::map(function(model.applied) {

      # クロスバリデーションの分割ごとにループ
      purrr::map(df.cv$splits, model = model.applied, function(df.split, model) {

        # 前処理済データの作成
        df.train <- recipe %>%
          recipes::prep() %>%
          recipes::bake(rsample::analysis(df.split))
        df.test <- recipe %>%
          recipes::prep() %>%
          recipes::bake(rsample::assessment(df.split))

        model %>%

          # モデルの学習
          {
            model <- (.)

            parsnip::fit(model, Species ~ ., df.train)
          } %>%

          # 学習済モデルによる予測
          {
            fit <- (.)

            list(
              train = predict(fit, df.train, type = "class")[[1]],
              test  = predict(fit, df.test,  type = "class")[[1]]
            )
          } %>%

          # 評価
          {
            lst.predicted <- (.)

            # train データでモデルを評価
            df.result.train <- df.train %>%
              dplyr::mutate(
                predicted = lst.predicted$train
              ) %>%
              metrics(truth = Species, estimate = predicted) %>%
              dplyr::select(-.estimator) %>%
              dplyr::mutate(
                .metric = stringr::str_c("train", .metric, sep = "_")
              ) %>%
              tidyr::spread(key = .metric, value = .estimate)

            # test データでモデルを評価
            df.result.test <- df.test %>%
              dplyr::mutate(
                predicted = lst.predicted$test
              ) %>%
              metrics(truth = Species, estimate = predicted) %>%
              dplyr::select(-.estimator) %>%
              dplyr::mutate(
                .metric = stringr::str_c("test", .metric, sep = "_")
              ) %>%
              tidyr::spread(key = .metric, value = .estimate)

            dplyr::bind_cols(
              df.result.train,
              df.result.test
            )
          }
      }) %>%

        # CV 分割全体の平均値を評価スコアとする
        purrr::reduce(dplyr::bind_rows) %>%
        dplyr::summarise_all(mean)
    }) %>%

    # 評価結果とパラメータを結合
    purrr::reduce(dplyr::bind_rows)

  df.grid.params %>%
    dplyr::bind_cols(df.scores)
}
