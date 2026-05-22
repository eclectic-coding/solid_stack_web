module SolidStackWeb
  class CableController < ApplicationController
    def index
      @total_messages = ::SolidCable::Message.count
      @channels       = ::SolidCable::Message.distinct.pluck(:channel).sort
    end
  end
end
