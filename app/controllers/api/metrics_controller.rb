# Implement a naïve Prometheus exporter.
#
# If this is extended, one should consider using the prometheus_client gem.
class Api::MetricsController < ApiController
  # NOTE: in production, this is Basic Auth protected on webserver level
  def show
    render plain: [pending_messages_total].join("\n")
  end

  private

  def pending_messages_total
    name = "intervillas_pending_messages_total"

    metric(name, :gauge, "Total number of messages to be sent, by template name.") do
      Message.where(sent_at: nil).group(:template).count.map { |tpl, n|
        sample(name, n, template: tpl)
      }
    end
  end

  def metric(name, type, help)
    [
      "# HELP #{name} #{help}",
      "# TYPE #{name} #{type}",
      *yield,
      nil, # ensure trailing new-line
    ].join("\n")
  end

  def sample(name, value, **labels)
    return "#{name} #{value}" if labels.empty?

    kv = labels.map { |key, val| %(#{key}="#{val}") }.join(",")
    "#{name}{#{kv}} #{value}"
  end
end
