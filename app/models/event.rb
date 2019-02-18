class Event < ApplicationRecord
  belongs_to :admin, class_name: 'User'
  has_many :attendances
  has_many :users, through: :attendances

  validates_with EventValidator, on: :create

  validates :start_date, presence: true

  validates :duration,
    presence: true,
    numericality: { greater_than: 0 }

  validates :title,
    presence: true,
    length: { in: 5..140 }

  validates :description,
    presence: true,
    length: { in: 20..1000 }

  validates :price,
    presence: true,
    numericality: { greater_than: 0, less_than: 1001}

  validates :location, presence: true

end
