class VmController < ApplicationController
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  before_filter :pre_vm_admin, :only => [:vm_action, :cancel_queued_tasks]

  def show
    set_perms(@perm_obj)
    @actions = @vm.get_action_and_label_list
    unless @can_monitor
      flash[:notice] = 'You do not have permission to view this vm: redirecting to top level'
      redirect_to :controller => 'library', :action => 'list'
    end
  end

  def new
  end

  def create
    if @vm.save
      @task = Task.new({ :user    => @user,
                         :vm_id   => @vm.id,
                         :action  => Task::ACTION_CREATE_VM,
                         :state   => Task::STATE_QUEUED})
      if @task.save
        flash[:notice] = 'Vm was successfully created.'
        start_now = params[:start_now]
        if (start_now)
          if @vm.get_action_list.include?(Task::ACTION_START_VM)
            @task = Task.new({ :user    => @user,
                               :vm_id   => @vm.id,
                               :action  => Task::ACTION_START_VM,
                               :state   => Task::STATE_QUEUED})
            if @task.save
              flash[:notice] = flash[:notice] + ' VM Start action queued.'
            else
              flash[:notice] = flash[:notice] + ' Error in inserting Start task.'
            end
          else
            flash[:notice] = flash[:notice] + ' Resources are not available to start VM now.'
          end
        end
      else
        flash[:notice] = 'Error in inserting task.'
      end
      redirect_to :controller => 'library', :action => 'show', :id => @vm.vm_library
    else
      render :action => 'new'
    end
  end

  def edit
  end

  def update
    #needs restart if certain fields are changed (since those will only take effect the next startup)
    needs_restart = false
    unless @vm.get_pending_state == Vm::STATE_STOPPED
      Vm::NEEDS_RESTART_FIELDS.each do |field|
        unless @vm[field].to_s == params[:vm][field]
          needs_restart = true
          break
        end
      end
      current_storage_ids = @vm.storage_volume_ids.sort
      new_storage_ids = params[:vm][:storage_volume_ids]
      new_storage_ids = [] unless new_storage_ids
      new_storage_ids = new_storage_ids.sort.collect {|x| x.to_i }
      needs_restart = true unless current_storage_ids == new_storage_ids
    end
    params[:vm][:needs_restart] = 1 if needs_restart
    if @vm.update_attributes(params[:vm])
      flash[:notice] = 'Vm was successfully updated.'
      redirect_to :action => 'show', :id => @vm
    else
      render :action => 'edit'
    end
  end

  def destroy
    vm_library = @vm.vm_library_id
    if ((@vm.state == Vm::STATE_STOPPED and @vm.get_pending_state == Vm::STATE_STOPPED) or
        (@vm.state == Vm::STATE_PENDING and @vm.get_pending_state == Vm::STATE_PENDING))
      @vm.destroy
      if vm_library
        redirect_to :controller => 'library', :action => 'show', :id => vm_library
      else
        redirect_to :controller => 'library', :action => 'list'
      end
    else
      flash[:notice] = "Vm must be stopped to destroy it."
      redirect_to :controller => 'vm', :action => 'show', :id => params[:id]
    end
  end

  def vm_action
    if @vm.get_action_list.include?(params[:vm_action])
      @task = Task.new({ :user    => get_login_user,
                         :vm_id   => params[:id],
                         :action  => params[:vm_action],
                         :state   => Task::STATE_QUEUED})
      if @task.save
        flash[:notice] = "#{params[:vm_action]} was successfully queued."
      else
        flash[:notice] = "Error in inserting task for #{params[:vm_action]}."
      end
    else
      flash[:notice] = "#{params[:vm_action]} is an invalid action."
    end
    redirect_to :controller => 'vm', :action => 'show', :id => params[:id]
  end

  def cancel_queued_tasks
    @vm.get_queued_tasks.each { |task| task.cancel}
    flash[:notice] = "queued tasks canceled."
    redirect_to :controller => 'vm', :action => 'show', :id => params[:id]
  end

  protected
  def pre_new
    # random MAC
    mac = [ 0x00, 0x16, 0x3e, rand(0x7f), rand(0xff), rand(0xff) ]
    # random uuid
    uuid = ["%02x" * 4, "%02x" * 2, "%02x" * 2, "%02x" * 2, "%02x" * 6].join("-") % 
      Array.new(16) {|x| rand(0xff) }
    newargs = { 
      :vm_library_id => params[:vm_library_id],
      :vnic_mac_addr => mac.collect {|x| "%02x" % x}.join(":"),
      :uuid => uuid
    }
    @vm = Vm.new( newargs )
    @perm_obj = @vm.vm_library
    @redir_controller = 'library'
  end
  def pre_create
    params[:vm][:state] = Vm::STATE_PENDING
    #set boot device to network for first boot (install)
    params[:vm][:boot_device] = Vm::BOOT_DEV_NETWORK unless params[:vm][:boot_device]
    @vm = Vm.new(params[:vm])
    @perm_obj = @vm.vm_library
    @redir_controller = 'library'
  end
  def pre_show
    @vm = Vm.find(params[:id])
    @perm_obj = @vm.vm_library
  end
  def pre_edit
    @vm = Vm.find(params[:id])
    @perm_obj = @vm.vm_library
    @redir_obj = @vm
  end
  def pre_vm_admin
    pre_edit
    authorize_admin
  end
end
