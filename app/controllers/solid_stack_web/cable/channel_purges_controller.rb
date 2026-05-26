module SolidStackWeb
  class Cable::ChannelPurgesController < ApplicationController
    def destroy
      ::SolidCable::Message.where(channel_hash: params[:channel_hash]).delete_all
      redirect_to cable_path, notice: "All messages for this channel have been purged."
    end
  end
end
