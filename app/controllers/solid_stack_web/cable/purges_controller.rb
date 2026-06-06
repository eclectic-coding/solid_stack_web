module SolidStackWeb
  class Cable::PurgesController < ApplicationController
    def destroy
      days = [params[:older_than].to_i, 1].max
      ::SolidCable::Message.where("created_at < ?", days.days.ago).delete_all
      redirect_to cable_path, notice: t("solid_stack_web.flash.messages_purged", count: days)
    end
  end
end
