class KnowledgeChunk < ApplicationRecord
  belongs_to :knowledge_document
  validates :content, presence: true
  validates :position, presence: true
end
