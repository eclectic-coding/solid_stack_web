module SolidStackWeb
  class DashboardController < ApplicationController
    def index
      @queue_stats = {
        ready:     ::SolidQueue::ReadyExecution.count,
        scheduled: ::SolidQueue::ScheduledExecution.count,
        claimed:   ::SolidQueue::ClaimedExecution.count,
        blocked:   ::SolidQueue::BlockedExecution.count,
        failed:    ::SolidQueue::FailedExecution.count,
      }
      @cache_entries  = ::SolidCache::Entry.count
      @cable_messages = ::SolidCable::Message.count
    end
  end
end
