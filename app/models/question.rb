class Question < ApplicationRecord
  validates :text, presence: true
  validates :confidence, inclusion: { in: %w[pending sufficient insufficient] }
end
