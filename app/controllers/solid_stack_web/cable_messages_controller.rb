module SolidStackWeb
  class CableMessagesController < ApplicationController
    def index
      @search = params[:q].presence
      scope   = ::SolidCable::Message.where(channel_hash: params[:channel_hash])
      if @search
        scope = scope.where("payload LIKE ?", "%#{::ActiveRecord::Base.sanitize_sql_like(@search)}%")
      end
      @channel_name    = ::SolidCable::Message.where(channel_hash: params[:channel_hash]).pick(:channel) || params[:channel_hash]
      @pagy, @messages = pagy(scope.order(created_at: :desc))
    end
  end
end
