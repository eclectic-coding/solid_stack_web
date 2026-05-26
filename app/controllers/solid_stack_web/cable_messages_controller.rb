module SolidStackWeb
  class CableMessagesController < ApplicationController
    def index
      scope = ::SolidCable::Message.where(channel_hash: params[:channel_hash]).order(created_at: :desc)
      @channel_name = scope.pick(:channel) || params[:channel_hash]
      @pagy, @messages = pagy(scope)
    end
  end
end
