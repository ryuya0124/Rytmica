# Microsoft Store の自動提出

Rytmica の Microsoft Store 製品 ID は `9N7HMK8TN36X`。GitHub Actions の
[`release_build.yml`](../.github/workflows/release_build.yml) は Windows x64 の
MSIX をビルドし、GitHub Release の作成後に Microsoft Store の審査へ提出する。
Store CLI の公式手順: <https://learn.microsoft.com/en-us/windows/apps/publish/msstore-dev-cli/github-actions>

## 設定の進捗（2026-09-23）

- Store 製品 `9N7HMK8TN36X` の 2.5.0 は手動提出済みで、Partner Center では審査中。自動提出は実行していない。
- 既存の Store 個人開発者アカウントに、新設した Microsoft Entra テナント `ryuyadev.onmicrosoft.com` を関連付け済み。Partner Center の完了画面で Entra 管理者への Account admin 権限付与を確認した。`ryuya-dev.net` は Entra でドメイン所有権を確認済み（Cloudflare DNS の TXT レコード）。既存のメール用 DNS レコードは変更していない。
- Entra には Rytmica 専用のシングルテナント アプリ `Rytmica Microsoft Store Release` を登録済み。他のアプリの配信用資格情報と共有しない。
- 同アプリのクライアントシークレットは 24 か月で発行済み。有効期限は **2028-09-22**。Microsoft の仕様上、カスタム指定でもクライアントシークレットの上限は 24 か月で、無期限にはできない。
- GitHub の [`microsoft-store` Environment](https://github.com/ryuya0124/Rytmica/settings/environments) には下記 4 種の Secrets を登録済み。Seller ID は既存の Partner Center 個人開発者アカウントの「Legal info → Developer → Publisher IDs」で確認した。資格情報の値はこのリポジトリに記録しない。
- Partner Center の「User management → Microsoft Entra applications」に上記アプリを追加し、`Manager(Windows)` ロールが付いたことを一覧で確認済み。
- **残作業:** 次の新しいリリースで Store CLI の認証・提出を検証する。2.5.0 は再提出しない。

最初の関連付け操作では `You are not authorized for this action` が表示されたが、個人開発者アカウントで再サインインしてやり直したところ成功した。Entra 管理者で入り直した「User management → Users」では `Global admin, Manager(Windows)` を確認済み。アプリの権限と GitHub Secrets は揃ったが、Store CLI の認証・提出実行は未検証。2.5.0 の既存審査を妨げないよう、このバージョンでの自動提出テストは行わない。

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
2028-09-22 より十分前に Entra の `Rytmica Microsoft Store Release` →「証明書とシークレット」で新しいシークレットを発行し、値が表示されている間に GitHub Environment の `AZURE_AD_APPLICATION_SECRET` を更新する。新しい資格情報で認証できることを確認してから古いものを削除する。Microsoft のクライアントシークレットは最大 24 か月であり、期限切れのままでは次回リリース時に認証失敗する。

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
