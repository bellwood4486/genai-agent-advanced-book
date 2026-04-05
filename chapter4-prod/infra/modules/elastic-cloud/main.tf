# チャイルドモジュールでサードパーティプロバイダを使う場合、
# required_providers でソースアドレスを明示する必要がある。
# これを省略すると Terraform が hashicorp/ プレフィックスを補完して解決に失敗する。
terraform {
  required_providers {
    ec = {
      source  = "elastic/ec"
      version = "~> 0.10"
    }
  }
}

# Elastic Cloud Serverless Elasticsearch プロジェクト。
#
# "Serverless" とは、クラスタの管理（ノード数、スケーリング）を Elastic 側が自動化する形態。
# 通常の Elastic Cloud（Hosted）と異なり、仮想マシンや容量を事前に確保しない。
# コストはストレージ + 検索コンピュート（VCU/ECU）の従量課金で、軽い利用では月数ドル程度。
#
# リソース ec_elasticsearch_project は elastic/ec プロバイダで管理する。
# 認証（APIキー）はルートの providers.tf で設定済みのため、ここでは不要。
#
# 注意: このリソースは Technical Preview（将来スキーマが変わる可能性あり）。学習用途なので許容する。

# GCP リージョン名を Elastic Cloud のリージョン ID 形式に変換する。
# Elastic Cloud では GCP リージョンに "gcp-" プレフィックスが付く。
# 例: "asia-northeast1" -> "gcp-asia-northeast1"
locals {
  elastic_region_id = "gcp-${var.region}"
}

resource "ec_elasticsearch_project" "this" {
  name = var.project_name

  # region_id: Elastic Cloud 上でプロジェクトを稼働させるリージョン。
  # GCP 東京（asia-northeast1）に配置することで、Cloud Run との通信レイテンシを抑える。
  region_id = local.elastic_region_id
}
