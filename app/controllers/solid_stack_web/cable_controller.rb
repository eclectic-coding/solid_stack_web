module SolidStackWeb
  class CableController < ApplicationController
    def index
      @total_messages = ::SolidCable::Message.count
      @channels       = channel_rows
    end

    private

    def channel_rows
      ::SolidCable::Message
        .group(:channel, :channel_hash)
        .order(Arel.sql("MAX(created_at) DESC"))
        .pluck(:channel, :channel_hash, Arel.sql("COUNT(*)"), Arel.sql("MAX(created_at)"))
        .map do |ch, hash, cnt, last_at|
          last_at = Time.zone.parse(last_at) if last_at.is_a?(String)
          { channel: ch, channel_hash: hash, message_count: cnt, last_message_at: last_at }
        end
    end
  end
end
