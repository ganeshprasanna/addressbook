class AddressController < ApplicationController

  def edit_address
    @address = Address.find_by_id(params[:id]) || Address.new

    if request.post?
      new_address = true if params[:id].nil?
      @address.attributes = params[:address]
      @address.secondary_contact = nil if @address.address_type.only_one_main_contact?
      if @address.save
        @saved = true
      else
        logger.error("Edit address failed: #{@address.errors.full_messages}")
      end
    end
    @address_list = Address.find_for_list if new_address
  end
  
  def delete_address
    @address = Address.find_by_id(params[:id])
    @address.ergo.destroy
  end
  
end
