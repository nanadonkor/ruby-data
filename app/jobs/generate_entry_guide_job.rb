class GenerateEntryGuideJob < ApplicationJob
  queue_as :default

  def perform(entry_id)
    entry = Entry.find(entry_id)
    GenerateEntryGuideWithGemini.new(entry).call
  end
end