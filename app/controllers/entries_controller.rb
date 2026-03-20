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
      redirect_to @entry, notice: "Learning request created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @entry = Entry.find(params[:id])
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

  def entry_params
    params.require(:entry).permit(:technology, :use_case)
  end
end