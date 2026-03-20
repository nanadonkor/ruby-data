class Entry < ApplicationRecord
    validates :technology, presence: true
    validates :use_case, presence: true
end
