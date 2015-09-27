module RailsAdmin
  module Config
    module Actions
      class BaseExpand < RailsAdmin::Config::Actions::Base

        register_instance_option :http_methods do
          [:get, :post]
        end

        register_instance_option :controller do
          proc do
            source = (@object && [@object.id.to_s]) || (@bulk_ids = params[:bulk_ids])
            options_config = RailsAdmin::Config.model(Forms::ExpandOptions)
            if options_params = params[options_config.abstract_model.param_key]
              options_params = options_params.select { |k, _| %w(segment_shortcuts).include?(k.to_s) }.permit!
            else
              options_params = {}
            end
            @options = Forms::ExpandOptions.new(options_params)
            result = nil
            begin
              result = Cenit::Rabbit.enqueue(@options.attributes.merge(source: source, task: Setup::DataTypeExpansion))
            rescue Exception => ex
              do_flash(:error, 'Error expanding data type:', ex.message)
            end if params[:_expand]
            if result
              do_flash_process_result(result)
              redirect_to back_or_index
            else
              report = Setup::DataType.shutdown(@object, report_only: true)
              @object.instance_variable_set(:@_to_shutdown, report[:destroyed].collect(&:data_type).uniq) if report[:destroyed]
              @object.instance_variable_set(:@_to_reload, report[:affected].collect(&:data_type).uniq) if report[:affected]
              @model_config = options_config
              render :expand
            end
          end
        end

        register_instance_option :link_icon do
          'icon-road'
        end

        register_instance_option :pjax? do
          false
        end
      end
    end
  end
end
