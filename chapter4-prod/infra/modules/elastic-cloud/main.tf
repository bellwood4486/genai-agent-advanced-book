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
#
# region_id の形式について:
# Hosted デプロイメント（ec_deployment）では "gcp-asia-northeast1" のような形式を使うが、
# Serverless プロジェクト（ec_elasticsearch_project）は独自のリージョン ID リストを持つ。
# 利用可能なリージョン ID は Elastic Cloud API で確認できる:
#   curl -H "Authorization: ApiKey <key>" https://api.elastic-cloud.com/api/v1/serverless/regions
# var.region にはそのリージョン ID をそのまま渡す（例: "gcp-asia-southeast1"）。

resource "ec_elasticsearch_project" "this" {
  name = var.project_name

  # region_id: Elastic Cloud Serverless のリージョン ID。
  # ルートモジュールの elastic_region 変数から渡される（例: "gcp-asia-southeast1"）。
  region_id = var.region
}
