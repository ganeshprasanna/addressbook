require File.dirname(__FILE__) + '/../test_helper'
require 'contact_controller'

# Re-raise errors caught by the controller.
class ContactController; def rescue_action(e) raise e end; end

class ContactControllerTest < ActionController::TestCase
  fixtures :contacts, :addresses
  
  def setup
    @controller = ContactController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_edit_contact_get
    get :edit_contact
    assert_template 'edit_contact'
  end

  def test_edit_contact_post
    contact = contacts(:john_doe)
    contact.middle_name = 'Patrick'
    post :edit_contact, { :id => contact.id, :contact => contact.attributes }
    assert_template 'edit_contact'
    assert_equal(contact.middle_name, assigns(:contact).middle_name)
    assert_equal(true, assigns(:saved))
  end
  
  def test_delete_contact
    contact = contacts(:john_doe)
    post :delete_contact, { :id => contact.id }
    assert_template 'delete_contact'
    assert_equal(contact, assigns(:contact))
  end
  
  def test_add_address_to_contact
    contact = contacts(:john_doe)
    address = addresses(:chicago)  
    post :add_address_to_contact, { :id => contact.id, :address_id => address.id }
    assert_template 'add_address_to_contact'
    assert_equal(address.id, assigns(:contact).address.id)
    assert_equal(true, assigns(:saved))
  end

  def test_add_address_to_contact_with_existing_address
    contact = contacts(:john_doe)
    address = addresses(:chicago)
    post :add_address_to_contact, { :id => contact.id, :address_id => address.id }

    address = addresses(:tinley_park)
    post :add_address_to_contact, { :id => contact.id, :address_id => address.id }

    chicago_from_db = Address.find(addresses(:chicago).id)
    assert_equal(nil, chicago_from_db.primary_contact)

    tinley_park_from_db = Address.find(addresses(:tinley_park).id)
    assert_equal(contact, tinley_park_from_db.primary_contact)
  end
  
  def test_remove_address_from_contact
    contact = contacts(:john_doe)
    address = addresses(:chicago)  
    post :add_address_to_contact, { :id => contact.id, :address_id => address.id }
    assert_equal(address.id, assigns(:contact).address.id)
    
    post :remove_address_from_contact, { :id => contact.id }
    assert_nil(assigns(:contact).address)
    assert_equal(true, assigns(:saved))
    assert_redirected_to(:controller => 'contact', :action => 'edit_contact', :id => contact.id)
  end
  
  def test_find_contact
    post :find_contact, { :last_name => 'd' }
    assert_equal(3, assigns(:contact_list).size)
    assert_template 'find_contact'
    assigns(:contact_list).each { |c| assert_equal('Doe', c.last_name) }
  end
  
  def test_link_to_address
    post :link_to_address
    assert_template 'link_to_address'
  end
  
end
