# DEFAULT_SETTINGS

Emoff の初期値・運用設定を管理する。コード、ビジネスモデル、ストア文言、QA と矛盾しないように更新する。

---

## プラン・課金

| 設定項目 | キー | デフォルト値 | 参照 |
|---|---|---|---|
| Freeプラン送信上限 | free_daily_message_limit | 30通/日 | BUSINESS_MODEL.md |
| Personal Pro月額 | personal_pro_monthly_price | 300円/月 | BUSINESS_MODEL.md |
| RevenueCat Entitlement | revenuecat_entitlement | pro | BUSINESS_MODEL.md |
| RevenueCat商品ID | revenuecat_product_id | emoff_pro_monthly | BUSINESS_MODEL.md |

## AI変換・データ保存

| 設定項目 | キー | デフォルト値 | 参照 |
|---|---|---|---|
| 変換前テキスト保存期間 | original_text_retention_days | 30日 | BUSINESS_MODEL.md |
| Anthropic側保持期間 | anthropic_retention_days | 7日 | BUSINESS_MODEL.md |
| 送信後の原文閲覧 | original_text_visible_after_send | false | BUSINESS_MODEL.md |

## QA・運用

| 設定項目 | キー | デフォルト値 | 参照 |
|---|---|---|---|
| QA共有列初期値 | qa_share_default | - | qa-checklist-rules |
| QA結果の記録先 | qa_results_file | QA_RESULTS.md | QA_RESULTS.md |
