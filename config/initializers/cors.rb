Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://localhost:5173', 'http://127.0.0.1:5173'  # Reactの実行先URLを指定

    resource '*',
      headers: :any,
      expose: ['access-token', 'client','uid'],
      methods: [:get, :post, :patch, :put, :delete, :options, :head],
      credentials: true 
  end
end
