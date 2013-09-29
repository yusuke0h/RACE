json.array!(@tests) do |test|
  json.extract! test, :title, :body
  json.url test_url(test, format: :json)
end
