Rails.configuration.safetynet = {
  email: {
    limit: Rails.env.development? ? 1000 : 1,
    timeframe: 1.hour
  }
}
