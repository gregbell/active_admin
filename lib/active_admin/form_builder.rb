# Note for posterity:
#
# Here we have two core customizations on top of Formtastic. First, this allows
# you to build forms in the AA DSL without dealing with the HTML return value of
# individual form methods (hence the +form_buffers+ object). Second, this provides
# an intuitive way to build has_many associated records in the same form.
#
module ActiveAdmin
  class FormBuilder < ::Formtastic::FormBuilder

    attr_reader :form_buffers

    def initialize(*args)
      @form_buffers = ["".html_safe]
      super
    end

    def inputs(*args, &block)
      @use_form_buffer = block_given?
      form_buffers.last << with_new_form_buffer{ super }
    end

    # If this `input` call is inside a `inputs` block, add the content
    # to the form buffer. Else, return it directly.
    def input(method, *args)
      content = with_new_form_buffer{ super }
      @use_form_buffer ? form_buffers.last << content : content
    end

    def cancel_link(url = {:action => "index"}, html_options = {}, li_attrs = {})
      li_attrs[:class] ||= "cancel"
      li_content = template.link_to I18n.t('active_admin.cancel'), url, html_options
      form_buffers.last << template.content_tag(:li, li_content, li_attrs)
    end

    def actions(*args, &block)
      form_buffers.last << with_new_form_buffer do
        block_given? ? super : super{ commit_action_with_cancel_link }
      end
    end

    def action(*args)
      form_buffers.last << with_new_form_buffer{ super }
    end

    def commit_action_with_cancel_link
      action(:submit)
      cancel_link
    end

    def has_many(assoc, options = {}, &block)
      options = {for: assoc, new_record: true}.merge options
      options[:class] ||= ""
      options[:class] << "inputs has_many_fields"

      # Add Delete Links
      form_block = proc do |has_many_form|
        index    = parent_child_index options[:parent] if options[:parent]
        contents = block.call has_many_form, index

        if has_many_form.object.new_record?
          contents << template.content_tag(:li) do
            template.link_to I18n.t('active_admin.has_many_remove'), "#", class: 'button has_many_remove'
          end
        elsif options[:allow_destroy]
          has_many_form.input :_destroy, as: :boolean, wrapper_html: {class: 'has_many_delete'},
                                                       label: I18n.t('active_admin.has_many_delete')
        end
        contents
      end

      
      html = with_new_form_buffer do
        template.content_tag :div, class: "has_many #{assoc}" do
          unless options.key?(:heading) && !options[:heading]
            form_buffers.last << template.content_tag(:h3) do
              options[:heading] || object.class.reflect_on_association(assoc).klass.model_name.human(count: 1.1)
            end
          end

          inputs_html = with_new_form_buffer { inputs options, &form_block }
          inputs_html = template.content_tag(:ol, inputs_html, class: 'moo2') if @already_in_an_inputs_block

          form_buffers.last << inputs_html
          form_buffers.last << js_for_has_many(assoc, form_block, template, options[:new_record]) if options[:new_record]
        end
      end

      # when the has_many is nested in an inputs block, wrap it in an li to keep the mark up valid
      # see https://github.com/justinfrench/formtastic/blob/2.3.0.rc2/lib/formtastic/helpers/inputs_helper.rb#L302
      html = template.content_tag(:li, html, class: 'input moo') if @already_in_an_inputs_block

      form_buffers.last << html
    end

    def semantic_errors(*args)
      form_buffers.last << with_new_form_buffer{ super }
    end

    protected

    def active_admin_input_class_name(as)
      "ActiveAdmin::Inputs::#{as.to_s.camelize}Input"
    end

    def input_class(as)
      @input_classes_cache ||= {}
      @input_classes_cache[as] ||= begin
        begin
          custom_input_class_name(as).constantize
        rescue NameError
          begin
            active_admin_input_class_name(as).constantize
          rescue NameError
            standard_input_class_name(as).constantize
          end
        end
      rescue NameError
        raise Formtastic::UnknownInputError, "Unable to find input class for #{as}"
      end
    end

    # This method calls the block it's passed (in our case, the `f.inputs` block)
    # and wraps the resulting HTML in a fieldset. If your block doesn't have a
    # valid return value but it was otherwise built correctly, we instead use
    # the most recent part of the Active Admin form buffer.
    def field_set_and_list_wrapping(*args, &block)
      block_given? ? super{
        (val = yield).is_a?(String) ? val : form_buffers.last
      } : super
    end

    private

    def with_new_form_buffer
      form_buffers << ''.html_safe
      return_value = (yield || '').html_safe
      form_buffers.pop
      return_value
    end

    # Capture the ADD JS
    def js_for_has_many(assoc, form_block, template, new_record)
      assoc_reflection = object.class.reflect_on_association assoc
      assoc_name       = assoc_reflection.klass.model_name
      placeholder      = "NEW_#{assoc_name.to_s.upcase.split(' ').join('_')}_RECORD"
      opts = {
        :for         => [assoc, assoc_reflection.klass.new],
        :class       => "inputs has_many_fields",
        :for_options => { child_index: placeholder }
      }
      html = with_new_form_buffer{ inputs_for_nested_attributes opts, &form_block }
      text = new_record.is_a?(String) ? new_record : I18n.t('active_admin.has_many_new', model: assoc_name.human)

      template.link_to text, '#', class: "button has_many_add", data: {
        html: CGI.escapeHTML(html).html_safe, placeholder: placeholder
      }
    end

  end
end
