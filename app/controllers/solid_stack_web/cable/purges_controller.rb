module SolidStackWeb
  class Cable::PurgesController < ApplicationController
    def destroy
      days = [params[:older_than].to_i, 1].max
      ::SolidCable::Message.where("created_at < ?", days.days.ago).delete_all
      redirect_to cable_path, notice: "Messages older than #{days} #{days == 1 ? "day" : "days"} purged."
    end
  end
end
