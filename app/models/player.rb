class Player < ApplicationRecord
  has_many :high_scores, dependent: :destroy
  has_many :achievements, dependent: :destroy

  def high_score
    @high_score ||= high_scores.maximum(:value)
  end
end
