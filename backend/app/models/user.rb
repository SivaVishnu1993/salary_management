# An HR user who can sign in. Every user is an HR Manager (no roles in v1).
class User < ApplicationRecord
  PASSWORD_MIN_LENGTH = 8

  has_secure_password

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true, length: { maximum: 100 }
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: true
  validates :password, length: { minimum: PASSWORD_MIN_LENGTH }, allow_nil: true
end
