# cf-common

PHPプロジェクトをはじめとしたシステム開発における、Google Cloud Functionsへのデプロイスクリプト、パッケージ依存関係の自動アップデート、各種自動化・共通ユーティリティをまとめたリポジトリです。
他のプロジェクトから git submodule として利用されることを想定しています。

## 主な機能

1. **Google Cloud Functions デプロイスクリプト & ワークフロー**
   - **ローカルデプロイスクリプト**: PHP 関数の HTTP トリガーおよびイベント（Pub/Sub）トリガーを安全かつ簡単にデプロイするための Bash スクリプトを提供します。
     - 終了時・失敗時の自動一時ディレクトリ（`_deploy`）クリーンアップ（`trap` 処理）。
     - 環境変数 `REGION` による任意リージョンの指定（デフォルト: `us-west1`）。
   - **再利用可能な GitHub Actions ワークフロー**:
     - Workload Identity Federation による安全な GCP 認証。
     - Secret Manager との統合。
     - Cloud Storage への静的ファイルアップロード支援。
     - HTTP トリガーおよび Pub/Sub トリガーのデプロイ。
     - Cloud Functions 削除ワークフロー (`remove-cloud-functions.yaml`)。

2. **パッケージ & サブモジュール自動アップデートワークフロー**
   - **パッケージ自動更新 (`update-packages.yml`)**: Composer、NPM、Gradle/Kotlin の各パッケージマネージャーの依存関係を自動的に検出・更新し、差分があれば自動でコミットおよびプッシュします。
   - **サブモジュール自動更新 (`update-submodules.yml`)**: リポジトリ内の git submodule を再帰的に最新化し、差分があれば自動でコミットおよびプッシュします。

3. **ユーティリティ & 開発支援**
   - **シークレット読み込みスクリプト (`export_secrets.sh` / `unset_secrets.sh`)**: ローカル開発時に、Google Secret Manager から指定した秘密情報を動的に取得し、環境変数に展開・解除するヘルパースクリプトです。
   - **GCS アーティファクトクリーンアップポリシー (`misc/artifact_cleanup_policy/`)**: GCS Artifact Registry バケット（`gcf-artifacts`）のクリーンアップポリシーを設定・参照するスクリプトを提供します。

---

## ディレクトリ構成

- `deploy/`: ローカルデプロイ用のシェルスクリプト。
  - `deploy_php_http.sh`: HTTP トリガーの PHP 関数をデプロイします。
  - `deploy_php_event.sh`: Pub/Sub トリガーの PHP 関数をデプロイします。
  - `common.sh`: 各デプロイスクリプトで共通利用される GCP プロジェクト・リージョン設定。
  - `RENAME_deploy.sh`: プロジェクトにコピーして使用するデプロイスクリプトのテンプレート。
  - `rsync_exclude.conf`: デプロイ対象から除外するファイル・ディレクトリ定義。
- `.github/`: 再利用可能な GitHub Actions ワークフローおよびアクション。
  - `workflows/deploy-cloud-functions.yaml`: 関数のデプロイ用ワークフロー。
  - `workflows/remove-cloud-functions.yaml`: 関数の削除用ワークフロー。
  - `workflows/update-packages.yml`: パッケージ（Composer, NPM, Gradle）自動更新ワークフロー。
  - `workflows/update-submodules.yml`: サブモジュール自動更新ワークフロー。
  - `actions/put_firebase_config/`: Firebase 設定ファイル作成アクション。
- `misc/`: その他ユーティリティ。
  - `artifact_cleanup_policy/`: GCS バケットのライフサイクル・クリーンアップポリシー設定スクリプト (`apply.sh`) およびポリシー定義 (`policy.json`)。
- `test/`: 開発およびテスト用ヘルパー。
  - `export_secrets.sh`: Google Secret Manager から秘密情報を取得し、環境変数としてエクスポートします。
  - `unset_secrets.sh`: 環境変数からシークレット情報を解除します。

---

## 使い方

### 1. プロジェクトへの追加 (Git Submodule)

プロジェクトのルートディレクトリで以下のコマンドを実行し、本リポジトリを `_myapps-common` として追加します。

```bash
git submodule add https://github.com/your-org/cf-common.git _myapps-common
```

### 2. ローカルからの Cloud Functions デプロイ

1. `_myapps-common/deploy/RENAME_deploy.sh` をプロジェクトのルートにコピーし、`deploy.sh` などにリネームします。
2. `deploy.sh` 内の関数名やデプロイタイプをプロジェクトに合わせて編集します。
3. プロジェクトルートに `.gcloudignore` や `configs/config.json`（必要に応じて）を用意します。
4. スクリプトを実行してデプロイします。

```bash
bash deploy.sh
```

※ デフォルトのリージョン（`us-west1`）を変更したい場合は、環境変数 `REGION` を設定して実行します。

```bash
REGION=asia-northeast1 bash deploy.sh
```

### 3. GitHub Actions でのワークフロー利用

#### A. Cloud Functions のデプロイ

プロジェクトの `.github/workflows/deploy.yml` から再利用可能なワークフローを呼び出します。

```yaml
jobs:
  deploy:
    uses: ./.github/workflows/deploy-cloud-functions.yaml@main
    with:
      function_name: 'my-function'
      service_account_name: 'github-actions-sa'
      secrets_config: |
        MY_SECRET
        ANOTHER_SECRET
    secrets:
      GCP_PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
      GCP_REGION: ${{ secrets.GCP_REGION }}
      GCP_PROJECT_NUMBER: ${{ secrets.GCP_PROJECT_NUMBER }}
```

#### B. 依存パッケージの自動アップデート

プロジェクト内の Composer, NPM, Gradle の依存パッケージを定期的に自動アップデートするには、プロジェクト側のワークフローから以下のように呼び出します。

```yaml
name: Scheduled Package Update

on:
  schedule:
    - cron: '0 9 * * 1' # 毎週月曜日の朝
  workflow_dispatch:

jobs:
  update:
    uses: ./.github/workflows/update-packages.yml@main
    secrets:
      GH_PAT: ${{ secrets.PERSONAL_ACCESS_TOKEN }}
```

#### C. サブモジュールの自動アップデート

呼び出し元プロジェクトに組み込まれているサブモジュールを最新のコミットに追従させる場合、以下のように呼び出します。

```yaml
name: Scheduled Submodule Update

on:
  schedule:
    - cron: '0 10 * * 1'
  workflow_dispatch:

jobs:
  update-submodule:
    uses: ./.github/workflows/update-submodules.yml@main
    secrets:
      GH_PAT: ${{ secrets.PERSONAL_ACCESS_TOKEN }}
```

### 4. 開発用シークレットヘルパーの利用

ローカルでのテスト時に Secret Manager の値を利用したい場合、以下のように `export_secrets.sh` を利用して環境変数にロードできます。

```bash
# SECRETS 配列に取得したいシークレット名を定義して source 実行
export SECRETS=("SECRET_A" "SECRET_B")
source _myapps-common/test/export_secrets.sh
```

使い終わったシークレットの環境変数をクリアしたい場合は、以下を実行します。

```bash
source _myapps-common/test/unset_secrets.sh
```

### 5. GCS アーティファクトクリーンアップポリシーの適用

Artifact Registry (`gcf-artifacts`) のクリーンアップポリシーを適用するには以下を実行します。

```bash
PROJECT_ID="my-gcp-project" bash _myapps-common/misc/artifact_cleanup_policy/apply.sh
```
