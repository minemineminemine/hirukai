class Staff < ApplicationRecord
	has_many :train_shifts
	has_many :shifts
	has_many :rests
	has_one :today_work
end
