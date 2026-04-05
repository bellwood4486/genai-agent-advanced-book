# チャイルドモジュールでサードパーティプロバイダを使う場合、
# required_providers でソースアドレスを明示する必要がある。
#
# 【重要】Terraform はリソース名のプレフィックス（_ より前）をプロバイダ名として推論する。
# "qdrant-cloud_accounts_cluster" → プロバイダ名 "qdrant-cloud" と推論される。
# しかし providers.tf では "qdrant" という名前で宣言しているため名前が一致しない。
# この不一致を解消するために、各リソース・データソースに provider = qdrant を明示する。
terraform {
  required_providers {
    qdrant = {
      source  = "qdrant/qdrant-cloud"
      version = "~> 1.1"
    }
  }
}

# Qdrant Cloud クラスタ（Free Tier）。
#
# Qdrant はベクトル類似検索に特化したデータベース。
# このアプリでは Q&A の埋め込みベクトルを格納し、ユーザーの質問と意味的に近い回答を検索する。
#
# Free Tier: 1 ノード、リソース制限あり、$0/月。学習用途に十分。
# 認証（APIキー + account_id）はルートの providers.tf で設定済み。

# 指定リージョンで利用可能なパッケージ（料金プラン）一覧を取得するデータソース。
# パッケージごとに CPU・メモリ・ストレージが異なり、price_per_hour で課金額が決まる。
# この情報を使って Free Tier のパッケージ ID を動的に特定する。
data "qdrant-cloud_booking_packages" "available" {
  # provider を明示してリソース名プレフィックスとの不一致を解消する
  provider = qdrant

  cloud_provider = "gcp"
  cloud_region   = var.region
}

# 取得したパッケージから Free Tier（時間単価 = 0）のものをフィルタする。
# unit_int_price_per_hour が 0 のパッケージが Free Tier に該当する。
locals {
  free_packages = [
    for pkg in data.qdrant-cloud_booking_packages.available.packages : pkg
    if pkg.unit_int_price_per_hour == 0
  ]
  # 最初に見つかった Free Tier パッケージを使用する。
  # 該当パッケージがなければ Terraform がインデックスエラーで即座に失敗するため気付きやすい。
  free_package_id = local.free_packages[0].id
}

resource "qdrant-cloud_accounts_cluster" "this" {
  # provider を明示してリソース名プレフィックスとの不一致を解消する
  provider = qdrant

  name = var.cluster_name

  # cloud_provider / cloud_region: クラスタを稼働させるクラウドとリージョン。
  # GCP を選ぶことで Cloud Run と同じインフラ上に近接配置できる。
  cloud_provider = "gcp"
  cloud_region   = var.region

  configuration {
    # Free Tier は 1 ノード構成。
    number_of_nodes = 1

    node_configuration {
      # パッケージ ID は上で動的に取得した Free Tier のもの。
      package_id = local.free_package_id
    }
  }
}

# クラスタへのアクセスに使うデータベース API キー。
# v2 リソースを使用する（qdrant-cloud_accounts_auth_key は非推奨）。
# MANAGE 権限により、コレクションの作成・削除も含むフルアクセスが可能。
resource "qdrant-cloud_accounts_database_api_key_v2" "this" {
  # provider を明示してリソース名プレフィックスとの不一致を解消する
  provider = qdrant

  cluster_id = qdrant-cloud_accounts_cluster.this.id
  name       = "${var.cluster_name}-key"

  global_access_rule {
    # MANAGE: 読み書き + コレクション管理の全権限。
    # 本番では読み書きのみの READ_WRITE に絞ることを推奨。
    access_type = "GLOBAL_ACCESS_RULE_ACCESS_TYPE_MANAGE"
  }
}
