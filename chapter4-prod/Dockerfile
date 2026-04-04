# マルチステージビルド: ビルド用と実行用のイメージを分ける手法。
# Stage 1でuvとpyproject.tomlを使って.venvを作り、Stage 2にはその.venvだけコピーする。
# ビルドツール（uv等）が最終イメージに含まれないため、イメージサイズが小さくなる。

# Stage 1: Install dependencies
FROM python:3.12-slim AS builder

# ghcr.io/astral-sh/uv: uvの公式Dockerイメージ。
# --from=... で別イメージのファイルをコピーする「マルチソースCOPY」の書き方。
# uvバイナリだけを/binに追加することで、Stageにuvを最小限組み込む。
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

COPY pyproject.toml uv.lock ./
# --frozen: uv.lockに記録されたバージョンを厳守してインストール（lockfileを更新しない）。
# --no-dev: devDependencies（テストツール等）を除いた本番用パッケージのみインストール。
# --no-install-project: srcパッケージ自体はインストールせず、依存ライブラリだけ入れる。
#   → srcはStage 2でCOPYするので、ここでは不要。
RUN uv sync --frozen --no-dev --no-install-project

# Stage 2: Runtime image
FROM python:3.12-slim

WORKDIR /app

# Stage 1で作った.venv（仮想環境）だけをコピー。uvやビルドキャッシュは含まれない。
COPY --from=builder /app/.venv /app/.venv
COPY src/ ./src/

# .venv内のpython/uvicorn等を直接実行できるようにPATHに追加。
# これにより`python`や`uvicorn`コマンドが.venv内のものを指す。
ENV PATH="/app/.venv/bin:$PATH"

# Cloud Runはデフォルトで8080番ポートにリクエストを転送する。
# EXPOSEはドキュメント目的（実際のポート開放はCMDのuvicorn引数で制御）。
EXPOSE 8080

# uvicorn: FastAPIを動かすASGIサーバ。
# src.main:app → src/main.pyのappオブジェクトを起動対象として指定。
# --host 0.0.0.0: コンテナ外からのアクセスを受け付ける（デフォルトの127.0.0.1だとコンテナ内のみ）。
CMD ["python", "-m", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8080"]
