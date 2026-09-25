require "rails_helper"

RSpec.describe BaseSerializer do
  it "requires subclasses to implement #as_json" do
    expect { described_class.one(Object.new) }.to raise_error(NotImplementedError)
  end

  it "serializes collections with the subclass mapping" do
    users = build_list(:user, 2)

    expect(UserSerializer.many(users).pluck(:email)).to eq(users.map(&:email))
  end
end
