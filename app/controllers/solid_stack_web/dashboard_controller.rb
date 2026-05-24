module SolidStackWeb
  class DashboardController < ApplicationController
    def index
      @queue_stats = {
        ready:     ::SolidQueue::ReadyExecution.count,
        scheduled: ::SolidQueue::ScheduledExecution.count,
        claimed:   ::SolidQueue::ClaimedExecution.count,
        blocked:   ::SolidQueue::BlockedExecution.count,
        failed:    ::SolidQueue::FailedExecution.count,
        processes: ::SolidQueue::Process.count
      }
      @cache_stats = {
        entries:   ::SolidCache::Entry.count,
        byte_size: ::SolidCache::Entry.sum(:byte_size)
      }
      @cable_stats = {
        messages: ::SolidCable::Message.count,
        channels: ::SolidCable::Message.distinct.count(:channel)
      }
    end
  end
end
