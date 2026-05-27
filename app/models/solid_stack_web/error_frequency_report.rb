module SolidStackWeb
  class ErrorFrequencyReport
    Row = Data.define(:exception_class, :message_prefix, :count, :sample_backtrace)

    MESSAGE_LIMIT = 120

    def groups
      ::SolidQueue::FailedExecution
        .order(created_at: :desc)
        .each_with_object({}) do |execution, acc|
          key = [execution.exception_class.to_s, message_prefix(execution.message)]
          entry = acc[key] ||= { count: 0, sample_backtrace: nil }
          entry[:count] += 1
          entry[:sample_backtrace] ||= execution.backtrace
        end
        .map do |(exception_class, prefix), data|
          Row.new(
            exception_class:  exception_class,
            message_prefix:   prefix,
            count:            data[:count],
            sample_backtrace: data[:sample_backtrace]
          )
        end
        .sort_by { |row| -row.count }
    end

    private

    def message_prefix(message)
      return "" if message.nil?
      message.length > MESSAGE_LIMIT ? "#{message[0, MESSAGE_LIMIT]}…" : message
    end
  end
end