# Microsoft Store の自動提出

Rytmica の Microsoft Store 製品 ID は `9N7HMK8TN36X`。GitHub Actions の
[`release_build.yml`](../.github/workflows/release_build.yml) は Windows x64 の
MSIX をビルドし、GitHub Release の作成後に Microsoft Store の審査へ提出する。
Store CLI の公式手順: <https://learn.microsoft.com/en-us/windows/apps/publish/msstore-dev-cli/github-actions>

## 初回設定

1. Partner Center に Microsoft Entra ID テナントを関連付ける。
2. 自動提出専用の Entra アプリを登録し、Partner Center の「User management」で
   そのアプリに Manager ロールを付与する。
3. GitHub の `microsoft-store` Environment に以下の Secrets を登録する。

   - `AZURE_AD_TENANT_ID`
   - `AZURE_AD_APPLICATION_CLIENT_ID`
   - `AZURE_AD_APPLICATION_SECRET`
   - `SELLER_ID`

クライアントシークレットはリポジトリや GitHub Actions のログに書かない。
期限が来る前に Entra 側で新しいシークレットを発行し、同名の GitHub Secret を更新する。

## リリース時

1. `pubspec.yaml` の Flutter バージョンと `msix_config.version` を更新する。
   MSIX の最初の 3 桁は `major.minor.patch` のリリースタグと一致させる。
2. `Publish GitHub Release` workflow を実行し、新しいタグを指定する。
   `submit_to_microsoft_store` は既定で有効。
3. Windows パッケージの ID、発行者、アーキテクチャ、バージョンの検証後、
   `msstore publish` が MSIX を審査に提出する。
4. 提出後の進捗は [Partner Center](https://partner.microsoft.com/en-us/dashboard/products/9N7HMK8TN36X/overview) で確認する。

2.5.0 は 2026-09-23 に手動提出済みなので、workflow からの Store 再提出を禁止している。
このタグで workflow を再実行しても Store 提出ジョブは動かない。
2.5.0 の審査が完了するまでは、新しいタグの自動提出も実行しない。
`msstore publish` は保留中の下書き提出を作り直す場合があるため、
Partner Center に編集中の下書きがあるときも先に内容を確認する。
Store 提出を見送るリリースでは `submit_to_microsoft_store` を無効にする。
Microsoft Store Developer CLI によるアプリ更新は、現時点では無料製品のみ対応。
