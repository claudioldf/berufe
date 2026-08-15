# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Database conventions", type: :model do
  let(:connection) { ActiveRecord::Base.connection }

  it "configures generators to create UUID primary keys" do
    generator_options = Rails.application.config.generators.options[:active_record]

    expect(generator_options[:primary_key_type]).to eq(:uuid)
  end

  it "creates UUID IDs and UTC timestamptz timestamps for application tables" do
    connection.create_table(:database_convention_spec_records, temporary: true, id: :uuid) do |table|
      table.timestamps
    end

    columns = connection.columns(:database_convention_spec_records).index_by(&:name)

    expect(columns.fetch("id").sql_type).to eq("uuid")
    expect(columns.fetch("created_at").sql_type).to include("timestamp", "with time zone")
    expect(columns.fetch("updated_at").sql_type).to include("timestamp", "with time zone")
    expect(ActiveRecord.default_timezone).to eq(:utc)
  ensure
    connection.drop_table(:database_convention_spec_records, if_exists: true)
  end

  it "stores GoodJob timestamps with time zone after the baseline migration" do
    created_at = connection.columns(:good_jobs).find { |column| column.name == "created_at" }

    expect(created_at.sql_type).to include("timestamp", "with time zone")
  end
end
