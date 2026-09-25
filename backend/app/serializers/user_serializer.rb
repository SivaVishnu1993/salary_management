class UserSerializer < BaseSerializer
  def as_json
    { id: record.id, name: record.name, email: record.email }
  end
end
