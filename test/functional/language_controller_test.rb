require File.dirname(__FILE__) + '/../test_helper'
require 'language_controller'

# Re-raise errors caught by the controller.
class LanguageController; def rescue_action(e) raise e end; end

class LanguageControllerTest < ControllerTestCase
  def setup
    @controller = LanguageController.new
    init_controller
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
