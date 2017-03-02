require 'json'

module RailsAdmin
  module RestApi
    ###
    # Generate notebook code for api service.
    module Notebooks
      def api_notebook(lang)
        ns, model_name, display_name = api_model
        nb_module = "#{ns}/#{model_name}"
        nb_name = "api-#{lang[:id]}.ipynb"

        Setup::Notebook.where(
          :name => nb_name,
          :module => nb_module
        ).first || api_create_notebook(lang, nb_module, nb_name, display_name)
      end

      def api_create_notebook(lang, nb_module, nb_name, display_name)
        runnable = ['ruby', 'python', 'nodejs'].include?(lang[:id])
        auth_vars = api_auth_vars(lang[:id], false)
        auth_vars_markdown = "```#{lang[:hljs]}\n#{auth_vars}\n```"
        cells = [
          api_notebook_cell_markdown("## Access to *#{display_name}* using *#{lang[:label]}* language."),
          api_notebook_cell_markdown("### Authentication parameters:"),
          (runnable ? api_notebook_cell_code(auth_vars) : api_notebook_cell_markdown(auth_vars_markdown))
        ]

        api_current_paths.each do |path, methods|
          methods.each do |method, definition|
            lines = []
            lines << "### #{definition[:summary].strip.sub(/[.:]*$/, ':')}\n"
            lines << "\n"
            lines << "---\n"
            lines << "\n"
            lines << "#{definition[:description].strip}\n"
            lines << "**#{method.to_s}:** #{api_uri(method, path)}\n"
            lines << "---"
            code = api_code(lang[:id], method, path)
            code_markdown = "```#{lang[:hljs]}\n#{code}\n```"

            cells << api_notebook_cell_markdown(lines)
            cells << (runnable ? api_notebook_cell_code(code) : api_notebook_cell_markdown(code_markdown))
          end
        end

        attrs ={
          :name => nb_name,
          :module => nb_module,
          :content => {
            cells: cells,
            metadata: api_notebook_metadata(lang[:id]),
            nbformat: 4,
            nbformat_minor: 2
          }.to_json
        }

        botebook = Setup::Notebook.create(attrs)
        botebook.origin = :shared
      end

      def api_notebook_cell_markdown(contents)
        contents = [contents] unless contents.is_a?(Array)
        {
          cell_type: "markdown",
          metadata: {},
          source: contents
        }
      end

      def api_notebook_cell_code(codes)
        codes = [codes] unless codes.is_a?(Array)
        {
          cell_type: "code",
          execution_count: nil,
          metadata: { collapsed: true },
          outputs: [],
          source: codes
        }
      end

      def api_notebook_metadata(lang)
        case lang.to_sym
        when :python
          {
            kernelspec: { display_name: "Python 3", language: "python", name: "python3" },
            language_info: {
              codemirror_mode: { name: "ipython", version: 3 },
              file_extension: ".py",
              mimetype: "text/x-python",
              name: "python",
              nbconvert_exporter: "python",
              pygments_lexer: "ipython3",
            }
          }
        when :ruby
          {
            kernelspec: { display_name: "Ruby 2.2.1", language: "ruby", name: "ruby" },
            language_info: {
              file_extension: ".rb",
              mimetype: "application/x-ruby",
              name: "ruby"
            }

          }

        when :nodejs
          {
            kernelspec: { display_name: "Javascript (Node.js)", language: "javascript", name: "javascript" },
            language_info: {
              file_extension: ".js",
              mimetype: "application/javascript",
              name: "javascript"
            }
          }
        else
          {}
        end
      end
    end
  end
end