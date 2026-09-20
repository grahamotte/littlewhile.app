class Agent
  ROOT = File.expand_path("../..", __dir__)
  URL = "http://127.0.0.1:57123"

  class << self
    def start(prompt, directory: ROOT)
      case ENV.fetch("AGENT_RUNNER")
      when "openchamber"
        openchamber(prompt, directory)
      else
        raise "Unknown AGENT_RUNNER #{ENV.fetch("AGENT_RUNNER")}"
      end
    end

    def openchamber(prompt, directory)
      payload = {
        directory:,
        prompt:,
        model: ENV.fetch("AGENT_MODEL"),
      }
      payload[:variant] = ENV.fetch("AGENT_VARIANT") if ENV["AGENT_VARIANT"].present?
      Req.call(
        url: "#{URL}/api/openchamber/sessions",
        method: :post,
        payload:,
      )
    end
  end
end
