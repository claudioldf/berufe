# frozen_string_literal: true

class DropApplicationSessionCsrfToken < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :application_sessions,
      "csrf_token_digest ~ '^[0-9a-f]{64}$'",
      name: "application_sessions_csrf_digest_format"
    remove_column :application_sessions, :csrf_token_digest
  end

  def down
    add_column :application_sessions, :csrf_token_digest, :text
    execute(<<~SQL.squish)
      UPDATE application_sessions
      SET csrf_token_digest = encode(sha256(gen_random_uuid()::text::bytea), 'hex')
      WHERE csrf_token_digest IS NULL
    SQL
    change_column_null :application_sessions, :csrf_token_digest, false
    add_check_constraint :application_sessions,
      "csrf_token_digest ~ '^[0-9a-f]{64}$'",
      name: "application_sessions_csrf_digest_format"
  end
end
