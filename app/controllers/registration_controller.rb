class RegistrationController < ApplicationController
  def index
    @title = "Manage Groups"
  end

  def create       #triggered by register view
    @registration = Registration.new(params[:registration])
    if @registration.save
      flash[:notice] = "Successful save"
      redirect_to edit_registration_path(:id => @registration.id)
    else
      @title = "Register a group"
      render "register"
    end
  end

  def edit              #prior to /:id/edit view
    @registration = Registration.find(params[:id])
    @liaison = Liaison.find(@registration.liaison_id)
    @group_type = SessionType.find(@registration.group_type_id)
    @church = Church.find(@liaison.church_id)
    @temp = Array.new()
    @temp << "None" << 0
    @sessions = Session.all.map  { |s| [s.name, s.id ]}
    @sessions.insert(0, @temp)
    @title = "Registration Step 2"
  end

  def register                #prior to display of register view
    @liaisons = Liaison.all
    @liaisons_churches = @liaisons.map { |l| [l.name, l.id ]}
    @group_types = SessionType.all.map { |s| [s.name, s.id ]}
    @registration = Registration.new
    @title = "Register A Group"

  end

  def schedule
  end

  def update
    @registration = Registration.find(params[:id])
    if @registration.update_attributes(params[:registration])
      flash[:success] = "Successful update"
      redirect_to registration_payment_path(:id => @registration.id)
    else
      @title = "Registration Step 2"
      render "edit"
    end
  end

  def process_payment
    @registration = Registration.find(params[:id])
    if @registration.payment_method.nil?
      @session = Session.find(@registration.request1)
      @payment_schedule = PaymentSchedule.find(@session.payment_schedule_id)
      @registration.amount_due= @payment_schedule.deposit * (@registration.requested_counselors + @registration.requested_youth)
      @payment_types = 'Check', 'Credit Card', 'Cash'
      @title = "Registration Step 3"
    else
      #record payment dataset
      @payment = Payment.new
      @payment.registration_id=@registration.id
      @payment.payment_method = @registration.payment_method
      @payment.payment_amount=@registration.amount_paid
      @payment.payment_date=Date.today
      @payment.payment_notes=@registration.payment_notes
      if @payment.save
        flash[:success] = "Successful completion of registration!"
        redirect_to registration_success_path
      else
        flash[:error] = "Update of registration or payment information failed."
        @title = "Registration Step 3"
        render "update"
      end
    end
  end

  def finalize
    @registration = Registration.find(params[:id])
    if @registration.update_attributes(params[:registration])
     @payment = Payment.new
     @payment.payment_method = @registration.payment_method
     @payment.payment_amount=@registration.amount_paid
     @payment.payment_date=Date.today
     @payment.payment_notes=@registration.payment_notes
     if @payment.save
       flash[:success] = "Successful completion"
       redirect_to successful_registration_path(:id => @registration.id)
     else
       flash[:error] = "Update of registration or payment information failed."
       @title = "Registration Step 3"
       render "update"
     end
    end
  end
  def successful
    @title = "Completed Registration"
    @registration = Registration.find(params[:id])
    @session = Session.find(@registration.request1)
  end

  def delete
  end

  def show
  end

  def show_schedule
    @schedule = {}
    @site_names = Site.order(:listing_priority).find_all_by_active(true).map { |s| s.name}
    @period_names = Period.order(:start_date).find_all_by_active(true).map { |p| p.name}

    @period_ordinal = Array.new
    for i in 0..@period_names.size - 1 do
      @period_ordinal[i] = @period_names[i]
    end

    @site_ordinal = Array.new
    for i in 0..@site_names.size - 1 do
      @site_ordinal[i] = @site_names[i]
    end

    @matrix = Array.new(@site_names.size){ Array.new(@period_names.size, 0)}

    #This is almost correct. I need to map the row and column positions to the ordinal
    #positions of the columns and rows...

    Registration.find(:all, :conditions => "request1 IS NOT NULL").each do |r|
        @session = Session.find(r.request1)
        @site = Site.find(@session.site_id)
        @period = Period.find(@session.period_id)
        @row_position = @site_ordinal.index(@site.name)
        @column_position = @period_ordinal.index(@period.name)
        @matrix[@row_position][@column_position] += r.requested_counselors + r.requested_youth
    end

    @schedule = { :site_count => @site_names.size, :period_count => @period_names.size,
                  :site_names => @site_names, :period_names => @period_names,
                  :matrix => @matrix}
  end

end