module Admin
  class FilterPresetsController < AdminController
    before_action :set_preset, only: [:update, :destroy]
    before_action :authorize_action

    def create
      @preset = current_user.admin_filter_presets.build(preset_params)
      
      if @preset.save
        render json: {
          id: @preset.id,
          name: @preset.name,
          filters: @preset.filters,
          global: @preset.global,
          message: 'Preset saved successfully'
        }
      else
        render json: { errors: @preset.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      if @preset.modifiable_by?(current_user) && @preset.update(preset_params)
        render json: {
          id: @preset.id,
          name: @preset.name,
          filters: @preset.filters,
          global: @preset.global,
          message: 'Preset updated successfully'
        }
      else
        render json: { errors: @preset.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      if @preset.modifiable_by?(current_user)
        @preset.destroy
        render json: { message: 'Preset deleted successfully' }
      else
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
    end

    def index
      @presets = AdminFilterPreset.available_to(current_user, params[:resource_type])
      render json: @presets.map { |preset|
        {
          id: preset.id,
          name: preset.name,
          description: preset.description,
          filters: preset.filters,
          global: preset.global,
          usage_count: preset.usage_count,
          last_used_at: preset.last_used_at,
          modifiable: preset.modifiable_by?(current_user)
        }
      }
    end

    def apply
      @preset = AdminFilterPreset.find(params[:id])
      @preset.increment!(:usage_count)
      @preset.touch(:last_used_at)
      
      redirect_to send("admin_#{@preset.resource_type}_path", @preset.filters)
    end

    private

    def set_preset
      @preset = AdminFilterPreset.find(params[:id])
    end

    def preset_params
      params.require(:filter_preset).permit(
        :name,
        :resource_type,
        :description,
        :global,
        filters: {}
      )
    end

    def authorize_action
      case action_name.to_sym
      when :index
        true # Allow all users to view presets
      when :create
        authorize! :create_presets, params[:filter_preset][:resource_type].to_sym
      when :update, :destroy
        authorize! :manage_presets, @preset.resource_type.to_sym
      end
    end
  end
end
