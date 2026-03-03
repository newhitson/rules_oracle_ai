class Question < ApplicationRecord
  validates :text, presence: true
  validates :confidence, inclusion: { in: %w[sufficient insufficient] }
end
