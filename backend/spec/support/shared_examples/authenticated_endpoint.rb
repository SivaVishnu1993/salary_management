# Include in a request spec that defines `make_request(headers:)`.
RSpec.shared_examples "an authenticated endpoint" do
  it "returns 401 without a token" do
    make_request(headers: {})

    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body.dig("error", "code")).to eq("unauthorized")
  end
end
