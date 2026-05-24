module SolidStackWeb
  class ProcessesController < ApplicationController
    def index
      @processes = ::SolidQueue::Process.order(:kind, :name)
    end
  end
end
