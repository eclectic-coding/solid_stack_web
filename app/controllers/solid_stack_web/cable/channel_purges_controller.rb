module SolidStackWeb
  class Cable::ChannelPurgesController < ApplicationController
    def destroy
      ::SolidCable::Message.where(channel_hash: params[:channel_hash]).delete_all
      redirect_to cable_path, notice: t("solid_stack_web.flash.channel_purged")
    end
  end
end
