module SolidStackWeb
  class CableStats
    def to_h
      {
        messages:          ::SolidCable::Message.count,
        channels:          ::SolidCable::Message.distinct.count(:channel),
        messages_per_hour: ::SolidCable::Message.where(created_at: 1.hour.ago..).count,
        oldest_message:    ::SolidCable::Message.minimum(:created_at),
        top_channels:      top_channels_by_volume
      }
    end

    private

    def top_channels_by_volume
      ::SolidCable::Message
        .group(:channel)
        .order(Arel.sql("count(*) DESC"))
        .limit(3)
        .count
    end
  end
end
