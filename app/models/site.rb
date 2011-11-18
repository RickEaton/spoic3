class Site < ActiveRecord::Base
  scope :inactive, where(:active => 'f')
  scope :active, where(:active => 't')

  attr_accessible :id, :address1, :address2, :city, :name, :phone, :state,
                  :zip, :listing_priority, :active

  validates :name, :address1, :city, :state, :zip, :listing_priority, :presence => true

  validates :state, :length => { :is => 2}
  validates_inclusion_of :state, :in => State::STATE_ABBREVIATIONS, :message => 'Invalid state.'
  validates :zip,   :length => { :is => 5}, :numericality => true

  validates_format_of :phone, :with => /\A[0-9]{3}-[0-9]{3}-[0-9]{4}/,
                      :message => 'Please enter phone numbers in the 123-456-7890 format.'
  validates :listing_priority, :numericality => true

end