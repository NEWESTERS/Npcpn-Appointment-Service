class Doctor < ApplicationRecord
	has_many :seances, dependent: :destroy
	belongs_to :affilate, optional: true

	def full_name
		self.last_name + ' ' + self.name + ' ' + self.patronymic
	end
end
