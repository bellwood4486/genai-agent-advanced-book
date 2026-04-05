# Secret Manager にシークレットを作成し、値（バージョン）を登録する。
#
# Secret Manager は「シークレット（メタデータ）」と「バージョン（実際の値）」の2層構造。
# google_secret_manager_secret がシークレットの箱を作り、
# google_secret_manager_secret_version が中身の値を入れる。
#
# Cloud Run では環境変数に secret_key_ref でシークレットを参照でき、
# アプリコードに秘密情報をハードコードせずに済む（Increment 5 で設定）。

locals {
  # シークレット名と値のマッピング。
  # for_each で繰り返し、各エントリに対してシークレット + バージョンを作成する。
  secrets = {
    "openai-api-key"  = var.openai_api_key
    "elastic-api-key" = var.elastic_api_key
    "qdrant-api-key"  = var.qdrant_api_key
  }
}

resource "google_secret_manager_secret" "this" {
  for_each  = local.secrets
  project   = var.project_id
  secret_id = each.key

  # シークレットのレプリケーション設定。
  # auto で Google が自動的に複数リージョンにレプリケートする（追加料金なし）。
  # 特定リージョンにデータを限定する要件がなければ auto が推奨。
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "this" {
  for_each = local.secrets
  secret   = google_secret_manager_secret.this[each.key].id

  # secret_data: シークレットの実際の値。
  # Terraform state に平文で保存されるため、state ファイルのアクセス制御が重要。
  # GCS backend + IAM で保護されているが、state への直接アクセスには注意する。
  secret_data = each.value

  lifecycle {
    # plan 実行時、Terraform は現在の secret_data を Secret Manager から読み取って
    # state と比較しようとする（これには secretmanager.versions.access 権限が必要）。
    # CI/CD サービスアカウントにシークレット値の読み取り権限を与えないために
    # ignore_changes を設定し、初回 apply 以降の差分チェックをスキップする。
    # 値を更新したい場合は手動で terraform apply を実行すること。
    ignore_changes = [secret_data]
  }
}
