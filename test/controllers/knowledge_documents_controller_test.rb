require "test_helper"

class KnowledgeDocumentsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get knowledge_documents_index_url
    assert_response :success
  end

  test "should get new" do
    get knowledge_documents_new_url
    assert_response :success
  end

  test "should get create" do
    get knowledge_documents_create_url
    assert_response :success
  end
end
