class EntriesController < ApplicationController
  def index
    @entries = Entry.order(created_at: :desc)
  end

  def new
    @entry = Entry.new
  end

  def create
    @entry = Entry.new(entry_params)

    if @entry.save
      GenerateEntryGuideWithGemini.new(@entry).call
      redirect_to @entry, notice: "Guide generated successfully."
    else
      render :new, status: :unprocessable_entity
    end
  rescue StandardError => e
    redirect_to @entry, alert: "Guide generation failed: #{e.message}"
  end

  def show
    @entry = Entry.find(params[:id])
    @safe_doc_link = safe_doc_link(@entry.doc_link)
  end

  def destroy
    @entry = Entry.find(params[:id])
    @entry.destroy

    redirect_to entries_path, notice: "Entry deleted successfully."
  end

  def generate_guide
    @entry = Entry.find(params[:id])

    GenerateEntryGuideWithGemini.new(@entry).call

    redirect_to @entry, notice: "Guide generated successfully."
  rescue StandardError => e
    redirect_to @entry, alert: "Guide generation failed: #{e.message}"
  end

  private

  def safe_doc_link(url)
  return nil if url.blank?

  uri = URI.parse(url)

  return url if uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

  nil
rescue URI::InvalidURIError
  nil
end

  def entry_params
    params.require(:entry).permit(:technology, :use_case)
  end
end
