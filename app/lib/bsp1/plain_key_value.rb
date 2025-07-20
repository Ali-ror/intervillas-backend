class Bsp1::PlainKeyValue < Faraday::Middleware
  def on_complete(response_env)
    decoded_params = response_env.body.split("\n").to_h { |line|
      line.split "=", 2
    }

    response_env.body = decoded_params
  end
end
