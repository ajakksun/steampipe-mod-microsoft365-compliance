query "custom_admin_accounts_cloud_only" {
  sql = <<-EOQ
    WITH global_admin_members AS (
      SELECT
        jsonb_array_elements_text(member_ids) AS user_id
      FROM
        azuread_directory_role
      WHERE
        display_name = 'Global Administrator'
    ),

    admin_sync_status AS (
      SELECT
        u.id                 AS resource,
        u.user_principal_name,
        COALESCE(u.on_premises_sync_enabled, false) AS synced,
        u._ctx
      FROM
        global_admin_members gm
        JOIN azuread_user u ON u.id = gm.user_id
    )

    SELECT
      resource,
      CASE
        WHEN synced = false THEN 'ok'
        ELSE 'alarm'
      END AS status,
      CASE
        WHEN synced = false
          THEN user_principal_name || ' is cloud‑only'
        ELSE user_principal_name || ' has on‑premises sync enabled'
      END AS reason,
      _ctx
    FROM
      admin_sync_status;
  EOQ
}
