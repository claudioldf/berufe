# frozen_string_literal: true

module Admin
  module Reports
    class Period
      TIME_ZONE = "America/Sao_Paulo"
      KEYS = %w[since_launch last_30_days last_7_days].freeze
      LABELS = {
        "since_launch" => ["Desde o lançamento", "Desde o início"],
        "last_30_days" => ["Últimos 30 dias", "30 dias"],
        "last_7_days" => ["Últimos 7 dias", "7 dias"]
      }.freeze
      MONTHS = %w[jan fev mar abr mai jun jul ago set out nov dez].freeze

      class Invalid < StandardError; end

      attr_reader :key, :generated_at, :start_date, :end_date, :start_at, :end_at,
        :previous_start_at, :previous_end_at

      def initialize(key:, generated_at: Time.current)
        @key = key.to_s.presence || "since_launch"
        raise Invalid unless KEYS.include?(@key)

        @generated_at = generated_at
        today = generated_at.in_time_zone(TIME_ZONE).to_date
        configured_launch = Rails.configuration.x.berufe.reporting.product_launch_date
        retained_from = today - (Rails.configuration.x.berufe.reporting.aggregate_retention_days - 1)
        requested_start = case @key
        when "last_7_days" then today - 6
        when "last_30_days" then today - 29
        else configured_launch
        end
        @truncated = @key == "since_launch" && requested_start < retained_from
        @start_date = [requested_start, retained_from].max
        @end_date = today
        @start_at = @start_date.in_time_zone(TIME_ZONE)
        @end_at = (today + 1).in_time_zone(TIME_ZONE)
        if @key != "since_launch"
          duration = (@end_date - @start_date + 1).to_i.days
          @previous_end_at = @start_at
          @previous_start_at = @start_at - duration
        end
      end

      def include?(timestamp)
        timestamp.present? && timestamp >= start_at && timestamp < end_at
      end

      def threshold
        (key == "last_7_days") ? 2 : 3
      end

      def to_h
        label, short_label = LABELS.fetch(key)
        label = "Últimos 24 meses" if @truncated
        short_label = "24 meses" if @truncated
        {
          key:,
          label:,
          short_label:,
          window_label: "#{self.class.format_date(start_date)} – #{self.class.format_date(end_date)}",
          start_at: start_at.iso8601,
          end_at: end_at.iso8601,
          truncated: @truncated,
          data_available_from: start_date.iso8601
        }
      end

      def self.format_date(date)
        "#{date.day.to_s.rjust(2, "0")} #{MONTHS.fetch(date.month - 1)}"
      end
    end
  end
end
