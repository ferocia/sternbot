class Player < ApplicationRecord
  has_many :high_scores, dependent: :destroy
  has_many :achievements, dependent: :destroy

  def high_score
    @high_score ||= high_scores.maximum(:value)
  end

  def highest_scores(n: 5)
    high_scores.order(value: :desc).limit(n)
  end

  def reload
    @high_score = nil
    super
  end
end
