class Player < ApplicationRecord
  has_many :high_scores

  def high_score
    @high_score ||= high_scores.maximum(:value)
  end
end
