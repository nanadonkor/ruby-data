class KnowledgeDocument < ApplicationRecord
  has_many :knowledge_chunks, dependent: :destroy
  validates :title, presence: true
  validates :raw_content, presence: true
end