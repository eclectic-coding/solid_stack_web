module SolidStackWeb
  class CableStats
    def to_h
      {
        messages: ::SolidCable::Message.count,
        channels: ::SolidCable::Message.distinct.count(:channel)
      }
    end
  end
end
