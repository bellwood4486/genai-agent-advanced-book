# VPC ネットワーク。
# auto_create_subnetworks = false で「カスタムモード VPC」にする。
# デフォルトモードでは各リージョンにサブネットが自動作成されるが、
# 必要なリージョンにのみ最小限のサブネットを手動定義する方がコスト・管理面で望ましい。
resource "google_compute_network" "this" {
  project                 = var.project_id
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

# サブネット。
# Cloud Run の Direct VPC Egress を使う場合、Cloud Run インスタンスが
# このサブネット内の IP を使って内部ネットワーク（将来の Firestore 等）にアクセスする。
# 現時点では ES/Qdrant はパブリックエンドポイントなので VPC 経由は不要だが、
# Increment 8（Firestore）以降に備えて先に作成しておく。
resource "google_compute_subnetwork" "this" {
  project       = var.project_id
  name          = "${var.vpc_name}-subnet"
  region        = var.region
  network       = google_compute_network.this.id
  ip_cidr_range = var.subnet_cidr
}
