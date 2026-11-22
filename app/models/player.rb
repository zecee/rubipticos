require "digest"

class Player < ApplicationRecord
  NAME_LENGTH = 3..20

  attr_reader :identity_token

  normalizes :name, with: ->(name) { name.gsub(/\A\p{Space}+|\p{Space}+\z/, "") }

  before_validation :set_name_key
  before_validation :generate_identity_token, on: :create

  validates :name, presence: true, length: { in: NAME_LENGTH }
  validates :name_key, presence: true, uniqueness: true
  validates :token_digest, presence: true, length: { is: 64 }

  def self.from_identity_token(token)
    return unless token.is_a?(String) && token.match?(/\A[A-Za-z0-9_-]{43}\z/)

    find_by(token_digest: Digest::SHA256.hexdigest(token))
  end

  def save_with_name_conflict
    save
  rescue ActiveRecord::RecordNotUnique
    raise unless self.class.where(name_key: name_key).where.not(id: id).exists?

    errors.add(:name_key, :taken)
    false
  end

  def name_suggestion
    suffix_number = 2
    loop do
      suffix = "_#{suffix_number}"
      candidate = "#{name.to_s.first(NAME_LENGTH.max - suffix.length)}#{suffix}"
      return candidate unless self.class.exists?(name_key: candidate.downcase(:fold))

      suffix_number += 1
    end
  end

  private

  def set_name_key
    self.name_key = name&.downcase(:fold)
  end

  def generate_identity_token
    return if token_digest.present?

    @identity_token = SecureRandom.urlsafe_base64(32)
    self.token_digest = Digest::SHA256.hexdigest(identity_token)
  end
end
