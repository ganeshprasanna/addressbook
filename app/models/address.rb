class Address < ActiveRecord::Base

  has_and_belongs_to_many :groups
  has_many :contacts, :dependent => :nullify
  belongs_to :address_type
  belongs_to :primary_contact, :class_name => 'Contact', :foreign_key => "contact1_id"
  belongs_to :secondary_contact, :class_name => 'Contact', :foreign_key => "contact2_id"

  validate :verify_required_info
  validates_format_of :home_phone, :with => /^\d\d\d-\d\d\d-\d\d\d\d$/, 
    :message => 'must be in the format of XXX-XXX-XXXX',
    :if => Proc.new { |address| !address.home_phone.blank? }
  
  def addressee_for_display
    if primary_contact.nil? && secondary_contact.nil?
      format_address_with_no_contacts
    else
      address_type.format_address_for_display(self)
    end
  end

  def addressee
    if primary_contact.nil? && secondary_contact.nil?
      format_address_with_no_contacts
    else
      address_type.format_address_for_label(self)
    end
  end

  def different_from(other)
    if other.nil? || (address1 != other.address1 || address2 != other.address2 ||
                      city != other.city || state != other.state ||
                      zip != other.zip || home_phone != other.home_phone)
      true
    else
      false
    end
  end

  def mailing_address
    ma = address1
    ma << ", #{address2}" unless address2.blank?
    ma << ", #{city}, #{state} #{zip}"
  end

  def unlink_contact(contact)
    self.primary_contact = nil if self.primary_contact == contact
    self.secondary_contact = nil if self.secondary_contact == contact
    contacts.delete(contact)
    save
    adjust_primary_secondary_contacts
  end

  def link_contact
    adjust_primary_secondary_contacts
  end

  def self.remove_contact(contact)
    addresses = Address.find(:all)
    addresses.each do |a|
      a.unlink_contact(contact) if a.primary_contact == contact || a.secondary_contact == contact
    end
  end

  def self.find_for_list
    address_list = Address.find(:all)
    address_list.sort! do |a1, a2| 
      result = 0
      if a1.primary_contact.nil? 
        result = 1
      elsif a2.primary_contact.nil?
        result = -1
      else
        result = a1.primary_contact.last_name <=> a2.primary_contact.last_name
        result = a1.primary_contact.first_name <=> a2.primary_contact.first_name if result == 0
      end
      result
    end
    address_list
  end

  def self.find_all_eligible_for_group
    Address.find(:all, :conditions => ["address1 <> ''"])
  end
  
  def compare_by_primary_contact(other)
    raise ArgumentError unless other.class == self.class
    return -1 if other.nil?

    return -1 if !self.primary_contact.nil? &&  other.primary_contact.nil?
    return  1 if  self.primary_contact.nil? && !other.primary_contact.nil?
    return  0 if  self.primary_contact.nil? &&  other.primary_contact.nil?

    return "#{self.primary_contact.last_name}#{self.primary_contact.first_name}" <=>
      "#{other.primary_contact.last_name}#{other.primary_contact.first_name}"
  end

  def is_empty?
    id.blank? || address1.blank? || city.blank? || state.blank? || zip.blank?
  end

  private

    def adjust_primary_secondary_contacts
      # Get the first 2 contacts linked to this address
      primary_contacts = contacts.first(2)

      # Set contact1 to the first person in the contacts list if it is blank
      if self.primary_contact.blank? && primary_contacts[0]
        self.primary_contact = primary_contacts[0]
      elsif !primary_contacts[0]
        self.primary_contact = nil
      end

      # Set contact2 to the second person in the contacts list if it is blank
      if self.secondary_contact.blank? && primary_contacts[1]
        self.secondary_contact = primary_contacts[1]
      elsif !primary_contacts[1]
        self.secondary_contact = nil
      end

      # If contact1 == contact2, fix it
      if self.primary_contact == self.secondary_contact && self.primary_contact && self.secondary_contact
        if self.primary_contact == primary_contacts[0]
          self.primary_contact = primary_contacts[1]
        else
          self.primary_contact = primary_contacts[0]
        end
      end

      # Set the address type to individual if one contact, and family if there are two
      if !self.primary_contact.blank? && self.secondary_contact.blank?
        self.address_type = AddressType.individual
      elsif !self.primary_contact.blank? && !self.secondary_contact.blank?
        self.address_type = AddressType.family
      end

      save
    end

    def verify_required_info
      if home_phone.blank? && (address1.blank? || city.blank? || state.blank? || zip.blank?)
        errors.add_to_base("You must specify a phone number or a full address")
      end
    end

    def format_address_with_no_contacts
      if !address1.blank?
        addressee =  "#{address1}"
        addressee << " #{address2}" if !address2.blank?
        addressee << ", #{city}, #{state} #{zip}"
        return addressee
      else
        return home_phone
      end
    end

end
